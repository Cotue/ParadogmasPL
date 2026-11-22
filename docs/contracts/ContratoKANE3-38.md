# Contrato KANE3-38 — Incompatibilidades entre cursos

**Historia:** KANE3-38  
**Etapa:** 3 — Paradigma lógico  
**Lenguaje:** SWI-Prolog  
**Módulo principal:** `src/rules/incompatibility.pl`  
**Estado:** Implementado

## 1. Objetivo

Verificar que una combinación no contenga al mismo tiempo dos cursos declarados
incompatibles en la política académica.

Esta historia implementa solo la regla `INCOMPATIBILIDAD`. No elige la primera
regla violada ni escribe resultados.

---

## 2. Interfaz pública

```prolog
:- module(incompatibility, [
    son_incompatibles/2,
    viola_incompatibilidad/2,
    cumple_incompatibilidad/1
]).
```

| Predicado | Uso |
|---|---|
| `son_incompatibles(?A, ?B)` | Verdadero si A y B son incompatibles, en cualquier sentido. |
| `viola_incompatibilidad(+Combinacion, -Razon)` | Busca pares incompatibles dentro de la combinación. |
| `cumple_incompatibilidad(+Combinacion)` | Verdadero si la combinación no tiene ningún par incompatible. |

`Combinacion` tiene la forma `combinacion(Id, Cursos, CreditosTotales)` y cada
curso es `curso(Codigo, Grupo, Creditos, Carrera, Area)` (KANE3-34).

`Razon` es:

```prolog
incompatibilidad(CursoA, CursoB)
```

---

## 3. Origen de los pares

Los pares se consultan en el módulo cargado por KANE3-35:

```prolog
politica:incompatible(A, B)
```

No hay pares escritos en la regla, así que se pueden cambiar editando
`data/policy/politica.pl`.

Cada par se declara una sola vez. `policy_loader` rechaza pares repetidos,
pares invertidos y cursos incompatibles consigo mismos.

Una política sin pares es válida: en ese caso ninguna combinación viola esta
regla.

---

## 4. Simetría

La relación es simétrica. Declarar:

```prolog
incompatible('A', 'B').
```

hace que `A-B` y `B-A` sean la misma incompatibilidad.

La simetría se resuelve en un solo lugar:

```prolog
son_incompatibles(A, B) :- politica:incompatible(A, B).
son_incompatibles(A, B) :- politica:incompatible(B, A).
```

El resto del módulo usa `son_incompatibles/2` y no repite la comprobación de
los dos sentidos.

---

## 5. Semántica de la regla

Una combinación viola la regla si contiene dos cursos A y B tales que
`son_incompatibles(A, B)`.

- Contener solo A o solo B **no** viola la regla.
- El **grupo** seleccionado no influye: solo importa el código del curso.
- Una combinación **vacía** cumple.

### 5.1 Orden de la razón

En `incompatibilidad(A, B)`, **A es el curso que aparece primero en la
combinación**, sin importar en qué orden se declaró el par en la política.

Ejemplo: con `incompatible('B', 'A')` y una combinación donde `'A'` aparece
antes que `'B'`, la razón es `incompatibilidad('A', 'B')`.

### 5.2 Varios pares violados

Si hay varios pares incompatibles en la misma combinación, salen uno por uno
mediante backtracking, ordenados primero por la posición de A y luego por la de
B. Cada par se reporta una sola vez.

El evaluador (KANE3-40) toma la primera solución, por lo que la razón reportada
es siempre la misma para una misma entrada.

---

## 6. Uso del paradigma lógico

- **Backtracking:** `par_ordenado/3` genera los pares de cursos (A antes que B)
  y `member/2` recorre los posibles B.
- **Varias cláusulas:** `son_incompatibles/2` expresa la simetría con dos
  cláusulas en vez de condiciones.
- **Negación por falla:** `cumple_incompatibilidad(C) :- \+ viola_incompatibilidad(C, _).`

---

## 7. Restricciones

El módulo:

- no realiza I/O;
- no imprime ni termina el programa;
- no usa `assert/retract` ni estado global;
- no tiene pares hardcodeados.

---

## 8. Datos oficiales

Los pares incompatibles reales se declaran en `data/policy/politica.pl`, con su
justificación en el README.

| Par | Justificación |
|---|---|
| *Pendiente* | *Pendiente* |
| *Pendiente* | *Pendiente* |

---

## 9. Pruebas

Archivo: `tests/unit/incompatibility_test.pl`

| Caso | Resultado esperado |
|---|---|
| `son_incompatibles/2` en ambos sentidos | Verdadero |
| Ningún curso del par | Cumple |
| Solo A | Cumple |
| Solo B | Cumple |
| A y B presentes | `incompatibilidad(A, B)` |
| Par declarado invertido | Razón en orden de la combinación |
| A y B con grupos distintos | Viola igual |
| Dos pares violados | Primero el que aparece primero; `findall` devuelve ambos |
| Varios pares declarados, uno presente | Solo ese par |
| Sin pares cargados | Cumple |
| Combinación vacía | Cumple |
| `cumple_incompatibilidad/1` | Verdadero y falso |

Ejecución:

```powershell
swipl -q -s .\tests\unit\incompatibility_test.pl -g run_tests -t halt
```

Regresión:

```powershell
swipl -q -s .\tests\unit\area_limit_test.pl -g run_tests -t halt
swipl -q -s .\tests\unit\policy_loader_test.pl -g run_tests -t halt
swipl -q -s .\tests\unit\combinations_loader_test.pl -g run_tests -t halt
swipl -q -s .\tests\unit\module_loading_test.pl -g run_tests -t halt
```

Todos terminan con código de salida 0.

---

## 10. Criterios de aceptación

1. Los pares se obtienen mediante `incompatible/2` (módulo `politica`).
2. Un par se almacena una sola vez.
3. La relación se interpreta de forma simétrica.
4. `A-B` y `B-A` representan la misma incompatibilidad.
5. Una combinación con solo A no viola la regla.
6. Una combinación con solo B no viola la regla.
7. Una combinación con A y B viola la regla.
8. El grupo seleccionado no modifica la incompatibilidad.
9. La violación identifica ambos cursos: `incompatibilidad(A, B)`.
10. Los datos oficiales incluyen al menos dos pares incompatibles. **Pendiente (sección 8).**
11. La lógica de ambos sentidos está solo en `son_incompatibles/2`.
12. Existen pruebas de simetría y de múltiples pares.

---

## 11. Pendientes del equipo

- Elegir los dos pares reales y completar la sección 8 y `politica.pl`.
- Integrar la regla en `evaluator.pl` como tercera regla (KANE3-40).
