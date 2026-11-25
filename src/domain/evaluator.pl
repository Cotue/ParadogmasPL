:- module(evaluator, [
    primera_violacion/2,
    evaluar_combinacion/2
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


% =========================================================
% Primera violacion de politica academica
% =========================================================

% primera_violacion(+Combinacion, -Razon)
%
% Retorna la primera violacion segun el orden establecido:
% 1. Balance entre carreras.
% 2. Limite de cursos por area.
% 3. Incompatibilidad entre cursos.
%
% Falla si la combinacion cumple todas las reglas.
% Requiere una combinacion y una politica previamente validadas.

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
% =========================================================
% Evaluacion completa de una combinacion
% =========================================================

% evaluar_combinacion(+Combinacion, -Resultado)
%
% Devuelve exactamente un resultado para una combinacion
% valida y una politica previamente cargada y validada.
%
% Si existe una violacion, devuelve resultado(false, Razon).
% Si no existe ninguna, devuelve resultado(true, ninguna).

evaluar_combinacion(Combinacion, Resultado) :-
    primera_violacion(Combinacion, Razon),
    !,
    Resultado = resultado(false, Razon).

evaluar_combinacion(Combinacion, Resultado) :-
    \+ primera_violacion(Combinacion, _),
    Resultado = resultado(true, ninguna).