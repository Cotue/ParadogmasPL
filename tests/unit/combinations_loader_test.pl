:- use_module(library(plunit)).

:- begin_tests(combinations_loader).

:- use_module('../../src/io/combinations_loader.pl').

test(carga_archivo_valido_vacio) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/valid_empty.json',
        Combinaciones
    ),
    assertion(Combinaciones == []).


test(
    rechaza_version_no_soportada,
    [
        throws(
            error(
                e3_schema(version_no_soportada("2.0")),
                _
            )
        )
    ]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_schema_version.json',
        _
    ).


test(carga_una_combinacion_valida) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/valid_single_combination.json',
        Combinaciones
    ),
    assertion(
        Combinaciones ==
        [
            combinacion(
                1,
                [
                    curso(
                        'CE1101',
                        1,
                        3,
                        'Computadores',
                        computadores
                    ),
                    curso(
                        'CE1104',
                        2,
                        3,
                        'Computadores',
                        computadores
                    ),
                    curso(
                        'MA1403',
                        4,
                        4,
                        'Computadores',
                        matematicas
                    )
                ],
                10
            )
        ]
    ).


test(
    rechaza_schema_version_ausente,
    [
        throws(
            error(
                e3_schema(campo_faltante(schemaVersion)),
                _
            )
        )
    ]

) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_missing_schema.json',
        _
    ).

test(asigna_ids_secuenciales) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/valid_two_combinations.json',
        Combinaciones
    ),
    assertion(
        Combinaciones =
        [
            combinacion(1, _, 10),
            combinacion(2, _, 10)
        ]
    ).
test(
    rechaza_curso_ausente,
    [throws(error(e3_schema(campo_faltante(curso)), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_missing_curso.json',
        _
    ).


test(
    rechaza_grupo_ausente,
    [throws(error(e3_schema(campo_faltante(grupo)), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_missing_grupo.json',
        _
    ).


test(
    rechaza_creditos_ausentes,
    [throws(error(e3_schema(campo_faltante(creditos)), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_missing_creditos.json',
        _
    ).


test(
    rechaza_carrera_ausente,
    [throws(error(e3_schema(campo_faltante(carrera)), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_missing_carrera.json',
        _
    ).


test(
    rechaza_area_ausente,
    [throws(error(e3_schema(campo_faltante(area)), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_missing_area.json',
        _
    ).
test(
    rechaza_curso_vacio,
    [throws(error(e3_schema(valor_invalido(curso, "")), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_empty_curso.json',
        _
    ).


test(
    rechaza_grupo_cero,
    [throws(error(e3_schema(valor_invalido(grupo, 0)), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_group_zero.json',
        _
    ).


test(
    rechaza_grupo_no_entero,
    [throws(error(e3_schema(valor_invalido(grupo, 1.5)), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_group_non_integer.json',
        _
    ).


test(
    rechaza_creditos_negativos,
    [throws(error(e3_schema(valor_invalido(creditos, -1)), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_negative_credits.json',
        _
    ).


test(
    rechaza_creditos_no_enteros,
    [throws(error(e3_schema(valor_invalido(creditos, 3.5)), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_credits_non_integer.json',
        _
    ).


test(
    rechaza_carrera_vacia,
    [throws(error(e3_schema(valor_invalido(carrera, "")), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_empty_carrera.json',
        _
    ).


test(
    rechaza_area_vacia,
    [throws(error(e3_schema(valor_invalido(area, "")), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_empty_area.json',
        _
    ).
test(
    rechaza_creditos_totales_ausentes,
    [throws(error(e3_schema(campo_faltante(creditosTotales)), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_missing_total_credits.json',
        _
    ).


test(
    rechaza_creditos_totales_negativos,
    [throws(error(e3_schema(valor_invalido(creditosTotales, -1)), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_negative_total_credits.json',
        _
    ).


test(
    rechaza_creditos_totales_no_enteros,
    [throws(error(e3_schema(valor_invalido(creditosTotales, 3.5)), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_total_credits_non_integer.json',
        _
    ).


test(
    rechaza_suma_creditos_inconsistente,
    [
        throws(
            error(
                e3_schema(
                    creditos_totales_inconsistentes(10, 6)
                ),
                _
            )
        )
    ]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_total_credits_mismatch.json',
        _
    ).
test(
    rechaza_combinaciones_ausentes,
    [throws(error(e3_schema(campo_faltante(combinaciones)), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_missing_combinations.json',
        _
    ).


test(
    rechaza_selecciones_ausentes,
    [throws(error(e3_schema(campo_faltante(selecciones)), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_missing_selections.json',
        _
    ).
test(
    rechaza_combinaciones_que_no_son_lista,
    [throws(error(e3_schema(tipo_invalido(combinaciones, _)), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_combinations_not_list.json',
        _
    ).


test(
    rechaza_selecciones_que_no_son_lista,
    [throws(error(e3_schema(tipo_invalido(selecciones, _)), _))]
) :-
    cargar_combinaciones(
        'tests/fixtures/combinations/invalid_selections_not_list.json',
        _
    ).
:- end_tests(combinations_loader).