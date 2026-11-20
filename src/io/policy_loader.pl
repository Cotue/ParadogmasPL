:- module(policy_loader, [
    cargar_politica/1,
    validar_politica/1,
    validar_cobertura_carreras/1
]).

:- use_module(library(readutil)).

% ============================================================================
% DECLARACIONES DINÁMICAS EN EL MÓDULO OBJETIVO (politica)
% ============================================================================

:- dynamic politica:max_porcentaje_carrera/2.
:- dynamic politica:max_cursos_area/1.
:- dynamic politica:incompatible/2.

% ============================================================================
% INTERFAZ PÚBLICA
% ============================================================================

%% cargar_politica(+Ruta) is det.
%
%  Lee los términos desde el archivo en Ruta sin ejecutar directivas,
%  valida todas las reglas de integridad de la política académica y,
%  únicamente si la validación es exitosa, reemplaza atómicamente los
%  hechos en el módulo `politica`.
cargar_politica(Ruta) :-
    (   \+ exists_file(Ruta)
    ->  lanzar_error_politica(archivo_inexistente(Ruta), cargar_politica/1)
    ;   leer_terminos_politica(Ruta, Terminos),
        validar_politica_con_contexto(Terminos, cargar_politica/1),
        aplicar_politica(Terminos)
    ).

%% validar_politica(+ListaDeTerminos) is det.
%
%  Predicado puro (sin efectos secundarios) que verifica que ListaDeTerminos
%  cumpla con todas las restricciones de formato, dominio y unicidad de la
%  política académica. Lanza error(e3_policy(Detalle), context(...)) ante
%  cualquier incumplimiento.
validar_politica(Terminos) :-
    validar_politica_con_contexto(Terminos, validar_politica/1).

%% validar_cobertura_carreras(+Combinaciones) is det.
%
%  Verifica que toda carrera presente en los cursos de Combinaciones tenga
%  definido un hecho politica:max_porcentaje_carrera(Carrera, _).
%  Una lista vacía de combinaciones es válida.
validar_cobertura_carreras([]) :- !.
validar_cobertura_carreras([combinacion(_Id, Cursos, _Total) | Resto]) :-
    validar_cobertura_cursos(Cursos),
    validar_cobertura_carreras(Resto).

% ============================================================================
% LECTURA SEGURA DE ARCHIVO (SIN CONSULT NI EVALUACIÓN)
% ============================================================================

%% leer_terminos_politica(+Ruta, -Terminos) is det.
%
%  Abre el archivo en UTF-8 y lee todos los términos hasta end_of_file.
%  Captura errores de sintaxis del parser de Prolog y los transforma en
%  errores de dominio e3_policy(sintaxis(Detalle)).
leer_terminos_politica(Ruta, Terminos) :-
    catch(
        setup_call_cleanup(
            open(Ruta, read, Flujo, [encoding(utf8)]),
            leer_flujo_terminos(Flujo, Terminos),
            close(Flujo)
        ),
        Error,
        manejar_error_lectura(Error)
    ).

%% leer_flujo_terminos(+Flujo, -Terminos) is det.
%
%  Lee recursivamente cada término del flujo abierto hasta end_of_file.
leer_flujo_terminos(Flujo, Terminos) :-
    read_term(Flujo, Termino, []),
    (   Termino == end_of_file
    ->  Terminos = []
    ;   Terminos = [Termino | Resto],
        leer_flujo_terminos(Flujo, Resto)
    ).

%% manejar_error_lectura(+Error) is det.
%
%  Convierte excepciones de sintaxis o lectura en e3_policy(sintaxis(Detalle)).
manejar_error_lectura(error(syntax_error(Detalle), _)) :- !,
    lanzar_error_politica(sintaxis(Detalle), cargar_politica/1).
manejar_error_lectura(Error) :-
    lanzar_error_politica(sintaxis(Error), cargar_politica/1).

% ============================================================================
% VALIDACIÓN PURA DE TÉRMINOS DE POLÍTICA
% ============================================================================

%% validar_politica_con_contexto(+Terminos, +Origen) is det.
%
%  Ejecuta la validación pura de Terminos propagando Origen en el contexto
%  de la excepción en caso de error.
validar_politica_con_contexto(Terminos, Origen) :-
    validar_terminos(Terminos, [], none, [], Origen).

%% validar_terminos(+Terminos, +PorcentajesAcc, +MaxAreaAcc, +ParesAcc, +Origen) is det.
%
%  Recorre la lista de términos acumulando:
%  - PorcentajesAcc: lista de pares carrera_pct(Carrera, Porcentaje)
%  - MaxAreaAcc: `none` si aún no aparece max_cursos_area/1, o `some(N)`
%  - ParesAcc: lista de pares par(CursoA, CursoB) ya declarados
validar_terminos([], PorcentajesAcc, MaxAreaAcc, _ParesAcc, Origen) :-
    (   MaxAreaAcc == none
    ->  lanzar_error_politica(max_cursos_area_faltante, Origen)
    ;   PorcentajesAcc == []
    ->  lanzar_error_politica(sin_porcentajes, Origen)
    ;   true
    ).
validar_terminos([Termino | Resto], PorcentajesAcc, MaxAreaAcc, ParesAcc, Origen) :-
    validar_termino(
        Termino,
        PorcentajesAcc, PorcentajesSig,
        MaxAreaAcc, MaxAreaSig,
        ParesAcc, ParesSig,
        Origen
    ),
    validar_terminos(Resto, PorcentajesSig, MaxAreaSig, ParesSig, Origen).

%% validar_termino(+Termino, +PctIn, -PctOut, +AreaIn, -AreaOut, +ParesIn, -ParesOut, +Origen) is det.
%
%  Valida un término individual y actualiza los acumuladores correspondientes.
validar_termino(max_porcentaje_carrera(Carrera, Porcentaje),
                PctIn, PctOut, AreaIn, AreaIn, ParesIn, ParesIn, Origen) :- !,
    validar_atomo_carrera(Carrera, Origen),
    validar_rango_porcentaje(Carrera, Porcentaje, Origen),
    registrar_porcentaje(Carrera, Porcentaje, PctIn, PctOut, Origen).

validar_termino(max_cursos_area(N),
                PctIn, PctIn, AreaIn, some(N), ParesIn, ParesIn, Origen) :- !,
    (   AreaIn \== none
    ->  lanzar_error_politica(max_cursos_area_duplicado, Origen)
    ;   true
    ),
    validar_entero_no_negativo(N, Origen).

validar_termino(incompatible(CursoA, CursoB),
                PctIn, PctIn, AreaIn, AreaIn, ParesIn, ParesOut, Origen) :- !,
    validar_atomo_curso(CursoA, Origen),
    validar_atomo_curso(CursoB, Origen),
    (   CursoA == CursoB
    ->  lanzar_error_politica(autoincompatible(CursoA), Origen)
    ;   true
    ),
    registrar_par_incompatible(CursoA, CursoB, ParesIn, ParesOut, Origen).

validar_termino(TerminoDesconocido, _PctIn, _PctOut, _AreaIn, _AreaOut, _ParesIn, _ParesOut, Origen) :-
    lanzar_error_politica(hecho_desconocido(TerminoDesconocido), Origen).

% ============================================================================
% HELPERS DE VALIDACIÓN DE DOMINIO
% ============================================================================

%% validar_atomo_carrera(+Carrera, +Origen) is det.
validar_atomo_carrera(Carrera, _Origen) :-
    atom(Carrera), !.
validar_atomo_carrera(Carrera, Origen) :-
    lanzar_error_politica(carrera_invalida(Carrera), Origen).

%% validar_rango_porcentaje(+Carrera, +Porcentaje, +Origen) is det.
validar_rango_porcentaje(_Carrera, Porcentaje, _Origen) :-
    number(Porcentaje),
    Porcentaje >= 0,
    Porcentaje =< 100, !.
validar_rango_porcentaje(Carrera, Porcentaje, Origen) :-
    lanzar_error_politica(porcentaje_invalido(Carrera, Porcentaje), Origen).

%% registrar_porcentaje(+Carrera, +Porcentaje, +PctIn, -PctOut, +Origen) is det.
%
%  Permite porcentajes repetidos únicamente si el valor numérico coincide.
%  Si la carrera ya tiene otro valor distinto, lanza porcentajes_contradictorios/3.
registrar_porcentaje(Carrera, Porcentaje, PctIn, PctOut, Origen) :-
    (   memberchk(carrera_pct(Carrera, Existente), PctIn)
    ->  (   Existente =:= Porcentaje
        ->  PctOut = PctIn
        ;   lanzar_error_politica(
                porcentajes_contradictorios(Carrera, Existente, Porcentaje),
                Origen
            )
        )
    ;   PctOut = [carrera_pct(Carrera, Porcentaje) | PctIn]
    ).

%% validar_entero_no_negativo(+N, +Origen) is det.
validar_entero_no_negativo(N, _Origen) :-
    integer(N),
    N >= 0, !.
validar_entero_no_negativo(N, Origen) :-
    lanzar_error_politica(max_cursos_area_invalido(N), Origen).

%% validar_atomo_curso(+Curso, +Origen) is det.
validar_atomo_curso(Curso, _Origen) :-
    atom(Curso), !.
validar_atomo_curso(Curso, Origen) :-
    lanzar_error_politica(curso_invalido(Curso), Origen).

%% registrar_par_incompatible(+CursoA, +CursoB, +ParesIn, -ParesOut, +Origen) is det.
%
%  Detecta duplicados tanto exactos (A, B) como invertidos (B, A).
registrar_par_incompatible(CursoA, CursoB, ParesIn, ParesOut, Origen) :-
    (   (   memberchk(par(CursoA, CursoB), ParesIn)
        ;   memberchk(par(CursoB, CursoA), ParesIn)
        )
    ->  lanzar_error_politica(par_duplicado(CursoA, CursoB), Origen)
    ;   ParesOut = [par(CursoA, CursoB) | ParesIn]
    ).

% ============================================================================
% CARGA ATÓMICA EN EL MÓDULO `politica`
% ============================================================================

%% aplicar_politica(+Terminos) is det.
%
%  Limpia los hechos previos en `politica` e inserta los términos validados.
%  Los hechos idénticos repetidos de max_porcentaje_carrera/2 se insertan
%  una única vez.
aplicar_politica(Terminos) :-
    retractall(politica:max_porcentaje_carrera(_, _)),
    retractall(politica:max_cursos_area(_)),
    retractall(politica:incompatible(_, _)),
    insertar_terminos_politica(Terminos).

%% insertar_terminos_politica(+Terminos) is det.
insertar_terminos_politica([]).
insertar_terminos_politica([max_porcentaje_carrera(Carrera, Porcentaje) | Resto]) :- !,
    (   politica:max_porcentaje_carrera(Carrera, _)
    ->  true
    ;   assertz(politica:max_porcentaje_carrera(Carrera, Porcentaje))
    ),
    insertar_terminos_politica(Resto).
insertar_terminos_politica([max_cursos_area(N) | Resto]) :- !,
    assertz(politica:max_cursos_area(N)),
    insertar_terminos_politica(Resto).
insertar_terminos_politica([incompatible(CursoA, CursoB) | Resto]) :- !,
    assertz(politica:incompatible(CursoA, CursoB)),
    insertar_terminos_politica(Resto).

% ============================================================================
% VALIDACIÓN DE COBERTURA DE CARRERAS
% ============================================================================

%% validar_cobertura_cursos(+Cursos) is det.
validar_cobertura_cursos([]).
validar_cobertura_cursos([curso(_Cod, _Grupo, _Creditos, Carrera, _Area) | Resto]) :-
    (   politica:max_porcentaje_carrera(Carrera, _)
    ->  true
    ;   lanzar_error_politica(
            carrera_sin_porcentaje(Carrera),
            validar_cobertura_carreras/1
        )
    ),
    validar_cobertura_cursos(Resto).

% ============================================================================
% MANEJO CENTRALIZADO DE EXCEPCIONES
% ============================================================================

%% lanzar_error_politica(+Detalle, +Origen) is det.
%
%  Lanza la excepción estándar del subsistema de políticas académicas.
lanzar_error_politica(Detalle, Origen) :-
    mensaje_error_politica(Detalle, Mensaje),
    throw(error(e3_policy(Detalle), context(Origen, Mensaje))).

%% mensaje_error_politica(+Detalle, -Mensaje) is det.
mensaje_error_politica(archivo_inexistente(Ruta), Mensaje) :-
    format(atom(Mensaje), 'El archivo de politica no existe: ~w', [Ruta]).
mensaje_error_politica(sintaxis(Detalle), Mensaje) :-
    format(atom(Mensaje), 'Error de sintaxis al leer politica: ~w', [Detalle]).
mensaje_error_politica(hecho_desconocido(Termino), Mensaje) :-
    format(atom(Mensaje), 'Termino no permitido en politica: ~w', [Termino]).
mensaje_error_politica(carrera_invalida(Carrera), Mensaje) :-
    format(atom(Mensaje), 'La carrera debe ser un atomo valido: ~w', [Carrera]).
mensaje_error_politica(porcentaje_invalido(Carrera, Porcentaje), Mensaje) :-
    format(atom(Mensaje), 'Porcentaje fuera de [0,100] o no numerico para ~w: ~w', [Carrera, Porcentaje]).
mensaje_error_politica(porcentajes_contradictorios(Carrera, P1, P2), Mensaje) :-
    format(atom(Mensaje), 'Porcentajes contradictorios para ~w: ~w vs ~w', [Carrera, P1, P2]).
mensaje_error_politica(max_cursos_area_faltante,
    'Falta la declaracion obligatoria max_cursos_area/1').
mensaje_error_politica(max_cursos_area_duplicado,
    'Se encontro mas de una declaracion max_cursos_area/1').
mensaje_error_politica(max_cursos_area_invalido(N), Mensaje) :-
    format(atom(Mensaje), 'max_cursos_area/1 requiere un entero no negativo, recibido: ~w', [N]).
mensaje_error_politica(curso_invalido(Curso), Mensaje) :-
    format(atom(Mensaje), 'El codigo de curso debe ser un atomo valido: ~w', [Curso]).
mensaje_error_politica(autoincompatible(Curso), Mensaje) :-
    format(atom(Mensaje), 'Un curso no puede ser incompatible consigo mismo: ~w', [Curso]).
mensaje_error_politica(par_duplicado(CursoA, CursoB), Mensaje) :-
    format(atom(Mensaje), 'Par incompatible duplicado o redundante: (~w, ~w)', [CursoA, CursoB]).
mensaje_error_politica(sin_porcentajes,
    'La politica debe definir al menos un hecho max_porcentaje_carrera/2').
mensaje_error_politica(carrera_sin_porcentaje(Carrera), Mensaje) :-
    format(atom(Mensaje), 'La carrera ~w aparece en las combinaciones pero no tiene politica definida', [Carrera]).