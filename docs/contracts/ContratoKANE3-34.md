# Contrato KANE3-34 — Carga y transformación de combinaciones JSON

**Historia:** KANE3-34  
**Etapa:** 3 — Paradigma lógico  
**Lenguaje:** SWI-Prolog  
**Módulo principal:** `src/io/combinations_loader.pl`  
**Estado:** Implementado

## 1. Objetivo

Cargar el archivo JSON generado por Racket, validar su estructura básica y transformar cada combinación a términos Prolog independientes del formato externo.

Esta historia corresponde únicamente a la frontera de entrada entre Racket y Prolog.

No ejecuta políticas académicas ni reglas de evaluación.

---

## 2. Interfaz pública

El módulo exporta:

```prolog
cargar_combinaciones/2
```

Uso conceptual:

```prolog
cargar_combinaciones(+RutaArchivo, -Combinaciones)
```

Donde:

- `RutaArchivo` es la ruta del JSON generado por Racket.
- `Combinaciones` es la lista de términos Prolog resultante.

Ejemplo:

```prolog
?- cargar_combinaciones(
       'data/input/combinaciones.json',
       Combinaciones
   ).
```

---

## 3. Versión soportada

La versión soportada del contrato de entrada es:

```json
"schemaVersion": "3.0"
```

En Prolog se representa mediante:

```prolog
version_soportada("3.0").
```

Si el campo `schemaVersion` no existe, el loader rechaza la entrada.

Si existe pero contiene una versión diferente de `"3.0"`, también se rechaza.

---

## 4. Estructura JSON esperada

La raíz debe tener la forma conceptual:

```json
{
  "schemaVersion": "3.0",
  "combinaciones": [
    {
      "creditosTotales": 10,
      "selecciones": [
        {
          "curso": "CE1101",
          "grupo": 1,
          "creditos": 3,
          "carrera": "Computadores",
          "area": "computadores"
        }
      ]
    }
  ]
}
```

Los campos requeridos de cada selección son:

```text
curso
grupo
creditos
carrera
area
```

Cada combinación requiere:

```text
creditosTotales
selecciones
```

---

## 5. Representación lógica resultante

Los diccionarios obtenidos desde JSON se utilizan únicamente dentro del módulo de carga.

Una selección válida se transforma a:

```prolog
curso(
    Codigo,
    Grupo,
    Creditos,
    Carrera,
    Area
)
```

Ejemplo:

```prolog
curso(
    'CE1101',
    1,
    3,
    'Computadores',
    computadores
)
```

Una combinación válida se transforma a:

```prolog
combinacion(
    Id,
    Cursos,
    CreditosTotales
)
```

Ejemplo:

```prolog
combinacion(
    1,
    [
        curso(
            'CE1101',
            1,
            3,
            'Computadores',
            computadores
        )
    ],
    3
)
```

Los diccionarios JSON no forman parte de la representación utilizada por las reglas de dominio.

---

## 6. Identificador de combinación

El JSON recibido desde Racket no contiene un identificador para cada combinación.

Por esta razón, el loader asigna un identificador secuencial comenzando en:

```text
1
```

según el orden de aparición en el JSON.

Ejemplo:

```text
primera combinación  -> Id = 1
segunda combinación  -> Id = 2
tercera combinación  -> Id = 3
```

Este identificador:

- pertenece únicamente a la ejecución actual;
- permite relacionar una combinación con sus resultados durante esa ejecución;
- no debe considerarse persistente entre ejecuciones diferentes.

---

## 7. Conversión de datos textuales

Los campos JSON:

```text
curso
carrera
area
```

son recibidos como strings y convertidos a átomos Prolog mediante `atom_string/2`.

Ejemplo:

```text
"CE1101"        -> 'CE1101'
"Computadores"  -> 'Computadores'
"computadores"  -> computadores
```

El loader no cambia el contenido semántico del dato.

No:

- infiere carreras;
- corrige carreras;
- infiere áreas;
- cambia mayúsculas o minúsculas;
- aplica reglas académicas.

---

## 8. Validación de campos obligatorios

Se utiliza:

```prolog
obtener_campo_requerido/3
```

para validar la existencia de campos obligatorios.

Si un campo requerido no existe, se genera:

```prolog
error(
    e3_schema(campo_faltante(Campo)),
    _
)
```

Ejemplo:

```prolog
error(
    e3_schema(campo_faltante(area)),
    _
)
```

---

## 9. Validación de valores

### 9.1 Curso

`curso` debe ser un string no vacío.

Ejemplo válido:

```json
"curso": "CE1101"
```

Ejemplo inválido:

```json
"curso": ""
```

### 9.2 Grupo

`grupo` debe ser:

```text
entero > 0
```

Ejemplos inválidos:

```json
"grupo": 0
```

```json
"grupo": 1.5
```

### 9.3 Créditos

`creditos` debe ser:

```text
entero >= 0
```

Ejemplos inválidos:

```json
"creditos": -1
```

```json
"creditos": 3.5
```

### 9.4 Carrera

`carrera` debe ser un string no vacío.

### 9.5 Área

`area` debe ser un string no vacío.

Los valores inválidos producen:

```prolog
error(
    e3_schema(valor_invalido(Campo, Valor)),
    _
)
```

---

## 10. Validación de créditos totales

`creditosTotales` debe:

```text
ser entero
ser >= 0
```

Además, debe coincidir con la suma de los créditos individuales de todos los cursos de la combinación.

La suma se realiza sobre términos:

```prolog
curso(_, _, Creditos, _, _)
```

mediante:

```prolog
sumar_creditos/2
```

Ejemplo:

```text
3 + 3 + 4 = 10
```

Si el JSON declara:

```json
"creditosTotales": 10
```

la combinación es consistente.

Si declara:

```json
"creditosTotales": 12
```

pero los cursos suman `10`, se produce:

```prolog
error(
    e3_schema(
        creditos_totales_inconsistentes(
            12,
            10
        )
    ),
    _
)
```

---

## 11. Validación de listas

Los campos:

```text
combinaciones
selecciones
```

deben contener listas.

La validación se realiza mediante:

```prolog
validar_lista/2
```

Si el campo existe pero no contiene una lista, se produce:

```prolog
error(
    e3_schema(
        tipo_invalido(
            Campo,
            Valor
        )
    ),
    _
)
```

Esto permite diferenciar entre:

```text
campo inexistente
```

y:

```text
campo existente con tipo incorrecto
```

---

## 12. Entrada sin combinaciones

La entrada:

```json
{
  "schemaVersion": "3.0",
  "combinaciones": []
}
```

es válida.

El resultado es:

```prolog
[]
```

No se considera un error que el archivo no contenga combinaciones.

---

## 13. Separación entre I/O y dominio

El flujo de conversión queda definido como:

```text
Archivo JSON
    ↓
json_read_dict/2
    ↓
dict temporal
    ↓
validación estructural
    ↓
conversión
    ↓
combinacion/3
    └── curso/5
```

Los `dict` existen únicamente dentro de `combinations_loader.pl`.

Las reglas académicas posteriores deben trabajar sobre:

```prolog
combinacion/3
curso/5
```

y no sobre estructuras JSON.

---

## 14. Responsabilidades que no pertenecen a KANE3-34

Esta historia no implementa:

- balance entre carreras;
- límite de cursos por área;
- incompatibilidades;
- evaluación de políticas;
- selección de primera regla violada;
- escritura de resultados;
- interfaz gráfica;
- CLI completo;
- normalización académica de `carrera`;
- inferencia de `area`.

Tampoco genera nuevas combinaciones.

Su responsabilidad termina después de producir términos Prolog válidos.

---

## 15. Errores de schema cubiertos

KANE3-34 utiliza la categoría:

```prolog
e3_schema(...)
```

para representar errores estructurales de entrada.

Actualmente se cubren casos como:

```prolog
campo_faltante(Campo)
```

```prolog
version_no_soportada(Version)
```

```prolog
valor_invalido(Campo, Valor)
```

```prolog
tipo_invalido(Campo, Valor)
```

```prolog
creditos_totales_inconsistentes(
    Declarados,
    Calculados
)
```

El manejo global y presentación final de errores pertenece a historias posteriores de integración y CLI.

---

## 16. Pruebas

Las pruebas unitarias se encuentran en:

```text
tests/unit/combinations_loader_test.pl
```

Los fixtures se encuentran en:

```text
tests/fixtures/combinations/
```

Actualmente existen pruebas para:

- entrada sin combinaciones;
- versión válida;
- versión no soportada;
- `schemaVersion` ausente;
- conversión de una combinación válida;
- asignación secuencial de identificadores;
- ausencia de cada campo requerido;
- curso vacío;
- grupo cero;
- grupo no entero;
- créditos negativos;
- créditos no enteros;
- carrera vacía;
- área vacía;
- `creditosTotales` ausente;
- `creditosTotales` negativo;
- `creditosTotales` no entero;
- suma de créditos inconsistente;
- `combinaciones` ausente;
- `selecciones` ausente;
- `combinaciones` con tipo incorrecto;
- `selecciones` con tipo incorrecto.

Al cierre de la historia:

```text
25 / 25 pruebas pasan correctamente
```

---

## 17. Ejecución de pruebas

Desde la raíz del repositorio:

```powershell
swipl -q -s .\tests\unit\combinations_loader_test.pl -g run_tests -t halt
```

La regresión de la arquitectura base puede verificarse con:

```powershell
swipl -q -s .\tests\unit\module_loading_test.pl -g run_tests -t halt
```

Una ejecución correcta debe terminar con código de salida:

```text
0
```

---

## 18. Criterios de aceptación verificados

1. Se puede abrir el archivo JSON de entrada.
2. Se valida la versión soportada.
3. Cada selección requiere `curso`, `grupo`, `creditos`, `carrera` y `area`.
4. `curso` no puede estar vacío.
5. `grupo` es entero positivo.
6. `creditos` es entero no negativo.
7. `carrera` no puede estar vacía.
8. `area` no puede estar vacía.
9. `creditosTotales` es entero no negativo.
10. La suma de créditos individuales coincide con `creditosTotales`.
11. Cada selección se convierte a `curso/5`.
12. Cada combinación se convierte a `combinacion/3`.
13. Los diccionarios JSON no circulan por las reglas de dominio.
14. Una entrada con cero combinaciones es válida.
15. Un schema inválido se rechaza antes de ejecutar políticas.
16. No se aplican reglas académicas durante la carga.
17. Existen pruebas unitarias para entradas válidas e inválidas.

---

## 19. Resultado

KANE3-34 deja establecida la frontera de entrada entre Racket y Prolog.

A partir de esta historia, los módulos posteriores pueden trabajar exclusivamente sobre una representación lógica formada por:

```prolog
combinacion/3
curso/5
```

sin depender directamente de la estructura JSON generada por la etapa anterior.