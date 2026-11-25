:- use_module(library(plunit)).

:- begin_tests(evaluator).

:- use_module('../../src/domain/evaluator.pl').
:- use_module('../../src/io/policy_loader.pl').

:- use_module('../../src/rules/career_balance.pl').
:- use_module('../../src/rules/area_limit.pl').
:- use_module('../../src/rules/incompatibility.pl').


% =========================================================
% Preparacion de politica
% =========================================================

preparar_politica :-
    cargar_politica(
        'tests/fixtures/policy/politica_evaluador.pl'
    ).


% =========================================================
% Pruebas de prioridad de reglas
% =========================================================

test(
    viola_tres_reglas_prioriza_balance,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            1,
            [
                curso('TEST_A', 1, 3, computadores, computadores),
                curso('TEST_B', 1, 3, matematica, matematicas),
                curso('TEST_C', 1, 3, computadores, computadores)
            ],
            9
        ),

    validar_cobertura_carreras([Combinacion]),

    % Verificar que realmente viola las tres reglas.
    once(viola_balance(
        Combinacion,
        balance_carrera(computadores)
    )),

    once(viola_limite_area(
        Combinacion,
        limite_area(computadores)
    )),

    once(viola_incompatibilidad(
        Combinacion,
        incompatibilidad('TEST_A', 'TEST_B')
    )),

    % Verificar que solo existe una primera violacion.
    findall(
        Razon,
        primera_violacion(Combinacion, Razon),
        Razones
    ),

    assertion(
        Razones == [balance_carrera(computadores)]
    ).

test(
    viola_area_e_incompatibilidad_prioriza_area,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            2,
            [
                curso('TEST_A', 1, 3, computadores, computadores),
                curso('TEST_B', 1, 3, matematica, matematicas),
                curso('TEST_C', 1, 3, computadores, computadores),
                curso('TEST_D', 1, 3, matematica, matematicas)
            ],
            12
        ),

    validar_cobertura_carreras([Combinacion]),

    cumple_balance(Combinacion),

    once(viola_limite_area(
        Combinacion,
        limite_area(computadores)
    )),

    once(viola_incompatibilidad(
        Combinacion,
        incompatibilidad('TEST_A', 'TEST_B')
    )),

    findall(
        Razon,
        primera_violacion(Combinacion, Razon),
        Razones
    ),

    assertion(
        Razones == [limite_area(computadores)]
    ).

test(
    viola_unicamente_incompatibilidad,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            3,
            [
                curso('TEST_A', 1, 3, computadores, computadores),
                curso('TEST_B', 1, 3, matematica, matematicas)
            ],
            6
        ),

    validar_cobertura_carreras([Combinacion]),

    cumple_balance(Combinacion),
    cumple_limite_area(Combinacion),

    once(viola_incompatibilidad(
        Combinacion,
        incompatibilidad('TEST_A', 'TEST_B')
    )),

    findall(
        Razon,
        primera_violacion(Combinacion, Razon),
        Razones
    ),

    assertion(
        Razones == [incompatibilidad('TEST_A', 'TEST_B')]
    ).
test(
    cumple_todas_no_existe_violacion,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            4,
            [
                curso('TEST_A', 1, 3, computadores, computadores),
                curso('TEST_D', 1, 3, matematica, matematicas)
            ],
            6
        ),

    validar_cobertura_carreras([Combinacion]),

    cumple_balance(Combinacion),
    cumple_limite_area(Combinacion),
    cumple_incompatibilidad(Combinacion),

    findall(
        Razon,
        primera_violacion(Combinacion, Razon),
        Razones
    ),

    assertion(Razones == []).

test(
    razon_ligada_no_permite_saltar_balance,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            5,
            [
                curso('TEST_A', 1, 3, computadores, computadores),
                curso('TEST_B', 1, 3, matematica, matematicas),
                curso('TEST_C', 1, 3, computadores, computadores)
            ],
            9
        ),

    validar_cobertura_carreras([Combinacion]),

    assertion(
        \+ primera_violacion(
            Combinacion,
            limite_area(computadores)
        )
    ),

    assertion(
        \+ primera_violacion(
            Combinacion,
            incompatibilidad('TEST_A', 'TEST_B')
        )
    ),

    assertion(
        primera_violacion(
            Combinacion,
            balance_carrera(computadores)
        )
    ).

test(
    razon_ligada_no_permite_saltar_area,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            6,
            [
                curso('TEST_A', 1, 3, computadores, computadores),
                curso('TEST_B', 1, 3, matematica, matematicas),
                curso('TEST_C', 1, 3, computadores, computadores),
                curso('TEST_D', 1, 3, matematica, matematicas)
            ],
            12
        ),

    validar_cobertura_carreras([Combinacion]),

    assertion(
        \+ primera_violacion(
            Combinacion,
            incompatibilidad('TEST_A', 'TEST_B')
        )
    ),

    assertion(
        primera_violacion(
            Combinacion,
            limite_area(computadores)
        )
    ).
% =========================================================
% Evaluacion completa de combinaciones
% =========================================================
test(
    evaluacion_combinacion_rechazada,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            7,
            [
                curso('TEST_A', 1, 3, computadores, computadores),
                curso('TEST_B', 1, 3, matematica, matematicas),
                curso('TEST_C', 1, 3, computadores, computadores)
            ],
            9
        ),

    validar_cobertura_carreras([Combinacion]),

    findall(
        Resultado,
        evaluar_combinacion(Combinacion, Resultado),
        Resultados
    ),

    assertion(
        Resultados ==
        [resultado(false, balance_carrera(computadores))]
    ).

test(
    evaluacion_combinacion_aceptada,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            8,
            [
                curso('TEST_A', 1, 3, computadores, computadores),
                curso('TEST_D', 1, 3, matematica, matematicas)
            ],
            6
        ),

    validar_cobertura_carreras([Combinacion]),

    findall(
        Resultado,
        evaluar_combinacion(Combinacion, Resultado),
        Resultados
    ),

    assertion(
        Resultados == [resultado(true, ninguna)]
    ).

test(
    evaluacion_rechazada_por_area,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            9,
            [
                curso('TEST_A', 1, 3, computadores, computadores),
                curso('TEST_B', 1, 3, matematica, matematicas),
                curso('TEST_C', 1, 3, computadores, computadores),
                curso('TEST_D', 1, 3, matematica, matematicas)
            ],
            12
        ),

    validar_cobertura_carreras([Combinacion]),

    findall(
        Resultado,
        evaluar_combinacion(Combinacion, Resultado),
        Resultados
    ),

    assertion(
        Resultados ==
        [resultado(false, limite_area(computadores))]
    ).
test(
    evaluacion_rechazada_por_incompatibilidad,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            10,
            [
                curso('TEST_A', 1, 3, computadores, computadores),
                curso('TEST_B', 1, 3, matematica, matematicas)
            ],
            6
        ),

    validar_cobertura_carreras([Combinacion]),

    findall(
        Resultado,
        evaluar_combinacion(Combinacion, Resultado),
        Resultados
    ),

    assertion(
        Resultados ==
        [resultado(false, incompatibilidad('TEST_A', 'TEST_B'))]
    ).
test(
    resultado_ligado_no_permite_forzar_aceptacion,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            11,
            [
                curso('TEST_A', 1, 3, computadores, computadores),
                curso('TEST_B', 1, 3, matematica, matematicas),
                curso('TEST_C', 1, 3, computadores, computadores)
            ],
            9
        ),

    validar_cobertura_carreras([Combinacion]),

    assertion(
        \+ evaluar_combinacion(
            Combinacion,
            resultado(true, ninguna)
        )
    ),

    assertion(
        \+ evaluar_combinacion(
            Combinacion,
            resultado(false, limite_area(computadores))
        )
    ),

    assertion(
        evaluar_combinacion(
            Combinacion,
            resultado(false, balance_carrera(computadores))
        )
    ).
test(
    resultado_ligado_no_permite_forzar_rechazo,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            12,
            [
                curso('TEST_A', 1, 3, computadores, computadores),
                curso('TEST_D', 1, 3, matematica, matematicas)
            ],
            6
        ),

    validar_cobertura_carreras([Combinacion]),

    assertion(
        \+ evaluar_combinacion(
            Combinacion,
            resultado(false, _)
        )
    ),

    assertion(
        evaluar_combinacion(
            Combinacion,
            resultado(true, ninguna)
        )
    ).
test(
    evaluacion_combinacion_vacia,
    [setup(preparar_politica)]
) :-
    Combinacion = combinacion(13, [], 0),

    validar_cobertura_carreras([Combinacion]),

    findall(
        Resultado,
        evaluar_combinacion(Combinacion, Resultado),
        Resultados
    ),

    assertion(
        Resultados == [resultado(true, ninguna)]
    ).
test(
    cero_creditos_con_violacion_area,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            14,
            [
                curso('TEST_G', 1, 0, computadores, computadores),
                curso('TEST_H', 1, 0, computadores, computadores)
            ],
            0
        ),

    validar_cobertura_carreras([Combinacion]),

    cumple_balance(Combinacion),
    cumple_incompatibilidad(Combinacion),

    once(viola_limite_area(
        Combinacion,
        limite_area(computadores)
    )),

    findall(
        Resultado,
        evaluar_combinacion(Combinacion, Resultado),
        Resultados
    ),

    assertion(
        Resultados ==
        [resultado(false, limite_area(computadores))]
    ).
test(
    cambio_politica_modifica_primera_violacion,
    [
        setup(preparar_politica),
        cleanup(preparar_politica)
    ]
) :-
    Combinacion =
        combinacion(
            15,
            [
                curso('TEST_A', 1, 3, computadores, computadores),
                curso('TEST_B', 1, 3, matematica, matematicas),
                curso('TEST_C', 1, 3, computadores, computadores)
            ],
            9
        ),

    validar_cobertura_carreras([Combinacion]),

    findall(
        Resultado,
        evaluar_combinacion(Combinacion, Resultado),
        ResultadosOriginales
    ),

    assertion(
        ResultadosOriginales ==
        [resultado(false, balance_carrera(computadores))]
    ),

    cargar_politica(
        'tests/fixtures/policy/politica_evaluador_alternativa.pl'
    ),

    validar_cobertura_carreras([Combinacion]),

    cumple_balance(Combinacion),
    cumple_limite_area(Combinacion),

    findall(
        Resultado,
        evaluar_combinacion(Combinacion, Resultado),
        ResultadosAlternativos
    ),

    assertion(
        ResultadosAlternativos ==
        [resultado(false, incompatibilidad('TEST_A', 'TEST_B'))]
    ).
test(
    viola_balance_y_area_prioriza_balance,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            16,
            [
                curso('TEST_A', 1, 3, computadores, computadores),
                curso('TEST_C', 1, 3, computadores, computadores)
            ],
            6
        ),

    validar_cobertura_carreras([Combinacion]),

    once(viola_balance(Combinacion, _)),
    once(viola_limite_area(Combinacion, _)),
    cumple_incompatibilidad(Combinacion),

    findall(
        Resultado,
        evaluar_combinacion(Combinacion, Resultado),
        Resultados
    ),

    assertion(
        Resultados ==
        [resultado(false, balance_carrera(computadores))]
    ).
test(
    viola_balance_e_incompatibilidad_prioriza_balance,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            17,
            [
                curso('TEST_A', 1, 3, computadores, computadores),
                curso('TEST_B', 1, 3, matematica, matematicas),
                curso('TEST_F', 1, 3, computadores, optativas)
            ],
            9
        ),

    validar_cobertura_carreras([Combinacion]),

    once(viola_balance(Combinacion, _)),
    cumple_limite_area(Combinacion),
    once(viola_incompatibilidad(Combinacion, _)),

    findall(
        Resultado,
        evaluar_combinacion(Combinacion, Resultado),
        Resultados
    ),

    assertion(
        Resultados ==
        [resultado(false, balance_carrera(computadores))]
    ).
test(
    viola_unicamente_balance,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            18,
            [
                curso('TEST_A', 1, 3, computadores, computadores)
            ],
            3
        ),

    validar_cobertura_carreras([Combinacion]),

    once(viola_balance(Combinacion, _)),
    cumple_limite_area(Combinacion),
    cumple_incompatibilidad(Combinacion),

    findall(
        Resultado,
        evaluar_combinacion(Combinacion, Resultado),
        Resultados
    ),

    assertion(
        Resultados ==
        [resultado(false, balance_carrera(computadores))]
    ).
test(
    viola_unicamente_area,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            19,
            [
                curso('TEST_A', 1, 3, computadores, computadores),
                curso('TEST_C', 1, 3, computadores, computadores),
                curso('TEST_D', 1, 3, matematica, matematicas),
                curso('TEST_E', 1, 3, matematica, matematicas)
            ],
            12
        ),

    validar_cobertura_carreras([Combinacion]),

    cumple_balance(Combinacion),
    once(viola_limite_area(Combinacion, _)),
    cumple_incompatibilidad(Combinacion),

    findall(
        Resultado,
        evaluar_combinacion(Combinacion, Resultado),
        Resultados
    ),

    assertion(
        Resultados ==
        [resultado(false, limite_area(computadores))]
    ).
:- end_tests(evaluator).