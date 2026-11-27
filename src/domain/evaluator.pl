:- module(evaluator, [
    primera_violacion/2,
    evaluar_combinacion/2,
    evaluacion/2,
    evaluar_todas/1
]).

:- use_module('../rules/career_balance.pl', [
    viola_balance/2
]).

:- use_module('../rules/area_limit.pl', [
    viola_limite_area/2
]).

:- use_module('../rules/incompatibility.pl', [
    viola_incompatibilidad/2
]).

% Hechos combinacion/3 registrados por registrar_combinaciones/1
% (KANE3-39). Se reutiliza ese mecanismo; no se crea otro.
:- use_module('combination_queries.pl', [
    combinacion/3
]).




primera_violacion(Combinacion, Razon) :-
    viola_balance(Combinacion, RazonEncontrada),
    !,
    Razon = RazonEncontrada.

primera_violacion(Combinacion, Razon) :-
    viola_limite_area(Combinacion, RazonEncontrada),
    !,
    Razon = RazonEncontrada.

primera_violacion(Combinacion, Razon) :-
    viola_incompatibilidad(Combinacion, RazonEncontrada),
    !,
    Razon = RazonEncontrada.




evaluar_combinacion(Combinacion, Resultado) :-
    primera_violacion(Combinacion, Razon),
    !,
    Resultado = resultado(false, Razon).

evaluar_combinacion(Combinacion, Resultado) :-
    \+ primera_violacion(Combinacion, _),
    Resultado = resultado(true, ninguna).


evaluacion(Id, evaluado(Combinacion, Resultado)) :-
    combinacion(Id, Cursos, CreditosTotales),
    Combinacion = combinacion(Id, Cursos, CreditosTotales),
    evaluar_una(Combinacion, Resultado).


% evaluar_todas(-Evaluados)
%
% Recolecta con findall/3 todas las soluciones de
% evaluacion/2. La lista queda en orden de Id.
% Si no hay hechos combinacion/3, Evaluados = [].
evaluar_todas(Evaluados) :-
    findall(
        Evaluado,
        evaluacion(_Id, Evaluado),
        Evaluados
    ).



evaluar_una(Combinacion, Resultado) :-
    (   evaluar_combinacion(Combinacion, ResultadoEncontrado)
    ->  Resultado = ResultadoEncontrado
    ;   Combinacion = combinacion(Id, _, _),
        throw(
            error(
                e3_evaluacion(sin_resultado(Id)),
                context(
                    evaluar_una/2,
                    'La evaluacion de la combinacion no produjo resultado'
                )
            )
        )
    ).
