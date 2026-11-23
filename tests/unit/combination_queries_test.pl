% tests/unit/combination_queries_test.pl
:- begin_tests(combination_queries, [
    setup(cargar_combinaciones_prueba),
    cleanup(registrar_combinaciones([]))
]).

:- use_module('../../src/domain/combination_queries').

cargar_combinaciones_prueba :-
    registrar_combinaciones([
        combinacion(1, [
            curso('CE1101', 1, 4, computadores, computadores),
            curso('MA1102', 1, 4, matematica, matematicas)
        ], 8),
        combinacion(2, [
            curso('CE1101', 2, 4, computadores, computadores),
            curso('FI1101', 1, 4, fisica, ciencias_naturales)
        ], 8),
        combinacion(3, [
            curso('MA1103', 2, 4, matematica, matematicas),
            curso('CE2101', 1, 4, computadores, computadores)
        ], 8)
    ]).

%consultas multimodo
test(id_conocido_curso_libre_devuelve_cursos_en_orden) :-
    findall(C, curso_en_combinacion(1, C), Cursos),
    Cursos == [
        curso('CE1101', 1, 4, computadores, computadores),
        curso('MA1102', 1, 4, matematica, matematicas)
    ].

test(curso_parcialmente_ligado_con_id_libre_unifica_atributos) :-
    findall(
        resultado(Id, G, Cr, Ca, A),
        curso_en_combinacion(Id, curso('CE1101', G, Cr, Ca, A)),
        Resultados
    ),
    Resultados == [
        resultado(1, 1, 4, computadores, computadores),
        resultado(2, 2, 4, computadores, computadores)
    ].

test(buscar_por_un_solo_atributo_area_matematicas) :-
    findall(
        Id-Cod,
        curso_en_combinacion(Id, curso(Cod, _, _, _, matematicas)),
        Resultados
    ),
    Resultados == [1-'MA1102', 3-'MA1103'].

test(id_y_curso_ligados_verdadero_y_falso) :-
    curso_en_combinacion(2, curso('FI1101', 1, 4, fisica, ciencias_naturales)),
    \+ curso_en_combinacion(1, curso('FI1101', 1, 4, fisica, ciencias_naturales)),
    \+ curso_en_combinacion(1, curso('CE1101', 2, 4, computadores, computadores)).

test(curso_inexistente_en_combinaciones_falla) :-
    \+ curso_en_combinacion(_, curso('XX9999', _, _, _, _)).

%gestion dinamica
test(registrar_combinaciones_reemplaza_hechos_anteriores, [cleanup(cargar_combinaciones_prueba)]) :-
    registrar_combinaciones([
        combinacion(10, [curso('CE3101', 1, 4, computadores, computadores)], 4),
        combinacion(20, [curso('MA2104', 1, 4, matematica, matematicas)], 4)
    ]),
    findall(Id, combinacion(Id, _, _), Ids),
    Ids == [10, 20],
    \+ combinacion(1, _, _).

test(registrar_combinaciones_vacia_deja_cero_hechos, [cleanup(cargar_combinaciones_prueba)]) :-
    registrar_combinaciones([]),
    \+ combinacion(_, _, _).

:- end_tests(combination_queries).