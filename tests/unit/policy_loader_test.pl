:- begin_tests(policy_loader, [cleanup(limpiar_modulo_politica)]).

:- use_module('../../src/io/policy_loader').
:- use_module('../../src/io/combinations_loader').

limpiar_modulo_politica :-
    retractall(politica:max_porcentaje_carrera(_, _)),
    retractall(politica:max_cursos_area(_)),
    retractall(politica:incompatible(_, _)).

% ============================================================================
% CASOS VÁLIDOS
% ============================================================================

test(politica_valida_completa_carga_en_modulo, [setup(limpiar_modulo_politica)]) :-
    cargar_politica('tests/fixtures/policy/politica_valida.pl'),
    politica:max_porcentaje_carrera(computadores, 70),
    politica:max_porcentaje_carrera(matematica, 50),
    politica:max_porcentaje_carrera(fisica, 40),
    politica:max_porcentaje_carrera(quimica, 40),
    politica:max_cursos_area(3),
    politica:incompatible(ic1802, ic1803),
    politica:incompatible(ma1102, ma1103).

test(politica_sin_incompatibles_es_valida, [setup(limpiar_modulo_politica)]) :-
    cargar_politica('tests/fixtures/policy/politica_sin_incompatibles.pl'),
    politica:max_porcentaje_carrera(computadores, 65),
    politica:max_porcentaje_carrera(matematica, 55),
    politica:max_cursos_area(2),
    \+ politica:incompatible(_, _).

test(porcentajes_limite_flotante_y_repetido_identico, [setup(limpiar_modulo_politica)]) :-
    cargar_politica('tests/fixtures/policy/politica_limites_y_repetido.pl'),
    politica:max_porcentaje_carrera(computadores, 0),
    politica:max_porcentaje_carrera(matematica, 100),
    findall(P, politica:max_porcentaje_carrera(fisica, P), ListaFisica),
    ListaFisica == [37.5],
    politica:max_cursos_area(0).

test(recargar_politica_reemplaza_completamente_valores_anteriores, [setup(limpiar_modulo_politica)]) :-
    cargar_politica('tests/fixtures/policy/politica_valida.pl'),
    politica:max_porcentaje_carrera(fisica, 40),
    cargar_politica('tests/fixtures/policy/politica_alternativa.pl'),
    politica:max_porcentaje_carrera(computadores, 80),
    politica:max_porcentaje_carrera(quimica, 25),
    politica:max_cursos_area(4),
    politica:incompatible(qu1101, qu1102),
    \+ politica:max_porcentaje_carrera(fisica, _),
    \+ politica:max_porcentaje_carrera(matematica, _),
    \+ politica:incompatible(ic1802, ic1803).

% ============================================================================
% CASOS INVÁLIDOS (ARCHIVO, SINTAXIS, VACÍO Y ATOMICIDAD)
% ============================================================================

test(archivo_inexistente_lanza_error, [
    setup(limpiar_modulo_politica),
    throws(error(e3_policy(archivo_inexistente('tests/fixtures/policy/no_existe.pl')), _))
]) :-
    cargar_politica('tests/fixtures/policy/no_existe.pl').

test(error_de_sintaxis_lanza_error, [
    setup(limpiar_modulo_politica),
    throws(error(e3_policy(sintaxis(_)), _))
]) :-
    cargar_politica('tests/fixtures/policy/politica_sintaxis_error.pl').

% Documentación de precedencia: ante archivo/lista vacía se verifica primero
% max_cursos_area_faltante antes que sin_porcentajes.
test(archivo_vacio_lanza_max_cursos_area_faltante, [
    setup(limpiar_modulo_politica),
    throws(error(e3_policy(max_cursos_area_faltante), _))
]) :-
    cargar_politica('tests/fixtures/policy/politica_vacia.pl').

test(politica_invalida_no_deja_hechos_cargados, [setup(limpiar_modulo_politica)]) :-
    catch(
        cargar_politica('tests/fixtures/policy/politica_invalida_parcial.pl'),
        error(e3_policy(porcentajes_contradictorios(computadores, 70, 60)), _),
        true
    ),
    \+ politica:max_cursos_area(_),
    \+ politica:max_porcentaje_carrera(_, _).

test(directiva_en_archivo_es_rechazada, [
    setup(limpiar_modulo_politica),
    throws(error(e3_policy(hecho_desconocido((:- _))), _))
]) :-
    cargar_politica('tests/fixtures/policy/politica_con_directiva.pl').

% ============================================================================
% CASOS INVÁLIDOS PUROS (validar_politica/1)
% ============================================================================

test(carrera_no_atomo_invalida, [
    throws(error(e3_policy(carrera_invalida(123)), _))
]) :-
    validar_politica([max_porcentaje_carrera(123, 50), max_cursos_area(2)]).

test(porcentaje_mayor_100_invalido, [
    throws(error(e3_policy(porcentaje_invalido(computadores, 100.1)), _))
]) :-
    validar_politica([max_porcentaje_carrera(computadores, 100.1), max_cursos_area(2)]).

test(porcentaje_negativo_invalido, [
    throws(error(e3_policy(porcentaje_invalido(computadores, -1)), _))
]) :-
    validar_politica([max_porcentaje_carrera(computadores, -1), max_cursos_area(2)]).

test(porcentaje_no_numerico_invalido, [
    throws(error(e3_policy(porcentaje_invalido(computadores, cincuenta)), _))
]) :-
    validar_politica([max_porcentaje_carrera(computadores, cincuenta), max_cursos_area(2)]).

test(porcentajes_contradictorios_invalidos, [
    throws(error(e3_policy(porcentajes_contradictorios(matematica, 50, 60)), _))
]) :-
    validar_politica([
        max_porcentaje_carrera(matematica, 50),
        max_porcentaje_carrera(matematica, 60),
        max_cursos_area(2)
    ]).

test(sin_porcentajes_cuando_hay_max_area, [
    throws(error(e3_policy(sin_porcentajes), _))
]) :-
    validar_politica([max_cursos_area(3)]).

test(max_cursos_area_faltante, [
    throws(error(e3_policy(max_cursos_area_faltante), _))
]) :-
    validar_politica([max_porcentaje_carrera(computadores, 70)]).

test(max_cursos_area_duplicado, [
    throws(error(e3_policy(max_cursos_area_duplicado), _))
]) :-
    validar_politica([
        max_porcentaje_carrera(computadores, 70),
        max_cursos_area(3),
        max_cursos_area(4)
    ]).

test(max_cursos_area_negativo, [
    throws(error(e3_policy(max_cursos_area_invalido(-2)), _))
]) :-
    validar_politica([
        max_porcentaje_carrera(computadores, 70),
        max_cursos_area(-2)
    ]).

test(max_cursos_area_no_entero, [
    throws(error(e3_policy(max_cursos_area_invalido(2.5)), _))
]) :-
    validar_politica([
        max_porcentaje_carrera(computadores, 70),
        max_cursos_area(2.5)
    ]).

test(curso_invalido_en_incompatible, [
    throws(error(e3_policy(curso_invalido("IC1802")), _))
]) :-
    validar_politica([
        max_porcentaje_carrera(computadores, 70),
        max_cursos_area(3),
        incompatible("IC1802", ic1803)
    ]).

test(curso_autoincompatible, [
    throws(error(e3_policy(autoincompatible(ic1802)), _))
]) :-
    validar_politica([
        max_porcentaje_carrera(computadores, 70),
        max_cursos_area(3),
        incompatible(ic1802, ic1802)
    ]).

test(par_incompatible_duplicado_exacto, [
    throws(error(e3_policy(par_duplicado(ic1802, ic1803)), _))
]) :-
    validar_politica([
        max_porcentaje_carrera(computadores, 70),
        max_cursos_area(3),
        incompatible(ic1802, ic1803),
        incompatible(ic1802, ic1803)
    ]).

test(par_incompatible_duplicado_invertido, [
    throws(error(e3_policy(par_duplicado(ic1803, ic1802)), _))
]) :-
    validar_politica([
        max_porcentaje_carrera(computadores, 70),
        max_cursos_area(3),
        incompatible(ic1802, ic1803),
        incompatible(ic1803, ic1802)
    ]).

test(hecho_desconocido_invalido, [
    throws(error(e3_policy(hecho_desconocido(creditos_minimos(12))), _))
]) :-
    validar_politica([
        max_porcentaje_carrera(computadores, 70),
        max_cursos_area(3),
        creditos_minimos(12)
    ]).

% ============================================================================
% COBERTURA DE CARRERAS Y PRUEBA DE INTEGRACIÓN LIGERA
% ============================================================================

test(cobertura_carreras_exitosa, [setup(limpiar_modulo_politica)]) :-
    cargar_politica('tests/fixtures/policy/politica_valida.pl'),
    Combinaciones = [
        combinacion('C1', [curso(ic1802, 1, 4, computadores, prog)], 4),
        combinacion('C2', [curso(ma1102, 1, 4, matematica, calc)], 4)
    ],
    validar_cobertura_carreras(Combinaciones).

test(cobertura_carrera_sin_porcentaje_falla, [
    setup(limpiar_modulo_politica),
    throws(error(e3_policy(carrera_sin_porcentaje(quimica)), _))
]) :-
    cargar_politica('tests/fixtures/policy/politica_sin_incompatibles.pl'),
    Combinaciones = [
        combinacion('C1', [
            curso(ic1802, 1, 4, computadores, prog),
            curso(qu1101, 1, 3, quimica, basicas)
        ], 7)
    ],
    validar_cobertura_carreras(Combinaciones).

test(cobertura_lista_vacia_exitosa, [setup(limpiar_modulo_politica)]) :-
    validar_cobertura_carreras([]).

test(integracion_ligera_politica_inicial_y_combinaciones_json, [setup(limpiar_modulo_politica)]) :-
    cargar_politica('data/policy/politica.pl'),
    cargar_combinaciones('tests/fixtures/policy/combinaciones_reales.json', Combinaciones),
    validar_cobertura_carreras(Combinaciones).

:- end_tests(policy_loader).