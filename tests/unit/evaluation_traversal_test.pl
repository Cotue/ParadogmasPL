:- begin_tests(evaluation_traversal, [cleanup(limpiar_estado)]).

:- use_module('../../src/io/combinations_loader').
:- use_module('../../src/io/policy_loader').
:- use_module('../../src/domain/combination_queries').
:- use_module('../../src/domain/evaluator').


% =========================================================
% Preparacion y limpieza
% =========================================================

% limpiar_estado
%
% Elimina los hechos de combinaciones y de politica.
limpiar_estado :-
    retractall(combination_queries:combinacion(_, _, _)),
    retractall(politica:max_porcentaje_carrera(_, _)),
    retractall(politica:max_cursos_area(_)),
    retractall(politica:incompatible(_, _)).

% preparar
%
% Estado limpio + politica sintetica cargada con el loader real.
preparar :-
    limpiar_estado,
    cargar_politica('tests/fixtures/policy/politica_recorrido.pl').


% =========================================================
% Datos de prueba
% =========================================================

% combinaciones_prueba(-Lista)
%
% 1: cumple (50% / 50%, una por area, sin par incompatible).
% 2: viola balance (computadores 80% > 70%).
% 3: viola incompatibilidad (TEST_A y TEST_B, balance 50/50).
combinaciones_prueba([
    combinacion(1, [
        curso('TEST_C', 1, 3, computadores, computadores),
        curso('TEST_D', 2, 3, matematica, matematicas)
    ], 6),
    combinacion(2, [
        curso('TEST_C', 1, 8, computadores, computadores),
        curso('TEST_D', 1, 2, matematica, matematicas)
    ], 10),
    combinacion(3, [
        curso('TEST_A', 1, 3, computadores, computadores),
        curso('TEST_B', 3, 3, matematica, matematicas)
    ], 6)
]).

% combinacion_de_evaluado(+Evaluado, -Combinacion)
combinacion_de_evaluado(evaluado(Combinacion, _), Combinacion).

% resultado_de_evaluado(+Evaluado, -Resultado)
resultado_de_evaluado(evaluado(_, Resultado), Resultado).

% id_de_evaluado(+Evaluado, -Id)
id_de_evaluado(evaluado(combinacion(Id, _, _), _), Id).

% resultado_bien_formado(+Resultado)
resultado_bien_formado(resultado(true, ninguna)).
resultado_bien_formado(resultado(false, Razon)) :-
    Razon \== ninguna.


% =========================================================
% 1. Entrada vacia
% =========================================================

test(entrada_vacia_produce_lista_vacia, [setup(preparar)]) :-
    registrar_combinaciones([]),
    evaluar_todas(Evaluados),
    Evaluados == [].


% =========================================================
% 2. N combinaciones -> N resultados
% =========================================================

test(tres_combinaciones_tres_resultados, [setup(preparar)]) :-
    combinaciones_prueba(Entrada),
    registrar_combinaciones(Entrada),
    evaluar_todas(Evaluados),
    length(Evaluados, 3),
    maplist(resultado_de_evaluado, Evaluados, Resultados),
    Resultados == [
        resultado(true, ninguna),
        resultado(false, balance_carrera(computadores)),
        resultado(false, incompatibilidad('TEST_A', 'TEST_B'))
    ].


% =========================================================
% 3. Conservacion de combinaciones
% =========================================================

test(combinaciones_de_salida_identicas_a_entrada, [setup(preparar)]) :-
    combinaciones_prueba(Entrada),
    registrar_combinaciones(Entrada),
    evaluar_todas(Evaluados),
    maplist(combinacion_de_evaluado, Evaluados, Salida),
    Salida == Entrada.


% =========================================================
% 4. Backtracking
% =========================================================

test(backtracking_enumera_ids_en_orden, [setup(preparar)]) :-
    combinaciones_prueba(Entrada),
    registrar_combinaciones(Entrada),
    findall(Id, evaluacion(Id, _), Ids),
    Ids == [1, 2, 3].

test(id_ligado_devuelve_solo_esa_combinacion, [setup(preparar)]) :-
    combinaciones_prueba(Entrada),
    registrar_combinaciones(Entrada),
    findall(E, evaluacion(2, E), Lista),
    Lista = [evaluado(Combinacion, Resultado)],
    nth1(2, Entrada, Esperada),
    Combinacion == Esperada,
    Resultado == resultado(false, balance_carrera(computadores)).

test(id_inexistente_falla, [setup(preparar), fail]) :-
    combinaciones_prueba(Entrada),
    registrar_combinaciones(Entrada),
    evaluacion(99, _).


% =========================================================
% 5. Exactamente un resultado por combinacion
% =========================================================

test(exactamente_un_resultado_por_id, [setup(preparar)]) :-
    combinaciones_prueba(Entrada),
    registrar_combinaciones(Entrada),
    forall(
        member(Id, [1, 2, 3]),
        (   findall(R, evaluacion(Id, R), L),
            length(L, 1)
        )
    ).


% =========================================================
% 6. Sin filtro de creditos
% =========================================================

test(total_40_creditos_no_se_filtra, [setup(preparar)]) :-
    Combinacion = combinacion(1, [
        curso('TEST_C', 1, 20, computadores, computadores),
        curso('TEST_D', 1, 20, matematica, matematicas)
    ], 40),
    registrar_combinaciones([Combinacion]),
    evaluar_todas(Evaluados),
    Evaluados = [evaluado(Salida, Resultado)],
    Salida == Combinacion,
    evaluar_combinacion(Combinacion, Directo),
    Resultado == Directo,
    Resultado == resultado(true, ninguna).


% =========================================================
% 7. Recarga
% =========================================================

test(recarga_reemplaza_combinaciones_anteriores, [setup(preparar)]) :-
    combinaciones_prueba(Primera),
    registrar_combinaciones(Primera),
    Segunda = [
        combinacion(1, [
            curso('TEST_E', 1, 4, fisica, ciencias_naturales)
        ], 4)
    ],
    registrar_combinaciones(Segunda),
    evaluar_todas(Evaluados),
    maplist(combinacion_de_evaluado, Evaluados, Salida),
    Salida == Segunda.


% =========================================================
% 8. Propagacion de excepciones
% =========================================================
%
% evaluar_combinacion/2 no puede fallar con salida libre sin
% modificar reglas. Se verifica en cambio que una excepcion
% de una regla no se convierte en perdida silenciosa de la
% combinacion.

test(excepcion_de_regla_se_propaga, [
    setup(preparar),
    throws(error(e3_policy(max_cursos_area_faltante), _))
]) :-
    combinaciones_prueba([Cumple | _]),
    registrar_combinaciones([Cumple]),
    retractall(politica:max_cursos_area(_)),
    evaluar_todas(_).


% =========================================================
% 9. Integracion con el JSON real de Racket
% =========================================================

test(integracion_json_real_conserva_cantidad, [setup(limpiar_estado)]) :-
    cargar_combinaciones(
        'tests/fixtures/policy/combinaciones_reales.json',
        Entrada
    ),
    cargar_politica('data/policy/politica.pl'),
    validar_cobertura_carreras(Entrada),
    registrar_combinaciones(Entrada),
    evaluar_todas(Evaluados),
    length(Entrada, N),
    length(Evaluados, N),
    N > 0,
    maplist(combinacion_de_evaluado, Evaluados, Salida),
    Salida == Entrada,
    maplist(id_de_evaluado, Evaluados, Ids),
    numlist(1, N, Ids),
    maplist(resultado_de_evaluado, Evaluados, Resultados),
    maplist(resultado_bien_formado, Resultados).

:- end_tests(evaluation_traversal).
