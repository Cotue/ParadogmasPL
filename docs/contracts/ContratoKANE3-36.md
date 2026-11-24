# Contrato KANE3-36 — Balance de créditos por carrera

**Historia:** KANE3-36  
**Etapa:** 3 — Paradigma lógico  
**Lenguaje:** SWI-Prolog  
**Módulo principal:** `src/rules/career_balance.pl`  
**Estado:** Implementado

## 1. Objetivo

Evaluar si una combinación de horario respeta el porcentaje máximo de créditos permitido para cada carrera de procedencia presente en la combinación.

La regla utiliza los créditos y la carrera almacenados en cada término:

```prolog
curso(Codigo, Grupo, Creditos, Carrera, Area)
```

y consulta los porcentajes máximos configurados mediante:

```prolog
politica:max_porcentaje_carrera(Carrera, MaxPorcentaje)
```

Esta historia implementa únicamente la regla de balance entre carreras.

No carga archivos, no modifica la política académica y no decide cuál es la primera regla global violada.

---

## 2. Dependencias

KANE3-36 depende de las estructuras producidas por KANE3-34:

```prolog
combinacion(
    Id,
    Cursos,
    CreditosTotales
)
```

y:

```prolog
curso(
    Codigo,
    Grupo,
    Creditos,
    Carrera,
    Area
)
```

La carrera utilizada para evaluar el balance corresponde directamente al cuarto argumento de `curso/5`.

La regla no:

- infiere la carrera a partir del código del curso;
- modifica la carrera;
- normaliza nombres;
- consulta datos externos diferentes de la política ya cargada.

KANE3-36 también depende de KANE3-35, que deja disponibles los porcentajes mediante:

```prolog
politica:max_porcentaje_carrera/2
```

La cobertura de carreras debe validarse previamente mediante:

```prolog
validar_cobertura_carreras/1
```

Por tanto, esta historia no duplica esa validación.

---

## 3. Interfaz pública

El módulo exporta:

```prolog
:- module(career_balance, [
    viola_balance/2,
    cumple_balance/1
]).
```

### `viola_balance/2`

Uso conceptual:

```prolog
viola_balance(+Combinacion, -Razon)
```

Una combinación viola la regla si alguna carrera supera el porcentaje máximo definido en la política.

La razón tiene la forma:

```prolog
balance_carrera(Carrera)
```

Ejemplo:

```prolog
viola_balance(
    Combinacion,
    balance_carrera(computadores)
).
```

### `cumple_balance/1`

Uso conceptual:

```prolog
cumple_balance(+Combinacion)
```

Es verdadero cuando no existe ninguna carrera que supere su porcentaje máximo.

Su definición utiliza negación por falla:

```prolog
cumple_balance(Combinacion) :-
    \+ viola_balance(
        Combinacion,
        _
    ).
```

---

## 4. Origen del porcentaje máximo

El porcentaje máximo no se encuentra hardcodeado dentro de `career_balance.pl`.

Para cada carrera se consulta:

```prolog
politica:max_porcentaje_carrera(
    Carrera,
    MaxPorcentaje
)
```

Los valores provienen del archivo de política cargado por KANE3-35.

El archivo actual contiene valores configurables como:

```prolog
max_porcentaje_carrera(computadores, 70).
max_porcentaje_carrera(matematica, 50).
max_porcentaje_carrera(fisica, 40).
max_porcentaje_carrera(quimica, 40).
```

Estos valores son datos externos a la regla y pueden modificarse sin cambiar `career_balance.pl`.

---

## 5. Semántica de la regla

Para cada carrera presente en una combinación se calcula:

```text
créditos de la carrera
---------------------- × 100
 créditos totales
```

Una carrera cumple si su porcentaje es menor o igual al máximo configurado.

Una carrera viola la regla si:

```text
porcentaje real > porcentaje máximo
```

El límite es inclusivo.

Ejemplo con:

```prolog
max_porcentaje_carrera(computadores, 70).
```

se obtiene:

```text
60%  → cumple
70%  → cumple
80%  → viola
```

Una combinación viola la regla si al menos una de sus carreras supera su máximo.

---

## 6. Agrupación de créditos por carrera

Los créditos se acumulan mediante:

```prolog
creditos_por_carrera/3
```

El predicado recorre todos los cursos de la combinación.

Para cursos cuya carrera coincide con la carrera consultada:

```prolog
curso(_, _, Creditos, Carrera, _)
```

sus créditos se suman.

Los cursos pertenecientes a otras carreras se ignoran para ese cálculo.

Ejemplo:

```prolog
[
    curso('CE1101', 1, 4, computadores, computadores),
    curso('CE1104', 2, 4, computadores, computadores),
    curso('MA1101', 1, 2, matematica, matematicas)
]
```

produce:

```text
computadores = 8 créditos
matematica   = 2 créditos
total        = 10 créditos
```

Por tanto:

```text
computadores = 80%
```

Si el máximo configurado es `70`, la combinación viola la regla con:

```prolog
balance_carrera(computadores)
```

---

## 7. Evaluación de todas las carreras

La regla utiliza:

```prolog
member(
    curso(_, _, _, Carrera, _),
    Cursos
)
```

para recorrer las carreras presentes en los cursos de la combinación.

Por esta razón, la evaluación no se limita al primer curso ni a la primera carrera encontrada.

Ejemplo:

```text
computadores = 40%  → máximo 70% → cumple
matematica   = 60%  → máximo 50% → viola
```

La combinación se considera inválida debido a:

```prolog
balance_carrera(matematica)
```

El predicado puede mantener puntos de elección debido al recorrido lógico de los cursos.

No se utiliza corte dentro de esta regla para impedir artificialmente el backtracking.

La selección de la primera regla global violada pertenece a la historia de evaluación posterior.

---

## 8. Comparación sin división

Para evitar cálculos innecesarios mediante división y reducir problemas asociados al punto flotante, la regla no calcula directamente:

```prolog
CreditosCarrera / CreditosTotales
```

En su lugar utiliza comparación por producto cruzado:

```prolog
CreditosCarrera * 100
>
CreditosTotales * MaxPorcentaje
```

Ejemplo:

```text
CreditosCarrera = 7
CreditosTotales = 10
MaxPorcentaje   = 70
```

se compara como:

```text
7 × 100 > 10 × 70
700 > 700
false
```

Por tanto, estar exactamente en el máximo es válido.

---

## 9. Porcentajes decimales

KANE3-35 permite porcentajes numéricos enteros o flotantes.

Por esta razón, la regla también funciona con valores como:

```prolog
max_porcentaje_carrera(computadores, 37.5).
```

Ejemplo:

```text
3 créditos de computadores
8 créditos totales

3 / 8 = 37.5%
```

La comparación utilizada es:

```text
3 × 100 > 8 × 37.5
300 > 300
false
```

Por tanto, exactamente `37.5%` cumple.

---

## 10. Combinaciones con una sola carrera

Una combinación con cursos de una sola carrera se evalúa mediante la misma regla.

No existe ninguna excepción especial por contener una única carrera.

Ejemplo:

```prolog
combinacion(
    4,
    [
        curso(
            'CE1101',
            1,
            10,
            computadores,
            computadores
        )
    ],
    10
)
```

representa:

```text
computadores = 100%
```

Con un máximo de:

```text
70%
```

la combinación viola:

```prolog
balance_carrera(computadores)
```

---

## 11. Caso de cero créditos

El caso:

```prolog
CreditosTotales = 0
```

se maneja explícitamente.

La regla establece que una combinación con cero créditos totales no viola el balance entre carreras.

Esto se representa mediante una cláusula específica:

```prolog
supera_porcentaje(
    _CreditosCarrera,
    0,
    _MaxPorcentaje
) :-
    fail.
```

No se intenta realizar una división entre cero.

KANE3-34 garantiza previamente que:

- los créditos individuales son enteros no negativos;
- la suma de los créditos individuales coincide con `CreditosTotales`.

Por tanto, si:

```text
CreditosTotales = 0
```

todos los créditos individuales también deben sumar `0`.

---

## 12. Separación de responsabilidades

`career_balance.pl` pertenece a:

```text
src/rules/
```

y contiene únicamente lógica de evaluación.

No realiza:

- lectura de archivos;
- escritura de archivos;
- carga de JSON;
- carga de política;
- impresión en consola;
- modificación de hechos;
- `assert/1`;
- `assertz/1`;
- `retract/1`;
- `retractall/1`;
- almacenamiento de resultados intermedios.

Los hechos de política son cargados previamente por KANE3-35.

La regla únicamente los consulta.

---

## 13. Flujo esperado

El flujo conceptual previo a ejecutar esta regla es:

```text
cargar_combinaciones/2
        ↓
cargar_politica/1
        ↓
validar_cobertura_carreras/1
        ↓
viola_balance/2
        o
cumple_balance/1
```

KANE3-36 presupone que la política y las combinaciones ya fueron validadas.

No repite validaciones correspondientes a las capas anteriores.

---

## 14. Pruebas

Las pruebas unitarias se encuentran en:

```text
tests/unit/career_balance_test.pl
```

Se utilizan políticas cargadas mediante la interfaz real proporcionada por KANE3-35.

Las pruebas cubren:

### Debajo del máximo

```text
computadores = 60%
máximo       = 70%
resultado    = cumple
```

### Exactamente en el máximo

```text
computadores = 70%
máximo       = 70%
resultado    = cumple
```

### Encima del máximo

```text
computadores = 80%
máximo       = 70%
resultado    = balance_carrera(computadores)
```

### Una sola carrera

```text
computadores = 100%
máximo       = 70%
resultado    = balance_carrera(computadores)
```

### Varias carreras

```text
computadores = 40% <= 70%
matematica   = 60% > 50%
```

Resultado:

```prolog
balance_carrera(matematica)
```

### Cero créditos

```text
CreditosTotales = 0
resultado        = cumple
```

### Agrupación de créditos

Dos cursos de `computadores`:

```text
4 + 4 = 8 créditos
```

sobre un total de:

```text
10
```

producen:

```text
80%
```

y violan un máximo del `70%`.

### Política configurable

Se carga durante la prueba una política alternativa:

```prolog
max_porcentaje_carrera(computadores, 50).
```

Una combinación con:

```text
60% computadores
```

pasa de cumplir con máximo `70` a violar con máximo `50`.

Esto comprueba que la regla consulta realmente los hechos de política y no contiene valores hardcodeados.

### Porcentaje decimal

Se prueba:

```prolog
max_porcentaje_carrera(computadores, 37.5).
```

con:

```text
3 / 8 = 37.5%
```

y la combinación cumple exactamente en el límite.

---

## 15. Resultado de pruebas

Al cierre de la historia:

```text
career_balance
9 / 9 pruebas pasan correctamente
```

La suite puede ejecutarse mediante:

```powershell
swipl -q -s .\tests\unit\career_balance_test.pl -g run_tests -t halt
```

Las regresiones correspondientes pueden ejecutarse mediante:

```powershell
swipl -q -s .\tests\unit\policy_loader_test.pl -g run_tests -t halt

swipl -q -s .\tests\unit\combinations_loader_test.pl -g run_tests -t halt

swipl -q -s .\tests\unit\module_loading_test.pl -g run_tests -t halt
```

Todas deben finalizar con código de salida:

```text
0
```

---

## 16. Responsabilidades que no pertenecen a KANE3-36

Esta historia no implementa:

- límite por área;
- incompatibilidades;
- selección de la primera regla global violada;
- corte para elegir la primera razón;
- recorrido global de todas las combinaciones;
- exportación de resultados;
- escritura del archivo consumido por Java;
- carga de combinaciones;
- carga de política;
- validación de cobertura de carreras.

Estas responsabilidades pertenecen a otras historias.

---

## 17. Criterios de aceptación verificados

1. La regla utiliza `Carrera` de `curso/5`.
2. Los créditos se agrupan por carrera.
3. Se evalúan todas las carreras presentes.
4. El máximo se obtiene desde `max_porcentaje_carrera/2`.
5. No se utilizan porcentajes hardcodeados.
6. El límite es inclusivo.
7. Estar exactamente en el porcentaje máximo es válido.
8. Superar el porcentaje produce una violación.
9. La violación identifica la carrera responsable mediante `balance_carrera(Carrera)`.
10. La comparación evita divisiones y problemas innecesarios de punto flotante.
11. Una combinación con cursos de una sola carrera se evalúa mediante la misma regla.
12. Una combinación con cero créditos totales se maneja explícitamente.
13. El predicado no realiza I/O.
14. El predicado no utiliza estado global.
15. Existen pruebas para:
    - debajo del máximo;
    - exactamente en el máximo;
    - encima del máximo;
    - una sola carrera;
    - varias carreras;
    - cero créditos.

Además se probaron:

- agrupación de varios cursos de una misma carrera;
- política configurable;
- porcentaje decimal.

---

## 18. Resultado

KANE3-36 deja implementada la primera regla académica de la Etapa 3:

```text
BALANCE_CARRERA
```

La regla puede determinar si una combinación respeta los porcentajes configurados para todas las carreras presentes y, cuando existe una violación, identificar la carrera responsable mediante:

```prolog
balance_carrera(Carrera)
```

sin realizar I/O, sin modificar estado global y sin contener parámetros académicos hardcodeados.