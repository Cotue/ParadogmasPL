:- module(result_writer, [
    escribir_resultados/2,
    evaluados_a_json/2
]).

:- use_module(library(http/json)).


% =========================================================
% Configuracion del writer
% =========================================================

% Version del contrato de salida Prolog -> Java.
version_salida("1.0").


% =========================================================
% Punto de entrada publico
% =========================================================

% escribir_resultados(+RutaArchivo, +Evaluados)
%
% Evaluados es la lista producida por evaluar_todas/1:
%   evaluado(combinacion(Id, Cursos, CreditosTotales), Resultado)
%
% Convierte la lista a JSON y la escribe en RutaArchivo.
% No ejecuta reglas: solo traduce resultados ya calculados.
%
% La conversion se hace ANTES de abrir el archivo, de modo que
% un resultado interno invalido se reporta como e3_resultado y
% no como un error de escritura.
%
% Si el archivo no puede crearse o escribirse, lanza:
%   error(e3_output_io(escritura_fallida(Ruta, Causa)), _)
escribir_resultados(RutaArchivo, Evaluados) :-
    evaluados_a_json(Evaluados, Json),
    catch(
        escribir_json(RutaArchivo, Json),
        Causa,
        lanzar_error_salida(RutaArchivo, Causa)
    ).


% evaluados_a_json(+Evaluados, -Json)
%
% Conversion pura (sin I/O) de la lista interna al dict que
% representa el archivo de salida:
%
%   _{schemaVersion: "1.0", combinaciones: [...]}
%
% Conserva el orden y la cantidad de combinaciones.
evaluados_a_json(
    Evaluados,
    _{schemaVersion: Version, combinaciones: Combinaciones}
) :-
    version_salida(Version),
    convertir_evaluados(Evaluados, Combinaciones).


% =========================================================
% Escritura del archivo
% =========================================================

% escribir_json(+RutaArchivo, +Json)
%
% Abre el archivo en UTF-8, escribe el dict como JSON y
% garantiza el cierre del stream aunque ocurra un error.
escribir_json(RutaArchivo, Json) :-
    setup_call_cleanup(
        open(RutaArchivo, write, Stream, [encoding(utf8)]),
        (   json_write_dict(Stream, Json),
            nl(Stream)
        ),
        close(Stream)
    ).


% =========================================================
% Conversion de combinaciones
% =========================================================

% convertir_evaluados(+Evaluados, -Combinaciones)
%
% Recorre la lista en orden. Un elemento de entrada produce
% exactamente un elemento de salida.
convertir_evaluados([], []).

convertir_evaluados([Evaluado | Resto], [Combinacion | RestoJson]) :-
    convertir_evaluado(Evaluado, Combinacion),
    convertir_evaluados(Resto, RestoJson).


% convertir_evaluado(+Evaluado, -CombinacionJson)
%
% El Id no se exporta: es un identificador interno de la
% ejecucion (Contrato Maestro §25).
%
% El corte evita que, tras convertir un elemento valido,
% el backtracking llegue a la clausula de error.
convertir_evaluado(
    evaluado(combinacion(_Id, Cursos, CreditosTotales), Resultado),
    _{
        selecciones: Selecciones,
        creditosTotales: CreditosTotales,
        cumple: Cumple,
        razon: Razon
    }
) :-
    !,
    convertir_cursos(Cursos, Selecciones),
    convertir_resultado(Resultado, Cumple, Razon).

convertir_evaluado(Otro, _) :-
    lanzar_error_resultado(evaluado_invalido(Otro)).


% =========================================================
% Conversion de selecciones
% =========================================================

% convertir_cursos(+Cursos, -Selecciones)
convertir_cursos([], []) :-
    !.

convertir_cursos([Curso | Resto], [Seleccion | RestoJson]) :-
    !,
    convertir_curso(Curso, Seleccion),
    convertir_cursos(Resto, RestoJson).

convertir_cursos(Otro, _) :-
    lanzar_error_resultado(cursos_invalidos(Otro)).


% convertir_curso(+Curso, -SeleccionJson)
%
% curso(Codigo, Grupo, Creditos, Carrera, Area) se copia
% campo por campo; los atomos se convierten a texto.
convertir_curso(
    curso(Codigo, Grupo, Creditos, Carrera, Area),
    _{
        curso: CodigoTexto,
        grupo: Grupo,
        creditos: Creditos,
        carrera: CarreraTexto,
        area: AreaTexto
    }
) :-
    !,
    a_texto(Codigo, CodigoTexto),
    a_texto(Carrera, CarreraTexto),
    a_texto(Area, AreaTexto).

convertir_curso(Otro, _) :-
    lanzar_error_resultado(curso_invalido(Otro)).


% =========================================================
% Conversion de veredicto y razon
% =========================================================

% convertir_resultado(+Resultado, -Cumple, -RazonJson)
%
% resultado(true, ninguna)  -> cumple true,  razon null
% resultado(false, Razon)   -> cumple false, razon {codigo...}
%
% Se copia el veredicto calculado por el evaluador: el writer
% no vuelve a consultar reglas ni politica.
convertir_resultado(resultado(true, ninguna), true, null) :-
    !.

convertir_resultado(resultado(false, Razon), false, RazonJson) :-
    !,
    convertir_razon(Razon, RazonJson).

convertir_resultado(Otro, _, _) :-
    lanzar_error_resultado(resultado_invalido(Otro)).


% convertir_razon(+Razon, -RazonJson)
%
% Traduce los terminos internos de razon (Contrato §38) al
% formato JSON acordado para Java (Contrato §49).
convertir_razon(
    balance_carrera(Carrera),
    _{codigo: "BALANCE_CARRERA", carrera: CarreraTexto}
) :-
    !,
    a_texto(Carrera, CarreraTexto).

convertir_razon(
    limite_area(Area),
    _{codigo: "LIMITE_AREA", area: AreaTexto}
) :-
    !,
    a_texto(Area, AreaTexto).

convertir_razon(
    incompatibilidad(CursoA, CursoB),
    _{codigo: "INCOMPATIBILIDAD", cursoA: TextoA, cursoB: TextoB}
) :-
    !,
    a_texto(CursoA, TextoA),
    a_texto(CursoB, TextoB).

convertir_razon(Otra, _) :-
    lanzar_error_resultado(razon_desconocida(Otra)).


% =========================================================
% Utilidades
% =========================================================

% a_texto(+Valor, -Texto)
%
% Convierte atomos a strings para que json_write_dict los
% escriba siempre como texto JSON (evita que un valor como
% true o null se confunda con una constante JSON).
a_texto(Valor, Texto) :-
    atom_string(Valor, Texto).


% lanzar_error_salida(+Ruta, +Causa)
lanzar_error_salida(Ruta, Causa) :-
    throw(
        error(
            e3_output_io(escritura_fallida(Ruta, Causa)),
            context(
                escribir_resultados/2,
                'No se pudo crear o escribir el archivo de salida'
            )
        )
    ).


% lanzar_error_resultado(+Detalle)
lanzar_error_resultado(Detalle) :-
    throw(
        error(
            e3_resultado(Detalle),
            context(
                evaluados_a_json/2,
                'Resultado interno con forma invalida'
            )
        )
    ).
