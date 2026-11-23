:- module(combination_queries, [
    registrar_combinaciones/1,
    combinacion/3,
    curso_en_combinacion/2
]).

:- dynamic combinacion/3.

%registrar_combinaciones(+Lista)
registrar_combinaciones(Combinaciones) :-
    retractall(combinacion(_, _, _)),
    forall(member(Comb, Combinaciones), registrar_una(Comb)).

registrar_una(combinacion(Id, Cursos, CreditosTotales)) :-
    assertz(combinacion(Id, Cursos, CreditosTotales)).

%curso_en_combinacion(?Id, ?Curso)
curso_en_combinacion(Id, Curso) :-
    combinacion(Id, Cursos, _),
    member(Curso, Cursos).