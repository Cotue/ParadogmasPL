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


% =========================================================
% Recorrido de todas las combinaciones (KANE3-41)
% =========================================================

% evaluacion(?Id, -Evaluado)
%
% Evaluado = evaluado(combinacion(Id, Cursos, CreditosTotales), Resultado)
%
% Obtiene cada hecho combinacion/3 y lo evalua.
% - Con Id libre: enumera TODAS las combinaciones por
%   backtracking, en el orden en que fueron registradas
%   (orden de Id, porque assertz conserva el orden de la
%   lista producida por cargar_combinaciones/2).
% - Con Id ligado: devuelve solo la evaluacion de esa
%   combinacion; falla si no existe ninguna con ese Id.
%
% La combinacion se entrega tal como esta en los hechos:
% Prolog no crea, elimina, reordena ni modifica combinaciones.
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


% evaluar_una(+Combinacion, -Resultado)   (privado)
%
% Garantiza EXACTAMENTE un resultado por combinacion.
%
% Por que (Contrato Maestro §42 y §50): findall/3 recolecta
% una solucion por cada exito del objetivo. Si la evaluacion
% dejara dos soluciones, la combinacion saldria duplicada; si
% fallara, la combinacion desapareceria en silencio. Por eso:
% - el if-then-else toma solo la primera solucion de
%   evaluar_combinacion/2 (nunca duplica);
% - si no hay solucion, se lanza un error explicito en lugar
%   de fallar (nunca se pierde una combinacion).
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
