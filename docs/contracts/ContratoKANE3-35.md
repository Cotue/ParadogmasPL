# Contrato KANE3-35 — Carga y validación de la política académica

**Historia:** KANE3-35  
**Etapa:** 3 — Paradigma lógico  
**Lenguaje:** SWI-Prolog  
**Módulo principal:** `src/io/policy_loader.pl`  
**Estado:** Implementado

## 1. Objetivo

Cargar desde un archivo externo los parámetros de la política académica, validar su consistencia y dejarlos disponibles como hechos para las reglas de evaluación.

Esta historia permite modificar las restricciones (porcentajes, máximo por área e incompatibilidades) sin cambiar el código de las reglas.

No evalúa combinaciones ni aplica reglas académicas.

---

## 2. Interfaz pública

El módulo exporta:

```prolog
cargar_politica/1
validar_politica/1
validar_cobertura_carreras/1
```

Uso conceptual:

```prolog
cargar_politica(+RutaArchivo)
validar_politica(+ListaDeTerminos)
validar_cobertura_carreras(+Combinaciones)
```

Donde:

- `RutaArchivo` es la ruta del archivo de política.
- `ListaDeTerminos` es una lista de términos de política ya leídos.
- `Combinaciones` es la lista de términos `combinacion/3` producida por `cargar_combinaciones/2`.

Ejemplo:

```prolog
?- cargar_politica('data/policy/politica.pl').
```

---

## 3. Archivo de política

La política se almacena en:

```text
data/policy/politica.pl
```

El archivo contiene **únicamente hechos**. No se permiten reglas ni directivas.

Hechos soportados:

```prolog
max_porcentaje_carrera(Carrera, Porcentaje).
max_cursos_area(N).
incompatible(CursoA, CursoB).
```

Ejemplo:

```prolog
max_porcentaje_carrera(computadores, 70).
max_porcentaje_carrera(matematica, 50).
max_porcentaje_carrera(fisica, 40).
max_porcentaje_carrera(quimica, 40).

max_cursos_area(3).

incompatible('CURSO_A', 'CURSO_B').
```

Los valores actuales son provisionales y serán definidos por el equipo a partir de los planes reales.

Los códigos de curso deben escribirse entre comillas simples (`'CE1101'`), porque sin comillas Prolog los interpreta como variables.

---

## 4. Ubicación de los hechos cargados

Los hechos validados se cargan en el módulo:

```text
politica
```

Declaraciones:

```prolog
:- dynamic politica:max_porcentaje_carrera/2.
:- dynamic politica:max_cursos_area/1.
:- dynamic politica:incompatible/2.
```

Los módulos de reglas consultan la política mediante calificación explícita:

```prolog
politica:max_porcentaje_carrera(Carrera, Max)   % KANE3-36
politica:max_cursos_area(N)                     % KANE3-37
politica:incompatible(A, B)                     % KANE3-38
```

Esto evita que las reglas dependan de un módulo de I/O y que contengan valores hardcodeados.

---

## 5. Lectura del archivo

El archivo se lee término por término mediante:

```prolog
open/4
read_term/3
setup_call_cleanup/3
```

con codificación `utf8`.

No se utiliza `consult/1`.

Razón:

```text
consult/1 ejecuta cualquier directiva presente en el archivo
y modifica la base de conocimiento antes de validar.
```

Con `read_term/3`, una directiva como:

```prolog
:- initialization(...).
```

se lee como un término normal y se rechaza durante la validación.

Flujo:

```text
Archivo politica.pl
    ↓
read_term/3
    ↓
lista de términos
    ↓
validar_politica/1
    ↓
retractall/1 + assertz/1
    ↓
módulo politica
```

---

## 6. Validar antes de cargar

`cargar_politica/1` sigue tres pasos:

1. Leer todos los términos del archivo a una lista.
2. Validar la lista completa con `validar_politica/1`.
3. Solo si la validación tiene éxito:
   - eliminar los hechos anteriores con `retractall/1`;
   - insertar los nuevos con `assertz/1`.

Consecuencias:

- una política inválida no deja hechos parciales cargados;
- una política inválida no borra una política válida cargada previamente;
- volver a cargar una política reemplaza completamente los valores anteriores.

`validar_politica/1` es un predicado puro: recorre la lista recursivamente con acumuladores y no utiliza `assert/retract`.

---

## 7. Uso permitido de hechos dinámicos

El enunciado permite `assert/retract` únicamente para cargar datos de entrada.

La política es un dato de entrada del programa.

Por tanto, `assertz/1` se utiliza solamente en el paso final de carga.

No se utiliza para almacenar:

```text
resultados
contadores
violaciones
estados intermedios
```

---

## 8. Validaciones de la política

### 8.1 Porcentaje por carrera

```prolog
max_porcentaje_carrera(Carrera, Porcentaje)
```

- `Carrera` debe ser un átomo.
- `Porcentaje` debe ser numérico (entero o flotante).
- `Porcentaje` debe estar en el rango cerrado `[0, 100]`.

No es obligatorio que la suma de los porcentajes sea 100.

Cada porcentaje representa un máximo independiente.

### 8.2 Porcentajes repetidos

Si una carrera aparece dos veces con **el mismo valor**, se acepta y se carga una sola vez.

```prolog
max_porcentaje_carrera(fisica, 37.5).
max_porcentaje_carrera(fisica, 37.5).
```

Si aparece con **valores distintos**, la política es inválida:

```prolog
max_porcentaje_carrera(matematica, 50).
max_porcentaje_carrera(matematica, 60).
```

La comparación es aritmética, por lo que `40` y `40.0` se consideran el mismo valor.

### 8.3 Máximo de cursos por área

```prolog
max_cursos_area(N)
```

- Debe existir exactamente un hecho.
- `N` debe ser un entero mayor o igual que cero.

### 8.4 Incompatibilidades

```prolog
incompatible(CursoA, CursoB)
```

- Ambos códigos deben ser átomos.
- Un curso no puede ser incompatible consigo mismo.
- Cada par se declara en un solo sentido.

Son inválidos:

```prolog
incompatible('A', 'B').
incompatible('A', 'B').
```

y:

```prolog
incompatible('A', 'B').
incompatible('B', 'A').
```

La simetría de la relación es responsabilidad de KANE3-38 (`son_incompatibles/2`).

Una política sin pares incompatibles es estructuralmente válida.

### 8.5 Términos desconocidos

Cualquier término distinto de los tres hechos soportados es inválido, incluyendo reglas y directivas.

### 8.6 Política incompleta

Una política sin `max_cursos_area/1` o sin ningún `max_porcentaje_carrera/2` es inválida.

Si faltan ambos (por ejemplo, un archivo vacío), se reporta primero:

```text
max_cursos_area_faltante
```

---

## 9. Cobertura de carreras

`validar_cobertura_carreras/1` verifica que toda carrera presente en las combinaciones tenga un porcentaje definido.

Para cada:

```prolog
curso(_, _, _, Carrera, _)
```

debe existir:

```prolog
politica:max_porcentaje_carrera(Carrera, _)
```

Esta validación se separa de `cargar_politica/1` porque requiere las combinaciones ya cargadas.

Orden de uso esperado:

```text
cargar_combinaciones/2
    ↓
cargar_politica/1
    ↓
validar_cobertura_carreras/1
    ↓
evaluación de reglas
```

Una lista vacía de combinaciones es válida.

---

## 10. Errores de política

KANE3-35 utiliza la categoría:

```prolog
e3_policy(...)
```

Todos los errores tienen la forma:

```prolog
error(
    e3_policy(Detalle),
    context(Origen, Mensaje)
)
```

| Detalle | Condición |
|---|---|
| `archivo_inexistente(Ruta)` | El archivo de política no existe. |
| `sintaxis(Detalle)` | Error al leer el archivo con `read_term/3`. |
| `hecho_desconocido(T)` | Término no soportado, incluidas reglas y directivas. |
| `carrera_invalida(C)` | La carrera no es un átomo. |
| `porcentaje_invalido(C, P)` | `P` no es numérico o está fuera de `[0, 100]`. |
| `porcentajes_contradictorios(C, P1, P2)` | La misma carrera tiene dos valores distintos. |
| `max_cursos_area_faltante` | No existe `max_cursos_area/1`. |
| `max_cursos_area_duplicado` | Existe más de un `max_cursos_area/1`. |
| `max_cursos_area_invalido(N)` | `N` no es entero o es negativo. |
| `curso_invalido(X)` | Un código de curso no es un átomo. |
| `autoincompatible(C)` | Se declaró `incompatible(C, C)`. |
| `par_duplicado(A, B)` | El par está repetido o ya existe su inverso. |
| `sin_porcentajes` | No existe ningún `max_porcentaje_carrera/2`. |
| `carrera_sin_porcentaje(C)` | Una carrera de las combinaciones no tiene porcentaje. |

El módulo no imprime errores ni termina el programa.

La presentación final de errores pertenece a la historia de integración y CLI.

---

## 11. Responsabilidades que no pertenecen a KANE3-35

Esta historia no implementa:

- balance entre carreras;
- límite de cursos por área;
- incompatibilidades entre cursos de una combinación;
- simetría de incompatibilidad;
- selección de primera regla violada;
- escritura de resultados;
- CLI completo;
- definición de los valores académicos reales de la política.

---

## 12. Pruebas

Las pruebas unitarias se encuentran en:

```text
tests/unit/policy_loader_test.pl
```

Los fixtures se encuentran en:

```text
tests/fixtures/policy/
```

| Fixture | Propósito |
|---|---|
| `politica_valida.pl` | Política completa válida. |
| `politica_sin_incompatibles.pl` | Política válida sin pares. |
| `politica_limites_y_repetido.pl` | Valores 0, 100, flotante y repetición idéntica. |
| `politica_alternativa.pl` | Segunda política para probar recarga. |
| `politica_sintaxis_error.pl` | Archivo con error de sintaxis. |
| `politica_vacia.pl` | Archivo sin hechos. |
| `politica_invalida_parcial.pl` | Hechos válidos seguidos de una contradicción. |
| `politica_con_directiva.pl` | Intento de incluir una directiva. |
| `combinaciones_reales.json` | Salida real de Racket para integración. |

Actualmente existen pruebas para:

- carga de política válida completa;
- política sin pares incompatibles;
- porcentajes límite 0 y 100;
- porcentaje flotante;
- porcentaje repetido idéntico cargado una sola vez;
- recarga que reemplaza completamente la política anterior;
- archivo inexistente;
- error de sintaxis;
- archivo vacío;
- política inválida que no deja hechos cargados;
- directiva rechazada;
- carrera que no es átomo;
- porcentaje mayor que 100;
- porcentaje negativo;
- porcentaje no numérico;
- porcentajes contradictorios;
- ausencia de porcentajes;
- `max_cursos_area` ausente;
- `max_cursos_area` duplicado;
- `max_cursos_area` negativo;
- `max_cursos_area` no entero;
- curso que no es átomo;
- curso autoincompatible;
- par duplicado exacto;
- par duplicado invertido;
- hecho desconocido;
- cobertura de carreras exitosa;
- carrera sin porcentaje;
- cobertura con lista vacía;
- integración con `data/policy/politica.pl` y el JSON real de Racket.

Al cierre de la historia:

```text
28 / 28 pruebas pasan correctamente
```

---

## 13. Ejecución de pruebas

Desde la raíz del repositorio:

```powershell
swipl -q -s .\tests\unit\policy_loader_test.pl -g run_tests -t halt
```

Regresión:

```powershell
swipl -q -s .\tests\unit\combinations_loader_test.pl -g run_tests -t halt
swipl -q -s .\tests\unit\module_loading_test.pl -g run_tests -t halt
```

Resultados verificados:

```text
policy_loader        28 / 28
combinations_loader  25 / 25
module_loading        4 / 4
```

Una ejecución correcta debe terminar con código de salida:

```text
0
```

---

## 14. Criterios de aceptación verificados

1. Existe el archivo `data/policy/politica.pl`.
2. Se soportan `max_porcentaje_carrera/2`, `max_cursos_area/1` e `incompatible/2`.
3. Cada porcentaje está entre 0 y 100.
4. Una carrera no posee dos máximos contradictorios.
5. Existe exactamente un valor de `max_cursos_area/1`.
6. El máximo por área es entero no negativo.
7. Un curso no puede declararse incompatible consigo mismo.
8. Los pares incompatibles se almacenan en un solo sentido.
9. Toda carrera presente en las combinaciones posee una política de porcentaje.
10. Una política incompleta se considera inválida.
11. Los valores pueden modificarse sin alterar los predicados de reglas.
12. Los porcentajes no están hardcodeados en las reglas: se consultan desde `politica`.
13. El máximo de área no está hardcodeado: se consulta desde `politica`.
14. Los pares incompatibles no están hardcodeados: se consultan desde `politica`.
15. Existen pruebas para políticas válidas e inválidas.

---

## 15. Pendientes del equipo

- Definir los porcentajes máximos reales por carrera.
- Definir el valor real de `max_cursos_area/1`.
- Declarar al menos dos pares incompatibles reales de los planes, con su justificación en el README.
- Completar la lista de carreras con todos los prefijos presentes en los planes de ocho semestres.

---

## 16. Resultado

KANE3-35 deja establecida la frontera de entrada de la política académica.

A partir de esta historia, las reglas de evaluación pueden consultar sus parámetros mediante:

```prolog
politica:max_porcentaje_carrera/2
politica:max_cursos_area/1
politica:incompatible/2
```

sin contener valores hardcodeados y sin depender del formato del archivo de política.
