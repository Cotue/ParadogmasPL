# Contrato KANE3-37 — Límite de cursos por área

**Historia:** KANE3-37  
**Etapa:** 3 — Paradigma lógico  
**Lenguaje:** SWI-Prolog  
**Módulo principal:** `src/rules/area_limit.pl`  
**Estado:** Implementado

## 1. Objetivo

Verificar que una combinación no tenga más cursos de una misma área que el
máximo definido en la política académica.

Esta historia implementa solo la regla `LIMITE_AREA`. No elige la primera regla
violada ni escribe resultados.

---

## 2. Interfaz pública

```prolog
:- module(area_limit, [
    viola_limite_area/2,
    viola_limite_area/3,
    cumple_limite_area/1
]).
```

| Predicado | Uso |
|---|---|
| `viola_limite_area(+Combinacion, -Razon)` | Toma el máximo de la política y busca áreas que lo superen. |
| `viola_limite_area(+Combinacion, -Razon, +Max)` | Igual, pero con el máximo como argumento. Sirve para probar distintos valores sin tocar la política. |
| `cumple_limite_area(+Combinacion)` | Verdadero si ninguna área supera el máximo. |

`Combinacion` tiene la forma `combinacion(Id, Cursos, CreditosTotales)` y cada
curso es `curso(Codigo, Grupo, Creditos, Carrera, Area)`, tal como los produce
`cargar_combinaciones/2` (KANE3-34).

`Razon` es:

```prolog
limite_area(Area)
```

---

## 3. Origen del máximo

El máximo se consulta en el módulo cargado por KANE3-35:

```prolog
politica:max_cursos_area(N)
```

No está escrito en la regla, así que se puede cambiar editando
`data/policy/politica.pl`.

La regla no valida `N`. Que sea entero no negativo y único lo garantiza
`policy_loader`.

Si no hay ningún `max_cursos_area/1` cargado, `viola_limite_area/2` lanza:

```prolog
error(e3_policy(max_cursos_area_faltante), context(viola_limite_area/2, _))
```

Así una política faltante nunca se toma como "cumple".

---

## 4. Semántica de la regla

Para cada área presente en la combinación:

```text
cantidad de cursos del área <= N   → cumple
cantidad de cursos del área >  N   → viola
```

- Se cuentan **cursos**, no créditos.
- El **grupo** no influye en el conteo.
- Un curso de **0 créditos** cuenta como un curso.
- Estar **exactamente en N** es válido.
- Una combinación **vacía** cumple.

Ejemplo con `max_cursos_area(2)`:

```prolog
combinacion(1, [
    curso('FI1101', 1, 3, fisica, ciencias_naturales),
    curso('QU1106', 2, 3, quimica, ciencias_naturales),
    curso('FI1102', 1, 3, fisica, ciencias_naturales)
], 9)
```

`ciencias_naturales` tiene 3 cursos; como 3 > 2, la razón es
`limite_area(ciencias_naturales)`.

---

## 5. Varias áreas en violación

Si más de un área supera el máximo, `viola_limite_area` devuelve una razón por
cada área mediante backtracking, **en el orden en que cada área aparece por
primera vez en la combinación**.

```prolog
?- viola_limite_area(C, R, 1).
R = limite_area(matematicas) ;
R = limite_area(computadores).
```

El evaluador (KANE3-40) toma la primera solución. Este orden hace que la razón
reportada sea siempre la misma para una misma entrada.

---

## 6. Uso del paradigma lógico

- **Backtracking:** `member/2` recorre las áreas distintas y genera una
  solución por cada área en violación.
- **Negación por falla:** `cumple_limite_area(C) :- \+ viola_limite_area(C, _).`
- **Recursión:** las áreas distintas y el conteo se calculan recorriendo la
  lista de cursos, sin `assert/retract`.

---

## 7. Restricciones

El módulo:

- no realiza I/O;
- no imprime ni termina el programa;
- no usa `assert/retract` ni estado global;
- no tiene valores hardcodeados;
- no infiere ni corrige áreas.

---

## 8. Pruebas

Archivo: `tests/unit/area_limit_test.pl`

| Caso | Resultado esperado |
|---|---|
| Menos de N cursos | No viola |
| Exactamente N cursos | No viola |
| N + 1 cursos | `limite_area(computadores)` |
| Varias áreas, una se pasa | Solo esa área |
| Dos áreas se pasan | Primero la que aparece primero; `findall` devuelve ambas |
| Cursos de 0 créditos | Cuentan como cursos |
| Cursos con distinto grupo | Cuentan igual |
| Combinación vacía | Cumple |
| `/2` con política cargada | Usa `politica:max_cursos_area` |
| `/2` sin política | Lanza `e3_policy(max_cursos_area_faltante)` |
| `cumple_limite_area/1` | Verdadero y falso |

Ejecución:

```powershell
swipl -q -s .\tests\unit\area_limit_test.pl -g run_tests -t halt
```

Regresión:

```powershell
swipl -q -s .\tests\unit\policy_loader_test.pl -g run_tests -t halt
swipl -q -s .\tests\unit\combinations_loader_test.pl -g run_tests -t halt
swipl -q -s .\tests\unit\module_loading_test.pl -g run_tests -t halt
```

Todos terminan con código de salida 0.

---

## 9. Criterios de aceptación verificados

1. La regla usa `Area` de `curso/5`.
2. El máximo se obtiene de `max_cursos_area/1` (módulo `politica`).
3. Se cuentan cursos, no créditos.
4. Los grupos no afectan el conteo.
5. Estar exactamente en el máximo es válido.
6. Superar el máximo produce una violación.
7. La violación identifica el área: `limite_area(Area)`.
8. Funciona con varias áreas en una combinación.
9. Un curso de cero créditos cuenta como un curso.
10. El predicado no realiza I/O.
11. El predicado no usa estado global.
12. Existen pruebas para menos de N, exactamente N, N + 1 y múltiples áreas.

---

## 10. Pendientes del equipo

- Definir el valor real de `max_cursos_area/1` en `data/policy/politica.pl`.
- Integrar la regla en `evaluator.pl` como segunda regla (KANE3-40).
