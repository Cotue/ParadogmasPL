:- module(career_balance, [
    viola_balance/2,
    cumple_balance/1
]).
:- dynamic politica:max_porcentaje_carrera/2.

% =========================================================
% Regla de balance entre carreras
% =========================================================

% viola_balance(+Combinacion, -Razon)
%
% Una combinacion viola la regla cuando alguna carrera
% supera el porcentaje maximo de creditos permitido
% por la politica academica.
viola_balance(
    combinacion(_, Cursos, CreditosTotales),
    balance_carrera(Carrera)
) :-
    member(
        curso(_, _, _, Carrera, _),
        Cursos
    ),
    politica:max_porcentaje_carrera(
        Carrera,
        MaxPorcentaje
    ),
    creditos_por_carrera(
        Cursos,
        Carrera,
        CreditosCarrera
    ),
    supera_porcentaje(
        CreditosCarrera,
        CreditosTotales,
        MaxPorcentaje
    ).


% cumple_balance(+Combinacion)
%
% Una combinacion cumple cuando no existe ninguna
% carrera que viole su porcentaje maximo.
cumple_balance(Combinacion) :-
    \+ viola_balance(
        Combinacion,
        _
    ).


% =========================================================
% Calculo de creditos por carrera
% =========================================================

creditos_por_carrera([], _, 0).

creditos_por_carrera(
    [
        curso(_, _, Creditos, Carrera, _)
        | Resto
    ],
    Carrera,
    Total
) :-
    creditos_por_carrera(
        Resto,
        Carrera,
        TotalResto
    ),
    Total is Creditos + TotalResto.

creditos_por_carrera(
    [
        curso(_, _, _, OtraCarrera, _)
        | Resto
    ],
    Carrera,
    Total
) :-
    OtraCarrera \== Carrera,
    creditos_por_carrera(
        Resto,
        Carrera,
        Total
    ).


% =========================================================
% Comparacion de porcentaje
% =========================================================

% Una combinación de cero créditos no viola la regla de balance.
supera_porcentaje(
    _CreditosCarrera,
    0,
    _MaxPorcentaje
) :-
    fail.

supera_porcentaje(
    CreditosCarrera,
    CreditosTotales,
    MaxPorcentaje
) :-
    CreditosTotales > 0,
    CreditosCarrera * 100
    >
    CreditosTotales * MaxPorcentaje.