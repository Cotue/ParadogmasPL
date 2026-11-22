:- module(incompatibility, [
    son_incompatibles/2,
    viola_incompatibilidad/2,
    cumple_incompatibilidad/1
]).

% son_incompatibles(?A, ?B)
son_incompatibles(A, B) :-
    politica:incompatible(A, B).
son_incompatibles(A, B) :-
    politica:incompatible(B, A).

% viola_incompatibilidad(+Combinacion, -Razon)
viola_incompatibilidad(combinacion(_, Cursos, _), incompatibilidad(CodigoA, CodigoB)) :-
    par_ordenado(Cursos, CodigoA, CodigoB),
    son_incompatibles(CodigoA, CodigoB).

% cumple_incompatibilidad(+Combinacion)
cumple_incompatibilidad(Combinacion) :-
    \+ viola_incompatibilidad(Combinacion, _).


%genera pares (A, B) donde A aparece antes que B en la combinacion.
par_ordenado([curso(A, _, _, _, _) | Resto], A, B) :-
    member(curso(B, _, _, _, _), Resto).
par_ordenado([_ | Resto], A, B) :-
    par_ordenado(Resto, A, B).