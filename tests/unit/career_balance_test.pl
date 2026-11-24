:- use_module(library(plunit)).

:- begin_tests(career_balance).

:- use_module('../../src/rules/career_balance.pl').
:- use_module('../../src/io/policy_loader.pl').


% =========================================================
% Preparacion de politica
% =========================================================

preparar_politica :-
    cargar_politica(
        'data/policy/politica.pl'
    ).
preparar_politica_alternativa :-
    cargar_politica(
        'tests/fixtures/policy/politica_balance_alternativa.pl'
    ).


restaurar_politica :-
    cargar_politica(
        'data/policy/politica.pl'
    ).
preparar_politica_decimal :-
    cargar_politica(
        'tests/fixtures/policy/politica_balance_decimal.pl'
    ).

% =========================================================
% Pruebas
% =========================================================

test(
    debajo_del_maximo,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            1,
            [
                curso(
                    'CE1101',
                    1,
                    6,
                    computadores,
                    computadores
                ),
                curso(
                    'MA1101',
                    1,
                    4,
                    matematica,
                    matematicas
                )
            ],
            10
        ),

    cumple_balance(Combinacion).


test(
    exactamente_en_el_maximo,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            2,
            [
                curso(
                    'CE1101',
                    1,
                    7,
                    computadores,
                    computadores
                ),
                curso(
                    'MA1101',
                    1,
                    3,
                    matematica,
                    matematicas
                )
            ],
            10
        ),

    cumple_balance(Combinacion).


test(
    encima_del_maximo,
    [
        setup(preparar_politica),
        nondet
    ]
) :-
    Combinacion =
        combinacion(
            3,
            [
                curso(
                    'CE1101',
                    1,
                    8,
                    computadores,
                    computadores
                ),
                curso(
                    'MA1101',
                    1,
                    2,
                    matematica,
                    matematicas
                )
            ],
            10
        ),

    viola_balance(
        Combinacion,
        balance_carrera(computadores)
    ).
test(
    una_sola_carrera_supera_maximo,
    [
        setup(preparar_politica),
        nondet
    ]
) :-
    Combinacion =
        combinacion(
            4,
            [
                curso(
                    'CE1101',
                    1,
                    10,
                    computadores,
                    computadores
                )
            ],
            10
        ),

    viola_balance(
        Combinacion,
        balance_carrera(computadores)
    ).
test(
    evalua_varias_carreras,
    [
        setup(preparar_politica),
        nondet
    ]
) :-
    Combinacion =
        combinacion(
            5,
            [
                curso(
                    'CE1101',
                    1,
                    4,
                    computadores,
                    computadores
                ),
                curso(
                    'MA1101',
                    1,
                    6,
                    matematica,
                    matematicas
                )
            ],
            10
        ),

    viola_balance(
        Combinacion,
        balance_carrera(matematica)
    ).
test(
    cero_creditos_totales_cumple,
    [setup(preparar_politica)]
) :-
    Combinacion =
        combinacion(
            6,
            [
                curso(
                    'CE1101',
                    1,
                    0,
                    computadores,
                    computadores
                ),
                curso(
                    'MA1101',
                    1,
                    0,
                    matematica,
                    matematicas
                )
            ],
            0
        ),

    cumple_balance(Combinacion).
test(
    obtiene_maximo_desde_politica,
    [
        setup(preparar_politica_alternativa),
        cleanup(restaurar_politica),
        nondet
    ]
) :-
    Combinacion =
        combinacion(
            7,
            [
                curso(
                    'CE1101',
                    1,
                    6,
                    computadores,
                    computadores
                ),
                curso(
                    'MA1101',
                    1,
                    4,
                    matematica,
                    matematicas
                )
            ],
            10
        ),

    viola_balance(
        Combinacion,
        balance_carrera(computadores)
    ).

test(
    agrupa_creditos_de_la_misma_carrera,
    [
        setup(preparar_politica),
        nondet
    ]
) :-
    Combinacion =
        combinacion(
            8,
            [
                curso(
                    'CE1101',
                    1,
                    4,
                    computadores,
                    computadores
                ),
                curso(
                    'CE1104',
                    2,
                    4,
                    computadores,
                    computadores
                ),
                curso(
                    'MA1101',
                    1,
                    2,
                    matematica,
                    matematicas
                )
            ],
            10
        ),

    viola_balance(
        Combinacion,
        balance_carrera(computadores)
    ).
test(
    porcentaje_decimal_exactamente_en_limite,
    [
        setup(preparar_politica_decimal),
        cleanup(restaurar_politica)
    ]
) :-
    Combinacion =
        combinacion(
            9,
            [
                curso(
                    'CE1101',
                    1,
                    3,
                    computadores,
                    computadores
                ),
                curso(
                    'MA1101',
                    1,
                    5,
                    matematica,
                    matematicas
                )
            ],
            8
        ),

    cumple_balance(Combinacion).
:- end_tests(career_balance).