:- begin_tests(area_limit, [cleanup(limpiar_modulo_politica)]).

:- use_module('../../src/io/policy_loader').
:- use_module('../../src/rules/area_limit').

limpiar_modulo_politica :-
    retractall(politica:max_porcentaje_carrera(_, _)),
    retractall(politica:max_cursos_area(_)),
    retractall(politica:incompatible(_, _)).

cargar_max_area(N) :-
    limpiar_modulo_politica,
    assertz(politica:max_cursos_area(N)).


%viola_limite_area/3
test(menos_de_n_cursos_no_viola) :-
    Comb = combinacion(1, [
        curso('CE1101', 1, 4, computadores, computadores),
        curso('CE1102', 1, 4, computadores, computadores)
    ], 8),
    \+ viola_limite_area(Comb, _, 3).

test(exactamente_n_cursos_no_viola) :-
    Comb = combinacion(1, [
        curso('CE1101', 1, 4, computadores, computadores),
        curso('CE1102', 1, 4, computadores, computadores),
        curso('CE1103', 1, 4, computadores, computadores)
    ], 12),
    \+ viola_limite_area(Comb, _, 3).

test(n_mas_1_cursos_viola_con_razon_esperada) :-
    Comb = combinacion(1, [
        curso('CE1101', 1, 4, computadores, computadores),
        curso('CE1102', 1, 4, computadores, computadores),
        curso('CE1103', 1, 4, computadores, computadores),
        curso('CE1104', 1, 4, computadores, computadores)
    ], 16),
    findall(R, viola_limite_area(Comb, R, 3), Razones),
    Razones == [limite_area(computadores)].

test(varias_areas_y_solo_una_se_pasa) :-
    Comb = combinacion(2, [
        curso('MA1102', 1, 4, matematica, matematicas),
        curso('CE1101', 1, 4, computadores, computadores),
        curso('CE1102', 1, 4, computadores, computadores),
        curso('FI1101', 1, 4, fisica, ciencias_naturales),
        curso('CE1103', 1, 4, computadores, computadores)
    ], 20),
    findall(R, viola_limite_area(Comb, R, 2), Razones),
    Razones == [limite_area(computadores)].

test(dos_areas_se_pasan_respeta_orden_de_aparicion) :-
    Comb = combinacion(3, [
        curso('MA1102', 1, 4, matematica, matematicas),
        curso('CE1101', 1, 4, computadores, computadores),
        curso('FI1101', 1, 4, fisica, ciencias_naturales),
        curso('CE1102', 1, 4, computadores, computadores),
        curso('MA1103', 1, 4, matematica, matematicas)
    ], 20),
    once(viola_limite_area(Comb, PrimeraRazon, 1)),
    PrimeraRazon == limite_area(matematicas),
    findall(R, viola_limite_area(Comb, R, 1), TodasRazones),
    TodasRazones == [limite_area(matematicas), limite_area(computadores)].

test(curso_de_cero_creditos_cuenta_como_uno) :-
    Comb = combinacion(4, [
        curso('SE1100', 1, 0, computadores, optativas),
        curso('SE1101', 1, 0, computadores, optativas)
    ], 0),
    findall(R, viola_limite_area(Comb, R, 1), Razones),
    Razones == [limite_area(optativas)].

test(cursos_con_distinto_grupo_cuentan_igual) :-
    Comb = combinacion(5, [
        curso('MA1102', 1, 4, matematica, matematicas),
        curso('MA1103', 5, 4, matematica, matematicas),
        curso('MA2104', 12, 4, matematica, matematicas)
    ], 12),
    findall(R, viola_limite_area(Comb, R, 2), Razones),
    Razones == [limite_area(matematicas)].

test(combinacion_vacia_cumple, [setup(cargar_max_area(0))]) :-
    Comb = combinacion(6, [], 0),
    \+ viola_limite_area(Comb, _, 0),
    cumple_limite_area(Comb).


%viola_limite_area/2 Y cumple_limite_area/1
test(viola_limite_area_2_con_politica_cargada, [setup(cargar_max_area(2))]) :-
    Comb = combinacion(7, [
        curso('CE1101', 1, 4, computadores, computadores),
        curso('CE1102', 2, 4, computadores, computadores),
        curso('CE1103', 3, 4, computadores, computadores)
    ], 12),
    findall(R, viola_limite_area(Comb, R), Razones),
    Razones == [limite_area(computadores)].

test(viola_limite_area_2_sin_politica_lanza_error, [
    setup(limpiar_modulo_politica),
    throws(error(e3_policy(max_cursos_area_faltante), _))
]) :-
    Comb = combinacion(8, [
        curso('CE1101', 1, 4, computadores, computadores)
    ], 4),
    viola_limite_area(Comb, _).

test(cumple_limite_area_verdadero_y_falso, [setup(cargar_max_area(2))]) :-
    CombValida = combinacion(9, [
        curso('CE1101', 1, 4, computadores, computadores),
        curso('MA1102', 1, 4, matematica, matematicas),
        curso('CE1102', 1, 4, computadores, computadores)
    ], 12),
    CombInvalida = combinacion(10, [
        curso('CE1101', 1, 4, computadores, computadores),
        curso('CE1102', 1, 4, computadores, computadores),
        curso('CE1103', 1, 4, computadores, computadores)
    ], 12),
    cumple_limite_area(CombValida),
    \+ cumple_limite_area(CombInvalida).

:- end_tests(area_limit).