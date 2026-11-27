# Contrato KANE3-41 — Recorrido de todas las combinaciones mediante backtracking

**Historia:** KANE3-41  
**Etapa:** 3 — Paradigma lógico  
**Lenguaje:** SWI-Prolog  
**Módulo principal:** `src/domain/evaluator.pl`  
**Estado:** Implementado

## 1. Objetivo

Recorrer todas las combinaciones cargadas mediante backtracking y producir exactamente un resultado por combinación.

Esta historia conecta el registro de combinaciones como hechos (KANE3-39) con el evaluador individual (KANE3-40).

No genera, filtra, reordena ni modifica combinaciones, y no escribe resultados.

---

## 2. Interfaz pública

El módulo `evaluator` exporta, además de lo definido en KANE3-40:

```prolog
evaluacion/2
evaluar_todas/1
```

Uso conceptual:

```prolog
evaluacion(?Id, -Evaluado)
evaluar_todas(-Evaluados)
```

Donde:

- `Id` es el identificador secuencial asignado por `cargar_combinaciones/2`.
- `Evaluado` tiene la forma `evaluado(combinacion(Id, Cursos, CreditosTotales), Resultado)`.
- `Evaluados` es la lista de todos los `evaluado/2`, en orden de `Id`.

`Resultado` es el término interno de KANE3-40:

```prolog
resultado(true, ninguna)
resultado(false, Razon)
```

Predicado privado:

```prolog
evaluar_una(+Combinacion, -Resultado)
```

Ejemplo:

```prolog
?- evaluar_todas(Evaluados).
```

---

## 3. Origen de las combinaciones

Las combinaciones se consultan como hechos:

```prolog
combination_queries:combinacion(Id, Cursos, CreditosTotales)
```

Se reutiliza `registrar_combinaciones/1` de KANE3-39. No se creó otro mecanismo de registro.

`evaluator.pl` importa `combinacion/3` desde `combination_queries.pl`.

Con esto, `evaluator.pl` pasa a depender de `combination_queries.pl`. `primera_violacion/2` y `evaluar_combinacion/2` siguen sin consultar los hechos: la dependencia solo la usa el recorrido.

Flujo esperado:

```text
cargar_combinaciones/2
    ↓
cargar_politica/1
    ↓
validar_cobertura_carreras/1
    ↓
registrar_combinaciones/1
    ↓
evaluar_todas/1
```

---

## 4. Uso permitido de hechos dinámicos

`assertz/1` solo aparece en `registrar_combinaciones/1` (KANE3-39) y su único propósito es cargar las combinaciones de entrada, como permite la sección 46 del contrato maestro.

KANE3-41 no usa `assert`, `retract`, `nb_setval` ni contadores.

Los resultados se construyen mediante:

```text
argumentos
unificación
backtracking
findall/3
```

---

## 5. Recorrido mediante backtracking

```prolog
evaluacion(Id, evaluado(Combinacion, Resultado)) :-
    combinacion(Id, Cursos, CreditosTotales),
    Combinacion = combinacion(Id, Cursos, CreditosTotales),
    evaluar_una(Combinacion, Resultado).
```

- Con `Id` libre, `combinacion/3` entrega una solución por hecho y `evaluacion/2` enumera todas las combinaciones.
- Con `Id` ligado, devuelve solo esa combinación.
- Con un `Id` inexistente, falla.

El orden es el de registro. `registrar_combinaciones/1` usa `assertz/1` en el orden de la lista y `cargar_combinaciones/2` asigna los `Id` en ese mismo orden, así que el recorrido queda en orden de `Id`.

---

## 6. Recolección

```prolog
evaluar_todas(Evaluados) :-
    findall(Evaluado, evaluacion(_Id, Evaluado), Evaluados).
```

`findall/3` recoge todas las soluciones del recorrido en una lista. Sin hechos, devuelve `[]`.

---

## 7. Exactamente un resultado por combinación

`findall/3` agrega un elemento por cada éxito del objetivo. Por tanto:

- si una evaluación tuviera dos soluciones, la combinación saldría duplicada;
- si una evaluación fallara, la combinación desaparecería.

`evaluar_una/2` lo impide:

```prolog
evaluar_una(Combinacion, Resultado) :-
    (   evaluar_combinacion(Combinacion, ResultadoEncontrado)
    ->  Resultado = ResultadoEncontrado
    ;   Combinacion = combinacion(Id, _, _),
        throw(error(e3_evaluacion(sin_resultado(Id)),
                    context(evaluar_una/2, _)))
    ).
```

- El if-then-else toma solo la primera solución: nunca hay duplicados.
- La ausencia de solución lanza un error: nunca se pierde una combinación en silencio.

Invariante (contrato maestro §50 y §67):

```text
cantidadCombinacionesEntrada = cantidadResultadosSalida
```

---

## 8. Error `e3_evaluacion`

```prolog
error(
    e3_evaluacion(sin_resultado(Id)),
    context(evaluar_una/2, Mensaje)
)
```

Es una salvaguarda defensiva. Con las precondiciones de KANE3-40, `evaluar_combinacion/2` con salida libre siempre tiene éxito: su segunda cláusula es la negación exacta de la condición de la primera. Ni una carrera sin porcentaje ni una estructura inesperada la hacen fallar; solo cambian la razón o producen aceptación.

Por eso este error no puede provocarse en una prueba sin modificar las reglas o el evaluador, y la prueba correspondiente se omitió.

Las excepciones de las reglas (por ejemplo `e3_policy(max_cursos_area_faltante)`) no se capturan: se propagan sin alterar.

---

## 9. Responsabilidades que no pertenecen a KANE3-41

Esta historia no implementa:

- generación, eliminación o reordenamiento de combinaciones;
- cambios a cursos o grupos;
- filtrado por créditos;
- revalidación del schema;
- reglas académicas;
- escritura del JSON para Java;
- orquestación de `main.pl`;
- presentación de errores al usuario.

---

## 10. Pruebas

Las pruebas unitarias se encuentran en:

```text
tests/unit/evaluation_traversal_test.pl
```

Fixture nuevo:

```text
tests/fixtures/policy/politica_recorrido.pl
```

Casos cubiertos (11 pruebas):

- entrada vacía produce `[]`;
- tres combinaciones producen tres resultados (cumple, balance, incompatibilidad);
- las combinaciones de salida son `==` a las de entrada;
- backtracking enumera `[1, 2, 3]`;
- `Id` ligado devuelve solo esa combinación;
- `Id` inexistente falla;
- exactamente un resultado por `Id`;
- una combinación de 40 créditos no se filtra;
- la recarga reemplaza las combinaciones anteriores;
- una excepción de una regla se propaga;
- integración con el JSON real (83 combinaciones) y `data/policy/politica.pl`.

Al cierre de la historia:

```text
11 / 11 pruebas pasan correctamente
```

---

## 11. Ejecución de pruebas

Desde la raíz del repositorio:

```powershell
swipl -q -s .\tests\unit\evaluation_traversal_test.pl -g run_tests -t halt
```

Regresión:

```powershell
Get-ChildItem .\tests -Recurse -Filter "*_test.pl" | ForEach-Object {
    swipl -q -s $_.FullName -g run_tests -t halt
    if ($LASTEXITCODE -ne 0) { throw "ERROR en $($_.Name)" }
}
```

Resultados verificados de la regresión completa:

```text
area_limit             11 / 11
career_balance          9 / 9
combinations_loader    25 / 25
combination_queries     7 / 7
evaluation_traversal   11 / 11
evaluator              19 / 19
incompatibility        12 / 12
module_loading          4 / 4
policy_loader          28 / 28
```

Una ejecución correcta debe terminar con código de salida:

```text
0
```

---

## 12. Criterios de aceptación

1. Todas las combinaciones se recorren mediante backtracking.
2. `evaluacion/2` enumera en orden de `Id`.
3. Con `Id` ligado se obtiene solo esa combinación.
4. `evaluar_todas/1` usa `findall/3`.
5. Entrada vacía produce una lista vacía sin error.
6. N combinaciones de entrada producen N resultados.
7. Las combinaciones rechazadas se conservan con `resultado(false, _)`.
8. Las combinaciones no se modifican.
9. No se filtra por créditos.
10. No se usa estado global para resultados.
11. `evaluator.pl` no realiza I/O.
12. Las reglas, `policy_loader` y `main.pl` no se modificaron.

---

## 13. Pendientes

- Criterio 7 de KANE3-39: `curso_en_combinacion/2` todavía no se usa en funcionalidad real.
- Escritura JSON (`result_writer.pl`) y orquestación (`main.pl`).

---

## 14. Resultado

KANE3-41 deja disponible el recorrido completo:

```prolog
evaluar_todas(Evaluados)
```

con una evaluación por combinación, en orden de `Id`, sin estado global y sin alterar la entrada.
