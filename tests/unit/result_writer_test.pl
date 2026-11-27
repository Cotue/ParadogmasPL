:- begin_tests(result_writer, [cleanup(limpiar_estado)]).

:- use_module(library(http/json)).
:- use_module('../../src/io/result_writer').
:- use_module('../../src/io/combinations_loader').
:- use_module('../../src/io/policy_loader').
:- use_module('../../src/domain/combination_queries').
:- use_module('../../src/domain/evaluator').


% =========================================================
% Preparacion y utilidades
% =========================================================

limpiar_estado :-
    retractall(combination_queries:combinacion(_, _, _)),
    retractall(politica:max_porcentaje_carrera(_, _)),
    retractall(politica:max_cursos_area(_)),
    retractall(politica:incompatible(_, _)).

% cursos_base(-Cursos)
cursos_base([
    curso('CE1101', 1, 3, computadores, computadores),
    curso('MA1403', 4, 4, matematica, matematicas)
]).

% evaluado_con(+Id, +Resultado, -Evaluado)
evaluado_con(Id, Resultado, evaluado(combinacion(Id, Cursos, 7), Resultado)) :-
    cursos_base(Cursos).

% primera_combinacion(+Evaluados, -CombinacionJson)
primera_combinacion(Evaluados, Combinacion) :-
    evaluados_a_json(Evaluados, Json),
    get_dict(combinaciones, Json, [Combinacion]).

% veredicto_de(+Resultado, -Cumple, -Razon)
veredicto_de(Resultado, Cumple, Razon) :-
    evaluado_con(1, Resultado, Evaluado),
    primera_combinacion([Evaluado], Combinacion),
    get_dict(cumple, Combinacion, Cumple),
    get_dict(razon, Combinacion, Razon).

% seleccion_es(+Seleccion, +Curso, +Grupo, +Creditos, +Carrera, +Area)
seleccion_es(S, Curso, Grupo, Creditos, Carrera, Area) :-
    get_dict(curso, S, Curso),
    get_dict(grupo, S, Grupo),
    get_dict(creditos, S, Creditos),
    get_dict(carrera, S, Carrera),
    get_dict(area, S, Area).

% total_de(+CombinacionJson, -Total)
total_de(Combinacion, Total) :-
    get_dict(creditosTotales, Combinacion, Total).

% leer_json(+Ruta, -Json)
leer_json(Ruta, Json) :-
    setup_call_cleanup(
        open(Ruta, read, Stream, [encoding(utf8)]),
        json_read_dict(Stream, Json),
        close(Stream)
    ).

% con_archivo_temporal(+Objetivo)
%
% Crea un archivo temporal, ejecuta call(Objetivo, Archivo)
% y lo borra al final, aunque la prueba falle.
con_archivo_temporal(Objetivo) :-
    tmp_file_stream(text, Archivo, Stream),
    close(Stream),
    setup_call_cleanup(
        true,
        call(Objetivo, Archivo),
        borrar_si_existe(Archivo)
    ).

borrar_si_existe(Archivo) :-
    (   exists_file(Archivo)
    ->  delete_file(Archivo)
    ;   true
    ).


% =========================================================
% Conversion pura
% =========================================================

test(entrada_vacia_genera_json_vacio) :-
    evaluados_a_json([], Json),
    get_dict(schemaVersion, Json, "1.0"),
    get_dict(combinaciones, Json, []).

test(cumple_true_y_razon_null) :-
    veredicto_de(resultado(true, ninguna), Cumple, Razon),
    Cumple == true,
    Razon == null.

test(conserva_selecciones_y_creditos_totales) :-
    evaluado_con(1, resultado(true, ninguna), Evaluado),
    primera_combinacion([Evaluado], C),
    get_dict(creditosTotales, C, 7),
    get_dict(selecciones, C, [S1, S2]),
    seleccion_es(S1, "CE1101", 1, 3, "computadores", "computadores"),
    seleccion_es(S2, "MA1403", 4, 4, "matematica", "matematicas").

test(id_interno_no_se_exporta) :-
    evaluado_con(1, resultado(true, ninguna), Evaluado),
    primera_combinacion([Evaluado], C),
    \+ get_dict(id, C, _).

test(razon_balance_carrera) :-
    veredicto_de(resultado(false, balance_carrera(matematica)), Cumple, R),
    Cumple == false,
    get_dict(codigo, R, "BALANCE_CARRERA"),
    get_dict(carrera, R, "matematica").

test(razon_limite_area) :-
    veredicto_de(resultado(false, limite_area(ciencias_naturales)), Cumple, R),
    Cumple == false,
    get_dict(codigo, R, "LIMITE_AREA"),
    get_dict(area, R, "ciencias_naturales").

test(razon_incompatibilidad) :-
    veredicto_de(resultado(false, incompatibilidad('CE1101', 'MA1403')), Cumple, R),
    Cumple == false,
    get_dict(codigo, R, "INCOMPATIBILIDAD"),
    get_dict(cursoA, R, "CE1101"),
    get_dict(cursoB, R, "MA1403").

test(orden_y_cantidad_se_conservan) :-
    Evaluados = [
        evaluado(combinacion(1, [curso('A', 1, 3, computadores, computadores)], 3),
                 resultado(true, ninguna)),
        evaluado(combinacion(2, [curso('B', 1, 4, matematica, matematicas)], 4),
                 resultado(false, balance_carrera(matematica))),
        evaluado(combinacion(3, [curso('C', 1, 5, fisica, ciencias_naturales)], 5),
                 resultado(true, ninguna))
    ],
    evaluados_a_json(Evaluados, Json),
    get_dict(combinaciones, Json, Combinaciones),
    length(Combinaciones, 3),
    maplist(total_de, Combinaciones, Totales),
    Totales == [3, 4, 5].

% Sin politica cargada y con una razon que no corresponde a los
% cursos: el writer la copia tal cual, porque no ejecuta reglas.
test(writer_no_reevalua_reglas, [setup(limpiar_estado)]) :-
    veredicto_de(resultado(false, limite_area(optativas)), Cumple, R),
    Cumple == false,
    get_dict(codigo, R, "LIMITE_AREA"),
    get_dict(area, R, "optativas").

test(razon_desconocida_lanza_error, [
    throws(error(e3_resultado(razon_desconocida(otra_regla(x))), _))
]) :-
    veredicto_de(resultado(false, otra_regla(x)), _, _).

test(resultado_invalido_lanza_error, [
    throws(error(e3_resultado(resultado_invalido(resultado(quizas, ninguna))), _))
]) :-
    veredicto_de(resultado(quizas, ninguna), _, _).


% =========================================================
% Escritura de archivos
% =========================================================

test(archivo_escrito_es_json_valido) :-
    con_archivo_temporal(verificar_archivo).

verificar_archivo(Archivo) :-
    evaluado_con(1, resultado(true, ninguna), E1),
    evaluado_con(2, resultado(false, incompatibilidad('CE1101', 'MA1403')), E2),
    escribir_resultados(Archivo, [E1, E2]),
    leer_json(Archivo, Json),
    get_dict(schemaVersion, Json, "1.0"),
    get_dict(combinaciones, Json, [C1, C2]),
    get_dict(cumple, C1, true),
    get_dict(razon, C1, null),
    get_dict(cumple, C2, false),
    get_dict(razon, C2, R2),
    get_dict(codigo, R2, "INCOMPATIBILIDAD").

test(archivo_vacio_es_json_valido) :-
    con_archivo_temporal(verificar_archivo_vacio).

verificar_archivo_vacio(Archivo) :-
    escribir_resultados(Archivo, []),
    leer_json(Archivo, Json),
    get_dict(combinaciones, Json, []).

test(ruta_invalida_lanza_e3_output_io, [
    throws(error(e3_output_io(escritura_fallida(_, _)), _))
]) :-
    escribir_resultados('tests/fixtures/carpeta_inexistente/salida.json', []).


% =========================================================
% Integracion: JSON real -> evaluacion -> JSON para Java
% =========================================================

test(integracion_pipeline_completo, [setup(limpiar_estado)]) :-
    con_archivo_temporal(verificar_integracion).

verificar_integracion(Archivo) :-
    Entrada = 'tests/fixtures/policy/combinaciones_reales.json',
    cargar_combinaciones(Entrada, Combinaciones),
    cargar_politica('data/policy/politica.pl'),
    validar_cobertura_carreras(Combinaciones),
    registrar_combinaciones(Combinaciones),
    evaluar_todas(Evaluados),
    escribir_resultados(Archivo, Evaluados),
    leer_json(Entrada, JsonEntrada),
    leer_json(Archivo, JsonSalida),
    get_dict(combinaciones, JsonEntrada, CombEntrada),
    get_dict(combinaciones, JsonSalida, CombSalida),
    length(CombEntrada, N),
    length(CombSalida, N),
    N > 0,
    maplist(misma_combinacion, CombEntrada, CombSalida),
    maplist(veredicto_coherente, CombSalida).

% misma_combinacion(+Entrada, +Salida)
%
% Mismas selecciones (campo por campo, en el mismo orden) y
% mismos creditosTotales.
misma_combinacion(Entrada, Salida) :-
    get_dict(creditosTotales, Entrada, Total),
    get_dict(creditosTotales, Salida, Total),
    get_dict(selecciones, Entrada, SelEntrada),
    get_dict(selecciones, Salida, SelSalida),
    maplist(misma_seleccion, SelEntrada, SelSalida).

misma_seleccion(Entrada, Salida) :-
    forall(
        member(Campo, [curso, grupo, creditos, carrera, area]),
        (   get_dict(Campo, Entrada, Valor),
            get_dict(Campo, Salida, Valor)
        )
    ).

% veredicto_coherente(+CombinacionJson)
%
% cumple = true  -> razon = null
% cumple = false -> razon con uno de los tres codigos
veredicto_coherente(Combinacion) :-
    get_dict(cumple, Combinacion, Cumple),
    get_dict(razon, Combinacion, Razon),
    (   Cumple == true
    ->  Razon == null
    ;   Cumple == false,
        is_dict(Razon),
        get_dict(codigo, Razon, Codigo),
        memberchk(Codigo, ["BALANCE_CARRERA", "LIMITE_AREA", "INCOMPATIBILIDAD"])
    ).

:- end_tests(result_writer).
