# Contrato KANE3-40 — Evaluación determinista y primera razón de rechazo

**Historia:** KANE3-40  
**Etapa:** 3 — Paradigma lógico  
**Lenguaje:** SWI-Prolog  
**Módulo principal:** `src/domain/evaluator.pl`  
**Rama:** `feature/KANE3-40`  
**Estado:** Implementado y verificado; commit e integración pendientes.

## 1. Objetivo

Evaluar una combinación concreta contra la política académica y entregar un único resultado. Si incumple una o más reglas, devolver exclusivamente la primera razón según la prioridad establecida. Si no incumple ninguna, devolver un resultado de aceptación.

El evaluador coordina las reglas existentes de KANE3-36, KANE3-37 y KANE3-38. No reemplaza su lógica ni genera combinaciones.

---

## 2. Interfaz pública y dependencias

```prolog
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
```

| Predicado | Modo previsto | Comportamiento |
|---|---|---|
| `primera_violacion(+Combinacion, -Razon)` | `semidet` | Cero soluciones si cumple; una solución si incumple. |
| `evaluar_combinacion(+Combinacion, -Resultado)` | `det` | Exactamente un resultado para cada entrada que satisface las precondiciones. |

El evaluador no importa los loaders, el módulo `combination_queries` ni módulos de escritura. No declara hechos dinámicos propios.

---

## 3. Datos, precondiciones y resultados

La representación de entrada corresponde a la establecida por KANE3-34:

```prolog
combinacion(Id, Cursos, CreditosTotales)
curso(Codigo, Grupo, Creditos, Carrera, Area)
```

Precondiciones:

- La combinación está completamente instanciada y ha sido validada previamente, incluyendo su total de créditos.
- La política académica ha sido cargada y validada mediante KANE3-35.
- Existe cobertura de porcentajes para las carreras presentes en la combinación.
- La política permanece estable durante una evaluación.
- Para el modo de salida indicado, `Razon` o `Resultado` es una variable libre.

| Resultado interno | Significado |
|---|---|
| `resultado(true, ninguna)` | No se encontró una violación. |
| `resultado(false, balance_carrera(Carrera))` | Primera violación de balance entre carreras. |
| `resultado(false, limite_area(Area))` | Primera violación del límite de cursos por área. |
| `resultado(false, incompatibilidad(CodigoA, CodigoB))` | Primer par incompatible. |

Los resultados son términos Prolog internos; no constituyen todavía el esquema JSON de salida. El evaluador no valida entradas ni captura excepciones de las reglas para convertirlas en aceptación o rechazo académico.

---

## 4. Primera violación y prioridad

Orden obligatorio:

1. `BALANCE_CARRERA` — KANE3-36.
2. `LIMITE_AREA` — KANE3-37.
3. `INCOMPATIBILIDAD` — KANE3-38.

Implementación real:

```prolog
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
```

El orden de cláusulas establece la prioridad. Cada regla conserva su propio orden de búsqueda de violaciones; el evaluador selecciona la primera solución que esa regla entrega.

### 4.1. Justificación del corte

Cada `!` descarta otras soluciones de la regla que tuvo éxito y las cláusulas posteriores de `primera_violacion/2`. No se acumulan razones ni se continúa evaluando reglas de menor prioridad después de encontrar una violación.

`RazonEncontrada` se mantiene libre durante la búsqueda y se unifica con `Razon` después del corte. Una razón de salida previamente ligada e incorrecta hace fallar la consulta, sin permitir que se busque otra violación que coincida con ella.

Ejemplo: si una combinación viola balance y área, consultar por `limite_area(computadores)` no permite omitir la violación de balance.

---

## 5. Evaluación completa y negación por falla

Implementación real:

```prolog
evaluar_combinacion(Combinacion, Resultado) :-
    primera_violacion(Combinacion, Razon),
    !,
    Resultado = resultado(false, Razon).

evaluar_combinacion(Combinacion, Resultado) :-
    \+ primera_violacion(Combinacion, _),
    Resultado = resultado(true, ninguna).
```

El corte de la primera cláusula compromete el rechazo y elimina la alternativa de aceptación. La unificación posterior evita que una salida ligada fuerce una decisión distinta.

La segunda cláusula utiliza negación por falla (`\+`) para expresar que no se puede demostrar ninguna violación. La variable anónima indica que no interesa una razón particular. Esta interpretación requiere las precondiciones de la sección 3; la ausencia de información no es una prueba de cumplimiento fuera de ellas. Las excepciones se propagan.

### 5.1. Determinismo y backtracking

Para una combinación válida y una salida libre, se obtiene exactamente un resultado. Con una salida previamente ligada incompatible con el resultado real, la consulta falla; ese uso no tiene la garantía `det` del modo principal.

Los cortes son locales a las invocaciones del evaluador y no eliminan los puntos de elección de un llamador que enumere combinaciones antes de evaluarlas. La conexión y verificación del recorrido global no se implementaron en esta historia.

### 5.2. Costo conocido

Para una combinación rechazada se realiza una llamada a `primera_violacion/2`. Para una aceptada se comprueba la ausencia de violaciones dos veces: una al fallar la primera cláusula y otra bajo negación por falla. Se conserva este diseño simple y explícito; no se realizó una optimización ni una medición de rendimiento.

---

## 6. Ejemplos y política configurable

Los ejemplos de esta sección usan únicamente los fixtures sintéticos, no la política académica de producción.

Con la política original de pruebas:

```prolog
max_porcentaje_carrera(computadores, 60).
max_porcentaje_carrera(matematica, 60).
max_cursos_area(1).
incompatible('TEST_A', 'TEST_B').
```

Una vez cargada la política y validada la entrada, la combinación:

```prolog
combinacion(1, [
    curso('TEST_A', 1, 3, computadores, computadores),
    curso('TEST_B', 1, 3, matematica, matematicas),
    curso('TEST_C', 1, 3, computadores, computadores)
], 9)
```

viola las tres reglas. `primera_violacion/2` devuelve `balance_carrera(computadores)` y `evaluar_combinacion/2` devuelve `resultado(false, balance_carrera(computadores))`.

La política alternativa eleva el porcentaje de computadores a 70 y el máximo por área a 2, sin modificar el par incompatible. Con los mismos cursos, la razón pasa a ser `incompatibilidad('TEST_A', 'TEST_B')`. Este cambio se verificó con los loaders y el evaluador reales.

La matriz de escenarios cubierta por las pruebas es:

| Balance | Área | Incompatibilidad | Razón final |
|---|---|---|---|
| Viola | Viola | Viola | Balance |
| Viola | Viola | Cumple | Balance |
| Viola | Cumple | Viola | Balance |
| Viola | Cumple | Cumple | Balance |
| Cumple | Viola | Viola | Área |
| Cumple | Viola | Cumple | Área |
| Cumple | Cumple | Viola | Incompatibilidad |
| Cumple | Cumple | Cumple | Ninguna |

Una combinación vacía cumple las tres reglas bajo una política válida. Los cursos de cero créditos pueden incumplir el límite por área aunque el balance se cumpla con cero créditos totales.

---

## 7. Archivos y pruebas

| Archivo | Cambio |
|---|---|
| `src/domain/evaluator.pl` | Implementación de los dos predicados públicos. |
| `tests/unit/evaluator_test.pl` | 19 pruebas unitarias y de integración ligera con reglas y loader. |
| `tests/fixtures/policy/politica_evaluador.pl` | Política sintética original. |
| `tests/fixtures/policy/politica_evaluador_alternativa.pl` | Política sintética alternativa. |

No se modificaron las reglas anteriores ni la política académica real.

### 7.1. Cobertura de pruebas del evaluador

| Pruebas | Cobertura |
|---|---|
| 1–4 | Tres escenarios obligatorios de prioridad y ausencia de violaciones. |
| 5–6 | Razones previamente ligadas. |
| 7–10 | Cuatro variantes del resultado interno. |
| 11–12 | Resultados previamente ligados. |
| 13–14 | Combinación vacía y cero créditos con violación de área. |
| 15 | Cambio de política y cambio de razón. |
| 16–19 | Escenarios restantes de la matriz, incluida área con créditos positivos. |

Se utiliza `findall/3` para verificar la lista completa de soluciones y `==` para comparar estrictamente el resultado esperado. En los escenarios principales se comprueban las reglas individuales antes de verificar la prioridad.

Ejecución desde la raíz del repositorio:

```powershell
swipl -q -s .\tests\unit\evaluator_test.pl -g run_tests -t halt
```

Resultado registrado: **19/19 pruebas correctas**.

### 7.2. Regresión general

| Suite | Resultado |
|---|---:|
| `area_limit_test.pl` | 11/11 |
| `career_balance_test.pl` | 9/9 |
| `combinations_loader_test.pl` | 25/25 |
| `combination_queries_test.pl` | 7/7 |
| `evaluator_test.pl` | 19/19 |
| `incompatibility_test.pl` | 12/12 |
| `module_loading_test.pl` | 4/4 |
| `policy_loader_test.pl` | 28/28 |
| **Total** | **115/115** |

Se verificaron las ocho suites en procesos independientes, todas con código de salida 0, y en un único proceso de SWI-Prolog, con 115/115 y código de salida 0. Los resultados corresponden a las ejecuciones realizadas en el repositorio local y compartidas para revisión.

```powershell
Get-ChildItem .\tests -Recurse -Filter "*_test.pl" | ForEach-Object {
    swipl -q -s $_.FullName -g run_tests -t halt
    if ($LASTEXITCODE -ne 0) { throw "ERROR en $($_.Name)" }
}
```

```powershell
swipl -q -g "load_files([
    'tests/unit/area_limit_test.pl',
    'tests/unit/career_balance_test.pl',
    'tests/unit/combination_queries_test.pl',
    'tests/unit/combinations_loader_test.pl',
    'tests/unit/evaluator_test.pl',
    'tests/unit/incompatibility_test.pl',
    'tests/unit/module_loading_test.pl',
    'tests/unit/policy_loader_test.pl'
], []), run_tests" -t halt
```

### 7.3. Aislamiento y mantenimiento de pruebas

Cada prueba del evaluador carga la política sintética original mediante `setup(preparar_politica)`. La prueba de política alternativa restaura ese fixture mediante `cleanup(preparar_politica)`. No se restaura el estado de política existente antes de la suite; por tanto, la suite no garantiza aislamiento completo frente a otras suites ejecutadas en cualquier orden. La regresión compartida no detectó interferencias en el orden comprobado.

Hay repetición deliberada de combinaciones en las pruebas: cada escenario conserva sus propios datos de entrada visibles. Una eventual extracción de helpers es una mejora de mantenimiento, no un requisito funcional.

---

## 8. Criterios de aceptación

| N.º | Criterio | Evidencia |
|---:|---|---|
| 1 | Orden balance → área → incompatibilidad | Orden de cláusulas; pruebas 1–3, 16–19. |
| 2 | Balance tiene prioridad si incumple | Prueba 1. |
| 3 | Área tiene prioridad si balance cumple | Prueba 2. |
| 4 | Incompatibilidad si las dos reglas anteriores cumplen | Prueba 3. |
| 5 | Existe `primera_violacion/2` | Interfaz y sección 4. |
| 6 | Corte justificado | Secciones 4.1 y 5; pruebas 5–6, 11–12. |
| 7 | Negación por falla justificada para cumplimiento | Sección 5; pruebas 8 y 13. |
| 8 | Resultado válido `resultado(true, ninguna)` | Pruebas 8 y 13. |
| 9 | Resultado inválido `resultado(false, Razon)` | Pruebas 7, 9 y 10. |
| 10 | Una única razón final | Comparaciones de listas de soluciones en las pruebas. |
| 11 | Prueba de violación de las tres reglas | Prueba 1. |
| 12 | Prueba de área e incompatibilidad | Prueba 2. |
| 13 | Prueba de incompatibilidad únicamente | Prueba 3. |

Los 13 criterios de KANE3-40 se consideran cubiertos por la implementación y las pruebas ejecutadas.

---

## 9. Diagnósticos conocidos

- La prueba `incompatibility:son_incompatibles_funciona_en_ambos_sentidos` conserva el warning preexistente `Test succeeded with choicepoint`. No se modificó KANE3-38; la prueba pasa.
- VS Code reporta tres warnings `Predicate evaluator:... not defined` para `viola_balance/2`, `viola_limite_area/2` y `viola_incompatibilidad/2`. Se verificó en SWI-Prolog que las tres importaciones están presentes:

```powershell
swipl -q -s .\src\domain\evaluator.pl -g "predicate_property(evaluator:viola_balance(_,_), imported_from(career_balance)), predicate_property(evaluator:viola_limite_area(_,_), imported_from(area_limit)), predicate_property(evaluator:viola_incompatibilidad(_,_), imported_from(incompatibility))" -t halt
```

El código de salida fue 0. La evidencia indica que son diagnósticos del analizador estático y no fallos de resolución de predicados en SWI-Prolog. No se alteraron las importaciones ni se declararon predicados dinámicos para silenciarlos.

---

## 10. Decisiones de alcance y pendientes

El contrato maestro sirve como guía arquitectónica evolutiva. El enunciado oficial, los criterios de aceptación, los contratos individuales y la implementación verificada establecen el alcance y el comportamiento real.

El Contrato KANE3-39, sección 9, había previsto que esta historia conectara `registrar_combinaciones/1`, el recorrido mediante `combinacion/3` y el uso funcional de `curso_en_combinacion/2`. Se conserva la independencia del evaluador individual para no introducir dependencias artificiales con el registro de combinaciones.

Se propone trasladar esa conexión a la historia correspondiente de evaluación global u orquestación. Su asignación concreta queda pendiente de confirmar con los criterios de las historias posteriores. El criterio 7 de KANE3-39 (uso en funcionalidad real del predicado multimodo) permanece pendiente; no se declara cumplido por esta entrega.

También quedan fuera de KANE3-40 el recorrido global, la recolección de resultados, su exportación JSON, la orquestación de `main.pl` y los valores definitivos de política académica que estén pendientes en historias anteriores.

Pendientes de cierre de esta historia: revisar el documento, preparar los cambios, verificar el diff preparado, realizar commit y push, e integrar en `integration/etapa3` sin fusionar en `main`.
