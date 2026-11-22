:- begin_tests(incompatibility, [cleanup(limpiar_modulo_politica)]).

:- use_module('../../src/io/policy_loader').
:- use_module('../../src/rules/incompatibility').

limpiar_modulo_politica :-
    retractall(politica:max_porcentaje_carrera(_, _)),
    retractall(politica:max_cursos_area(_)),
    retractall(politica:incompatible(_, _)).

cargar_pares(Pares) :-
    limpiar_modulo_politica,
    forall(member(incompatible(A, B), Pares), assertz(politica:incompatible(A, B))).


%son_incompatibles/2
test(son_incompatibles_funciona_en_ambos_sentidos, [
    setup(cargar_pares([incompatible('CE1101', 'CE1102')]))
]) :-
    son_incompatibles('CE1101', 'CE1102'),
    son_incompatibles('CE1102', 'CE1101').

%presencia y ausencia de cursos del par
test(ningun_curso_del_par_presente_cumple, [
    setup(cargar_pares([incompatible('CE1101', 'CE1102')]))
]) :-
    Comb = combinacion(1, [
        curso('MA1102', 1, 4, matematica, matematicas),
        curso('FI1101', 1, 4, fisica, ciencias_naturales)
    ], 8),
    \+ viola_incompatibilidad(Comb, _),
    cumple_incompatibilidad(Comb).

test(solo_primer_curso_presente_cumple, [
    setup(cargar_pares([incompatible('CE1101', 'CE1102')]))
]) :-
    Comb = combinacion(2, [
        curso('CE1101', 1, 4, computadores, computadores),
        curso('MA1102', 1, 4, matematica, matematicas)
    ], 8),
    \+ viola_incompatibilidad(Comb, _),
    cumple_incompatibilidad(Comb).

test(solo_segundo_curso_presente_cumple, [
    setup(cargar_pares([incompatible('CE1101', 'CE1102')]))
]) :-
    Comb = combinacion(3, [
        curso('MA1102', 1, 4, matematica, matematicas),
        curso('CE1102', 1, 4, computadores, computadores)
    ], 8),
    \+ viola_incompatibilidad(Comb, _),
    cumple_incompatibilidad(Comb).

test(ambos_cursos_presentes_viola, [
    setup(cargar_pares([incompatible('CE1101', 'CE1102')]))
]) :-
    Comb = combinacion(4, [
        curso('CE1101', 1, 4, computadores, computadores),
        curso('MA1102', 1, 4, matematica, matematicas),
        curso('CE1102', 1, 4, computadores, computadores)
    ], 12),
    findall(R, viola_incompatibilidad(Comb, R), Razones),
    Razones == [incompatibilidad('CE1101', 'CE1102')].

%pruebas simetria por orden
test(par_declarado_invertido_reporta_en_orden_de_combinacion, [
    setup(cargar_pares([incompatible('B', 'A')]))
]) :-
    Comb = combinacion(5, [
        curso('A', 1, 4, computadores, computadores),
        curso('B', 1, 4, computadores, computadores)
    ], 8),
    findall(R, viola_incompatibilidad(Comb, R), Razones),
    Razones == [incompatibilidad('A', 'B')].

test(grupos_distintos_siguen_violando, [
    setup(cargar_pares([incompatible('CE1101', 'CE1102')]))
]) :-
    Comb = combinacion(6, [
        curso('CE1101', 3, 4, computadores, computadores),
        curso('CE1102', 12, 4, computadores, computadores)
    ], 8),
    findall(R, viola_incompatibilidad(Comb, R), Razones),
    Razones == [incompatibilidad('CE1101', 'CE1102')].

test(dos_pares_violados_salen_en_orden_de_aparicion, [
    setup(cargar_pares([
        incompatible('CE2101', 'CE2102'),
        incompatible('MA1102', 'MA1103')
    ]))
]) :-
    Comb = combinacion(7, [
        curso('MA1102', 1, 4, matematica, matematicas),
        curso('CE2101', 1, 4, computadores, computadores),
        curso('MA1103', 1, 4, matematica, matematicas),
        curso('CE2102', 1, 4, computadores, computadores)
    ], 16),
    once(viola_incompatibilidad(Comb, PrimeraRazon)),
    PrimeraRazon == incompatibilidad('MA1102', 'MA1103'),
    findall(R, viola_incompatibilidad(Comb, R), TodasRazones),
    TodasRazones == [
        incompatibilidad('MA1102', 'MA1103'),
        incompatibilidad('CE2101', 'CE2102')
    ].

test(varios_pares_declarados_y_solo_uno_presente, [
    setup(cargar_pares([
        incompatible('CE1101', 'CE1102'),
        incompatible('MA1102', 'MA1103'),
        incompatible('FI1101', 'FI1102')
    ]))
]) :-
    Comb = combinacion(8, [
        curso('CE1101', 1, 4, computadores, computadores),
        curso('MA1102', 1, 4, matematica, matematicas),
        curso('FI1101', 1, 4, fisica, ciencias_naturales),
        curso('MA1103', 2, 4, matematica, matematicas)
    ], 16),
    findall(R, viola_incompatibilidad(Comb, R), Razones),
    Razones == [incompatibilidad('MA1102', 'MA1103')].

%prueba de politica sin pares
test(sin_pares_cargados_cumple, [setup(limpiar_modulo_politica)]) :-
    Comb = combinacion(9, [
        curso('CE1101', 1, 4, computadores, computadores),
        curso('CE1102', 1, 4, computadores, computadores)
    ], 8),
    \+ viola_incompatibilidad(Comb, _),
    cumple_incompatibilidad(Comb).

test(combinacion_vacia_cumple, [
    setup(cargar_pares([incompatible('CE1101', 'CE1102')]))
]) :-
    Comb = combinacion(10, [], 0),
    \+ viola_incompatibilidad(Comb, _),
    cumple_incompatibilidad(Comb).

test(cumple_incompatibilidad_verdadero_y_falso, [
    setup(cargar_pares([incompatible('CE1101', 'CE1102')]))
]) :-
    CombValida = combinacion(11, [
        curso('CE1101', 1, 4, computadores, computadores),
        curso('MA1102', 1, 4, matematica, matematicas)
    ], 8),
    CombInvalida = combinacion(12, [
        curso('CE1101', 1, 4, computadores, computadores),
        curso('CE1102', 1, 4, computadores, computadores)
    ], 8),
    cumple_incompatibilidad(CombValida),
    \+ cumple_incompatibilidad(CombInvalida).

:- end_tests(incompatibility).