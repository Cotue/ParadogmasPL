:- module(area_limit, [
    viola_limite_area/2,
    viola_limite_area/3,
    cumple_limite_area/1
]).


viola_limite_area(Combinacion, Razon) :-
    (   politica:max_cursos_area(Max)
    ->  true
    ;   throw(error(e3_policy(max_cursos_area_faltante),
                    context(viola_limite_area/2, 'Falta definir max_cursos_area/1 en politica')))
    ),
    viola_limite_area(Combinacion, Razon, Max).

viola_limite_area(combinacion(_, Cursos, _), limite_area(Area), Max) :-
    areas_unicas_en_orden(Cursos, [], Areas),
    member(Area, Areas),
    contar_cursos_area(Cursos, Area, Cantidad),
    Cantidad > Max.

cumple_limite_area(Combinacion) :-
    \+ viola_limite_area(Combinacion, _).

areas_unicas_en_orden([], _, []).
areas_unicas_en_orden([curso(_, _, _, _, Area) | Resto], Vistas, Areas) :-
    (   memberchk(Area, Vistas)
    ->  areas_unicas_en_orden(Resto, Vistas, Areas)
    ;   Areas = [Area | RestoAreas],
        areas_unicas_en_orden(Resto, [Area | Vistas], RestoAreas)
    ).

contar_cursos_area([], _, 0).
contar_cursos_area([curso(_, _, _, _, AreaCurso) | Resto], Area, Total) :-
    contar_cursos_area(Resto, Area, SubTotal),
    (   AreaCurso == Area
    ->  Total is SubTotal + 1
    ;   Total = SubTotal
    ).