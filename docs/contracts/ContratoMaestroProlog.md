# Contrato Maestro de Arquitectura y Flujo — CEmestre Etapa 3

**Versión del contrato:** 1.0  
**Etapa:** 3 — Paradigma lógico  
**Lenguaje principal:** SWI-Prolog  
**Etapas afectadas por integración:** C y Racket  
**Rol del documento:** Fuente de verdad arquitectónica para el desarrollo de la Etapa 3.

---

# 1. Propósito

Este documento define la arquitectura, límites entre etapas, modelos conceptuales, contratos de entrada y salida, reglas de política, flujo de datos y principios de implementación de la Etapa 3 de CEmestre.

Su propósito es permitir que cualquier integrante del equipo —o una herramienta de IA— pueda implementar una parte del proyecto sin depender de conocimiento informal ni introducir decisiones incompatibles con el resto del sistema.

Este contrato precede conceptualmente a las historias de usuario de Etapa 3.

Las historias posteriores deben respetar las decisiones aquí establecidas.

Si una implementación contradice este documento, debe corregirse la implementación o modificarse explícitamente el contrato antes de continuar.

---

# 2. Objetivo de la Etapa 3

Etapa 3 recibe las combinaciones válidas producidas previamente por Racket y las evalúa contra un conjunto configurable de reglas de política académica.

Por cada combinación debe determinar:

```text
¿Cumple todas las reglas?
```

Si no cumple:

```text
¿Cuál es la primera regla que viola?
```

El módulo debe utilizar los principios del paradigma lógico:

```text
hechos
reglas
términos compuestos
unificación
backtracking
corte
negación por falla
```

La salida será posteriormente consumida por Java.

---

# 3. Contexto global del sistema

CEmestre continúa dividido en programas independientes.

```text
ETAPA 1 — C
    ↓
ETAPA 2 — RACKET
    ↓
ETAPA 3 — PROLOG
    ↓
ETAPA 4 — JAVA
```

La integración entre etapas ocurre mediante archivos.

No existe memoria compartida entre los programas.

Cada etapa agrega información o toma decisiones correspondientes exclusivamente a su paradigma y responsabilidad.

---

# 4. Responsabilidad de Etapa 1 — C

C continúa siendo responsable de:

- cargar el plan de estudios seleccionado;
- procesar requisitos;
- procesar correquisitos;
- determinar elegibilidad;
- calcular choques entre grupos;
- construir el catálogo;
- extender los datos hasta los primeros ocho semestres;
- conservar la procedencia académica de cada curso;
- incorporar el nuevo campo `area`.

Los algoritmos académicos construidos anteriormente no deben reescribirse para Etapa 3.

La incorporación de los nuevos datos afecta principalmente:

```text
datos fuente
↓
lectura
↓
modelo Course
↓
validación
↓
serialización JSON
```

No debe alterar:

```text
requisitos
correquisitos
elegibilidad
cálculo de choques
comparación de horarios
```

---

# 5. Responsabilidad de Etapa 2 — Racket

Racket continúa siendo responsable de:

- leer el catálogo producido por C;
- leer las preferencias;
- construir cursos candidatos;
- generar combinaciones mediante streams;
- seleccionar exactamente un grupo por curso incluido;
- impedir combinaciones con choques;
- validar correquisitos pendientes;
- filtrar por rango de créditos;
- exportar las combinaciones válidas.

Para soportar Etapa 3, Racket deberá además:

- leer `area`;
- conservar `area`;
- propagar `area`;
- conservar la procedencia `carrera`;
- exportar los créditos individuales de cada selección;
- exportar `carrera` y `area`.

Racket **no calcula áreas**.

Racket **no vuelve a determinar la procedencia académica**.

Racket recibe ambos datos desde C.

---

# 6. Responsabilidad de Etapa 3 — Prolog

Prolog es responsable de:

1. cargar las combinaciones generadas por Racket;
2. cargar los parámetros de política;
3. evaluar balance entre carreras;
4. evaluar límite de cursos por área;
5. evaluar incompatibilidades;
6. determinar la primera regla violada;
7. evaluar todas las combinaciones mediante backtracking;
8. exportar un resultado por cada combinación.

Prolog NO debe:

```text
generar nuevas combinaciones
agregar cursos
eliminar cursos
cambiar grupos
recalcular choques
recalcular requisitos
recalcular correquisitos
recalcular elegibilidad
volver a aplicar el rango de créditos
inferir áreas
corregir datos producidos por etapas anteriores
```

---

# 7. Unidad de ejecución

Una ejecución de CEmestre trabaja sobre un único plan de estudios seleccionado.

Ejemplo conceptual:

```text
Estudiante
    ↓
selecciona plan de Ingeniería en Computadores
    ↓
C genera catálogo de ese plan
    ↓
Racket genera combinaciones de ese catálogo
    ↓
Prolog evalúa esas combinaciones
```

El estudiante no combina arbitrariamente dos planes académicos.

Sin embargo, dentro de un mismo plan existen cursos provenientes de distintas escuelas o unidades académicas.

Por ejemplo:

```text
CE... → Computadores
MA... → Matemática
FI... → Física
EL... → Electrónica
```

Esta procedencia es independiente del plan que está cursando el estudiante.

---

# 8. Distinción entre plan, carrera y área

Esta distinción es fundamental para toda Etapa 3.

## 8.1 Plan del estudiante

Es el plan académico seleccionado al ejecutar C.

Ejemplo:

```text
Ingeniería en Computadores
```

Determina qué catálogo de cursos se procesa.

No es la propiedad utilizada directamente por la regla de balance.

---

## 8.2 Carrera

`carrera` representa la **procedencia académica del curso**.

Conceptualmente:

```text
CE... → computadores
MA... → matematica
FI... → fisica
EL... → electronica
```

Otros prefijos deberán agregarse utilizando los cursos reales de los planes.

Esta propiedad es utilizada por:

```text
BALANCE ENTRE CARRERAS
```

---

## 8.3 Área

`area` representa una clasificación académica más amplia definida por el equipo.

No identifica necesariamente la escuela que imparte el curso.

Es utilizada por:

```text
LÍMITE DE CURSOS POR ÁREA
```

Por tanto:

```text
carrera ≠ area
```

---

# 9. Clasificación de áreas

La clasificación adoptada inicialmente por el equipo será:

```text
ciencias_naturales
matematicas
comunicacion
computadores
optativas
electronica
```

Estas categorías son deliberadamente amplias.

No se utilizarán categorías excesivamente específicas como:

```text
calculo
algebra
programacion
bases_de_datos
redes
fisica_1
fisica_2
```

porque eso reduciría la utilidad de la regla de máximo de cursos por área.

---

# 10. Semántica de las áreas

## `ciencias_naturales`

Incluye cursos correspondientes a disciplinas como:

```text
Física
Química
```

Ejemplo conceptual:

```text
FIxxxx
→ carrera: fisica
→ area: ciencias_naturales
```

---

## `matematicas`

Incluye cursos matemáticos del plan, por ejemplo:

```text
Cálculo
Álgebra
Matemática discreta
otros cursos matemáticos
```

Ejemplo:

```text
MA1403
→ carrera: matematica
→ area: matematicas
```

---

## `comunicacion`

Incluye cursos asociados con comunicación, lenguaje y disciplinas equivalentes pertenecientes a la escuela correspondiente.

La procedencia académica continúa conservándose independientemente.

---

## `computadores`

Incluye los cursos regulares propios de Ingeniería en Computadores que no hayan sido clasificados como optativos.

Ejemplo conceptual:

```text
CE1101
→ carrera: computadores
→ area: computadores
```

---

## `optativas`

Incluye cursos que el plan identifica específicamente como parte del bloque de formación optativa definido por el equipo.

Un curso puede tener:

```text
carrera: computadores
area: optativas
```

Por esta razón el área no puede deducirse únicamente utilizando el prefijo del curso.

---

## `electronica`

Incluye los cursos clasificados dentro del área de Electrónica.

Ejemplo conceptual:

```text
ELxxxx
→ carrera: electronica
→ area: electronica
```

---

# 11. Regla de asignación de área

El área se considera un **dato académico del curso**.

Debe ser definida en los datos utilizados por C.

C no debe implementar una larga cadena de condiciones para intentar adivinar el área a partir del código.

Flujo correcto:

```text
datos del plan
    ↓
curso + area
    ↓
C
    ↓
catálogo JSON
```

Especialmente:

```text
CE...
```

no permite distinguir por sí solo entre:

```text
area = computadores
```

y:

```text
area = optativas
```

Por tanto, `area` debe estar explícitamente asignada.

---

# 12. Regla de procedencia académica

La procedencia del curso puede determinarse utilizando el prefijo de su código cuando dicho prefijo representa inequívocamente la escuela de origen.

Ejemplos actualmente conocidos:

```text
CE → computadores
MA → matematica
FI → fisica
EL → electronica
```

La tabla completa se construirá utilizando los cursos reales de los planes.

La responsabilidad de resolver o validar esta procedencia pertenece a C.

Debe existir una única correspondencia centralizada:

```text
prefijo → carrera
```

Racket y Prolog no deben duplicar esta lógica.

Un prefijo desconocido no se convierte silenciosamente en:

```text
otros
```

Debe considerarse un problema de datos hasta que la tabla sea actualizada.

---

# 13. Curso dentro del catálogo de C

Conceptualmente, cada curso debe contener al menos la información necesaria para las etapas posteriores:

```text
codigo
nombre
creditos
semestre
carrera
area
requisitos
correquisitos
grupos
puedeMatricular
correquisitosPendientes
```

más la información existente necesaria para choques y horarios.

`carrera` representa procedencia académica.

`area` representa clasificación de área.

---

# 14. Extensión a ocho semestres

Los planes utilizados por el equipo deben extenderse hasta los primeros:

```text
8 semestres
```

La extensión consiste principalmente en incorporar más datos al módulo existente.

No se crea un algoritmo nuevo para los semestres 7 y 8.

Los nuevos cursos deben pasar por las mismas reglas ya implementadas en C.

---

# 15. Versión del contrato C → Racket

Debido a que `area` pasa a ser un campo obligatorio, el contrato de catálogo evoluciona conceptualmente a:

```text
schemaVersion = "3.0"
```

Un catálogo de una versión anterior no contiene toda la información necesaria para Etapa 3.

---

# 16. Invariantes nuevas del catálogo

Además de las validaciones anteriores, debe cumplirse:

```text
curso.carrera ≠ vacío
curso.area ≠ vacío
```

La carrera debe corresponder con una procedencia conocida.

El área debe pertenecer a la clasificación oficial del equipo.

Todas las representaciones del mismo curso deben conservar:

```text
misma carrera
misma area
mismos creditos
```

Una inconsistencia no debe corregirse silenciosamente.

---

# 17. Flujo global actualizado

```text
                DATOS DEL PLAN
                     │
                     ▼
               ETAPA 1 — C
                     │
              curso contiene:
              - carrera
              - area
              - creditos
              - grupos
              - choques
              - elegibilidad
                     │
                     ▼
             catalogo JSON 3.0
                     │
                     ▼
             ETAPA 2 — RACKET
                     │
                preferencias
                     │
                     ▼
                 candidatos
                     │
                     ▼
               combinaciones
                     │
                     ▼
         combinaciones JSON 3.0
                     │
                     ▼
            ETAPA 3 — PROLOG
                     │
            + archivo política
                     │
          ┌──────────┼──────────┐
          ▼          ▼          ▼
       balance     límite    incompat.
       carrera      área
          └──────────┼──────────┘
                     ▼
             primera violación
                     │
                     ▼
             JSON para Java
```

---

# 18. Propagación de datos en Racket

El flujo de `area` será:

```text
catalog JSON
    ↓
course
    ↓
candidate-course
    ↓
selection
    ↓
combination
    ↓
writer
```

La misma regla aplica a:

```text
carrera
creditos
```

Racket transporta los valores.

No los recalcula.

---

# 19. Evolución de los modelos Racket

Conceptualmente:

```racket
(struct course
  (code
   career
   area
   credits
   can-enroll?
   pending-corequisites
   groups)
  #:transparent)
```

```racket
(struct candidate-course
  (code
   career
   area
   credits
   pending-corequisites
   groups)
  #:transparent)
```

```racket
(struct selection
  (course-code
   group-number
   career
   area
   credits
   pending-corequisites
   conflicts)
  #:transparent)
```

La incorporación del nuevo campo no modifica la semántica de las funciones existentes.

---

# 20. Lógica Racket que no debe modificarse

Etapa 3 no justifica reescribir:

```text
build-candidates
generate-combinations
selection-compatible?
corequisites-satisfied?
credits-in-range?
stream-select
```

Los cambios deben concentrarse en:

```text
modelos
reader
validadores
propagación
writer
fixtures
tests afectados por schema
```

---

# 21. Contrato Racket → Prolog

La salida de Racket evoluciona a:

```text
schemaVersion = "3.0"
```

Estructura conceptual:

```json
{
  "schemaVersion": "3.0",
  "combinaciones": [
    {
      "selecciones": [
        {
          "curso": "CE1101",
          "grupo": 1,
          "creditos": 3,
          "carrera": "computadores",
          "area": "computadores"
        },
        {
          "curso": "MA1403",
          "grupo": 4,
          "creditos": 4,
          "carrera": "matematica",
          "area": "matematicas"
        }
      ],
      "creditosTotales": 7
    }
  ]
}
```

---

# 22. Campos obligatorios para Prolog

Cada selección debe contener:

```text
curso
grupo
creditos
carrera
area
```

Cada combinación debe contener:

```text
selecciones
creditosTotales
```

Prolog no debe consultar nuevamente los archivos de C para obtener esta información.

---

# 23. Validación de entrada en Prolog

Antes de aplicar reglas se valida:

```text
curso        → texto no vacío
grupo        → entero positivo
creditos     → entero no negativo
carrera      → valor no vacío
area         → valor no vacío
creditosTotales → entero no negativo
```

Además:

```text
suma de creditos individuales
=
creditosTotales
```

Esta comprobación corresponde a integridad del contrato.

No constituye un nuevo filtro académico.

---

# 24. Representación lógica de un curso

Representación canónica:

```prolog
curso(Codigo, Grupo, Creditos, Carrera, Area)
```

Ejemplo:

```prolog
curso(
    'MA1403',
    4,
    4,
    matematica,
    matematicas
).
```

---

# 25. Representación lógica de una combinación

```prolog
combinacion(Id, Cursos, CreditosTotales)
```

Ejemplo:

```prolog
combinacion(
    1,
    [
        curso('CE1101', 1, 3, computadores, computadores),
        curso('MA1403', 4, 4, matematica, matematicas)
    ],
    7
).
```

`Id` es únicamente un identificador interno de trazabilidad.

No tiene significado académico.

---

# 26. Frontera JSON → dominio lógico

Los objetos JSON no deben circular directamente por las reglas.

Flujo:

```text
JSON
 ↓
dicts de SWI-Prolog
 ↓
validación
 ↓
curso/5
 ↓
combinacion/3
 ↓
reglas
```

Esto mantiene separadas:

```text
representación externa
```

y:

```text
lógica del dominio
```

---

# 27. Archivo de política

Los parámetros modificables se almacenan como hechos.

Archivo conceptual:

```text
politica.pl
```

Estructura:

```prolog
max_porcentaje_carrera(Carrera, Porcentaje).

max_cursos_area(N).

incompatible(CursoA, CursoB).
```

Ejemplo exclusivamente estructural:

```prolog
max_porcentaje_carrera(computadores, 60).
max_porcentaje_carrera(matematica, 50).
max_porcentaje_carrera(fisica, 40).

max_cursos_area(3).

incompatible('CURSO_A', 'CURSO_B').
incompatible('CURSO_C', 'CURSO_D').
```

Los valores anteriores no representan la política definitiva.

---

# 28. Parámetros no hardcodeados

Las reglas no deben contener directamente:

```text
porcentajes máximos
máximo de cursos por área
pares incompatibles
```

Estos valores pertenecen exclusivamente al archivo de política.

Esto permite cambiarlos durante la defensa sin modificar los predicados.

---

# 29. Validación de política

Una política válida debe cumplir:

- cada porcentaje es numérico y está entre 0 y 100;
- una misma carrera no posee dos porcentajes diferentes;
- `max_cursos_area` existe;
- `max_cursos_area` es entero no negativo;
- un curso no puede ser incompatible consigo mismo;
- los pares incompatibles no se duplican de forma innecesaria;
- toda carrera presente en las combinaciones posee una política de porcentaje.

No es obligatorio que la suma de porcentajes máximos sea 100.

Cada porcentaje representa un máximo independiente.

Una política incompleta genera un error de política.

---

# 30. Regla 1 — Balance entre carreras

La regla utiliza:

```text
carrera
```

de cada curso.

Para cada carrera presente en una combinación se calculan sus créditos:

```text
creditosCarrera
```

y se comparan con los créditos totales.

Conceptualmente:

```text
creditosCarrera
---------------- × 100
creditosTotales
```

debe ser menor o igual que el porcentaje máximo establecido.

---

# 31. Comparación de porcentajes

Para evitar problemas innecesarios de punto flotante se utiliza:

```text
creditosCarrera * 100
<=
creditosTotales * porcentajeMaximo
```

Ejemplo:

```text
créditos carrera = 4
créditos totales = 10
máximo = 50

4 * 100 = 400
10 * 50 = 500

400 <= 500
→ cumple
```

---

# 32. Caso de cero créditos

Puede existir conceptualmente una combinación formada únicamente por cursos de cero créditos.

En ese caso:

```text
creditosTotales = 0
```

La regla de balance se considera satisfecha siempre que todos los créditos individuales sean también cero.

Esto evita una división `0 / 0` y representa el hecho de que ninguna carrera aporta créditos positivos.

Este comportamiento debe documentarse como caso límite.

---

# 33. Regla 2 — Límite por área

La regla utiliza:

```text
area
```

de cada curso.

La política proporciona:

```prolog
max_cursos_area(N).
```

Para toda área presente:

```text
cantidadCursosArea <= N
```

La regla cuenta:

```text
cursos
```

No cuenta:

```text
créditos
grupos
```

---

# 34. Ejemplo de límite por área

Supongamos:

```text
FIxxxx → ciencias_naturales
QUxxxx → ciencias_naturales
FIyyyy → ciencias_naturales
```

y:

```prolog
max_cursos_area(2).
```

La combinación contiene:

```text
3 cursos de ciencias_naturales
```

Por tanto:

```text
3 > 2
→ viola LIMITE_AREA
```

---

# 35. Regla 3 — Incompatibilidad

La política declara pares de cursos:

```prolog
incompatible(A, B).
```

Una combinación viola la regla si contiene simultáneamente ambos cursos.

La incompatibilidad se define a nivel de curso.

El grupo seleccionado no altera la relación.

---

# 36. Simetría de incompatibilidad

La relación es simétrica.

Si existe:

```prolog
incompatible('A', 'B').
```

entonces:

```text
A incompatible B
```

y:

```text
B incompatible A
```

representan la misma política.

Se almacena el par una sola vez.

Conceptualmente:

```prolog
son_incompatibles(A, B) :-
    incompatible(A, B).

son_incompatibles(A, B) :-
    incompatible(B, A).
```

---

# 37. Orden oficial de evaluación

El orden adoptado será:

```text
1. BALANCE_CARRERA
2. LIMITE_AREA
3. INCOMPATIBILIDAD
```

Este orden forma parte del diseño.

Si una combinación viola varias reglas, solo se reporta la primera según esta secuencia.

---

# 38. Representación interna de razones

Las razones se representan mediante términos estructurados.

Balance:

```prolog
balance_carrera(Carrera)
```

Área:

```prolog
limite_area(Area)
```

Incompatibilidad:

```prolog
incompatibilidad(CursoA, CursoB)
```

No se utilizan textos libres dentro de la lógica.

---

# 39. Primera regla violada

Predicado conceptual:

```prolog
primera_violacion(Combinacion, Razon)
```

Estructura:

```prolog
primera_violacion(C, R) :-
    viola_balance(C, R),
    !.

primera_violacion(C, R) :-
    viola_limite_area(C, R),
    !.

primera_violacion(C, R) :-
    viola_incompatibilidad(C, R),
    !.
```

---

# 40. Uso del corte

El corte tiene una responsabilidad específica:

> Una vez encontrada la primera regla violada, no deben buscarse reglas posteriores como posibles razones principales.

No debe utilizarse para ocultar errores de lógica ni para simular comportamiento procedural innecesario.

---

# 41. Negación por falla

Cada regla debe permitir expresar cumplimiento mediante ausencia de una violación.

Ejemplo conceptual:

```prolog
cumple_balance(C) :-
    \+ viola_balance(C, _).
```

El mismo patrón puede utilizarse para:

```text
cumple_limite_area/1
cumple_incompatibilidad/1
```

Esto constituye un uso explícito y justificado de negación por falla.

---

# 42. Evaluación completa

Interfaz conceptual:

```prolog
evaluar_combinacion(Combinacion, Resultado)
```

Resultado aceptado:

```prolog
resultado(true, ninguna)
```

Resultado rechazado:

```prolog
resultado(false, Razon)
```

Toda combinación estructuralmente válida debe generar un resultado.

Una combinación rechazada no debe desaparecer por fallo del predicado.

---

# 43. Predicado multimodo

La Etapa 3 debe incluir al menos un predicado realmente utilizable en varios modos.

Se adopta conceptualmente:

```prolog
curso_en_combinacion(IdCombinacion, Curso)
```

Ejemplo:

```prolog
curso_en_combinacion(Id, Curso) :-
    combinacion(Id, Cursos, _),
    member(Curso, Cursos).
```

---

# 44. Modos de consulta

Con combinación conocida:

```prolog
?- curso_en_combinacion(1, Curso).
```

permite enumerar los cursos de la combinación mediante backtracking.

Con un curso parcialmente conocido:

```prolog
?- curso_en_combinacion(
       Id,
       curso('CE1101', Grupo, Creditos, Carrera, Area)
   ).
```

permite encontrar combinaciones que contienen el curso y unificar el resto de sus atributos.

El predicado debe utilizarse en funcionalidad real del proyecto y no existir únicamente para satisfacer la rúbrica.

---

# 45. Backtracking

Todas las combinaciones deben recorrerse mediante backtracking.

Conceptualmente:

```prolog
combinacion(Id, Cursos, Total),
evaluar_combinacion(
    combinacion(Id, Cursos, Total),
    Resultado
).
```

Cada solución representa la evaluación de una combinación.

Puede utilizarse:

```prolog
findall/3
```

para recolectar los resultados destinados al writer.

---

# 46. Uso de hechos dinámicos

Se permite utilizar hechos dinámicos exclusivamente para cargar los datos externos.

Ejemplo conceptual:

```prolog
:- dynamic combinacion/3.
```

La carga puede utilizar:

```prolog
assertz/1
```

siempre que su único propósito sea incorporar las combinaciones provenientes del archivo de entrada.

No se permite almacenar mediante `assert/retract`:

```text
resultados
contadores
violaciones
porcentajes calculados
créditos acumulados
estados intermedios
```

El estado calculado se maneja mediante:

```text
argumentos
unificación
recursión
backtracking
```

---

# 47. Contrato de salida Prolog → Java

El formato elegido será JSON.

Nombre conceptual:

```text
evaluacion_combinaciones.json
```

Versión inicial:

```text
schemaVersion = "1.0"
```

---

# 48. Estructura de salida

La salida conserva la combinación recibida y agrega:

```text
cumple
razon
```

Ejemplo:

```json
{
  "schemaVersion": "1.0",
  "combinaciones": [
    {
      "selecciones": [
        {
          "curso": "CE1101",
          "grupo": 1,
          "creditos": 3,
          "carrera": "computadores",
          "area": "computadores"
        },
        {
          "curso": "MA1403",
          "grupo": 4,
          "creditos": 4,
          "carrera": "matematica",
          "area": "matematicas"
        }
      ],
      "creditosTotales": 7,
      "cumple": true,
      "razon": null
    }
  ]
}
```

---

# 49. Razones JSON

Balance:

```json
{
  "codigo": "BALANCE_CARRERA",
  "carrera": "matematica"
}
```

Área:

```json
{
  "codigo": "LIMITE_AREA",
  "area": "ciencias_naturales"
}
```

Incompatibilidad:

```json
{
  "codigo": "INCOMPATIBILIDAD",
  "cursoA": "CURSO_A",
  "cursoB": "CURSO_B"
}
```

Si la combinación cumple:

```json
"razon": null
```

---

# 50. Conservación de combinaciones

Prolog evalúa todas las combinaciones recibidas.

No elimina las rechazadas.

Invariante:

```text
cantidadCombinacionesEntrada
=
cantidadResultadosSalida
```

Si entran:

```text
N
```

combinaciones, deben producirse:

```text
N
```

resultados.

---

# 51. Entrada vacía

Es válido recibir:

```json
{
  "schemaVersion": "3.0",
  "combinaciones": []
}
```

El resultado debe contener una colección vacía.

No encontrar combinaciones en Racket no constituye un error de Prolog.

---

# 52. Manejo de errores

Los errores externos se detectan en las fronteras de I/O.

Categorías conceptuales:

```text
E3_ARGS
E3_INPUT_IO
E3_JSON_SYNTAX
E3_SCHEMA
E3_POLICY
E3_OUTPUT_IO
```

## `E3_ARGS`

Cantidad o formato incorrecto de argumentos.

## `E3_INPUT_IO`

No se pudo abrir o leer un archivo de entrada.

## `E3_JSON_SYNTAX`

El archivo JSON no es sintácticamente válido.

## `E3_SCHEMA`

La estructura Racket → Prolog no cumple el contrato.

## `E3_POLICY`

La política es inexistente, incompleta o inválida.

## `E3_OUTPUT_IO`

No se pudo crear o escribir el archivo final.

---

# 53. Separación de errores y lógica

Los módulos de reglas no deben:

```text
imprimir errores
terminar el programa
realizar I/O
```

`main.pl` y los módulos de frontera son responsables de convertir fallos externos en mensajes comprensibles y códigos de salida.

---

# 54. Interfaz del ejecutable

El programa se ejecutará mediante SWI-Prolog.

Interfaz conceptual:

```bash
swipl -q -s src/main.pl -- \
  <combinaciones.json> \
  <politica.pl> \
  <salida.json>
```

Ejemplo:

```bash
swipl -q -s src/main.pl -- \
  data/input/combinaciones_validas.json \
  data/policy/politica.pl \
  data/output/evaluacion_combinaciones.json
```

---

# 55. Estructura del repositorio

```text
CEmestre-Prolog/
│
├── src/
│   ├── main.pl
│   │
│   ├── io/
│   │   ├── combinations_loader.pl
│   │   ├── policy_loader.pl
│   │   └── result_writer.pl
│   │
│   ├── domain/
│   │   ├── evaluator.pl
│   │   └── combination_queries.pl
│   │
│   └── rules/
│       ├── career_balance.pl
│       ├── area_limit.pl
│       └── incompatibility.pl
│
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
│
├── data/
│   ├── input/
│   ├── policy/
│   └── output/
│
├── docs/
│   └── contracts/
│       └── ContratoArquitecturaEtapa3.md
│
├── README.md
└── .gitignore
```

---

# 56. Responsabilidades de módulos

## `src/main.pl`

Tipo:

```text
orquestación / I/O
```

Responsable de:

- argumentos;
- loaders;
- evaluación;
- writer;
- manejo de errores.

No contiene reglas académicas.

---

## `src/io/combinations_loader.pl`

Responsable de:

```text
JSON
↓
validación
↓
curso/5
↓
combinacion/3
```

No evalúa políticas.

---

## `src/io/policy_loader.pl`

Responsable de cargar y validar:

```text
max_porcentaje_carrera/2
max_cursos_area/1
incompatible/2
```

---

## `src/io/result_writer.pl`

Responsable exclusivamente de transformar resultados internos a JSON.

No vuelve a ejecutar reglas.

---

## `src/domain/evaluator.pl`

Responsable de:

- coordinar reglas;
- obtener primera violación;
- construir resultado.

No realiza I/O.

---

## `src/domain/combination_queries.pl`

Contiene predicados relacionales reutilizables como:

```prolog
curso_en_combinacion/2
```

---

## `src/rules/career_balance.pl`

Contiene únicamente lógica correspondiente a:

```text
BALANCE_CARRERA
```

---

## `src/rules/area_limit.pl`

Contiene únicamente lógica correspondiente a:

```text
LIMITE_AREA
```

---

## `src/rules/incompatibility.pl`

Contiene únicamente lógica correspondiente a:

```text
INCOMPATIBILIDAD
```

---

# 57. Dependencias

Se utilizará SWI-Prolog.

Bibliotecas estándar esperadas:

```prolog
library(http/json)
library(lists)
library(apply)
library(plunit)
```

No se incorporarán dependencias externas si SWI-Prolog ya proporciona la funcionalidad necesaria.

---

# 58. Estrategia de pruebas

El desarrollo sigue:

```text
contrato
   ↓
tests RED
   ↓
implementación mínima
   ↓
GREEN
   ↓
regresión
   ↓
commit
```

Cada módulo debe poder probarse independientemente.

---

# 59. Pruebas de C requeridas

La extensión de C deberá verificar:

- ocho semestres;
- carrera/procedencia válida;
- área válida;
- área no vacía;
- consistencia de área para un mismo curso;
- consistencia de carrera para un mismo curso;
- prefijo conocido;
- exportación JSON correcta;
- regresión de requisitos;
- regresión de correquisitos;
- regresión de choques;
- regresión de elegibilidad.

---

# 60. Pruebas de Racket requeridas

La adaptación de Racket deberá verificar:

- lectura de `area`;
- validación de `area`;
- propagación `course → candidate-course`;
- propagación `candidate-course → selection`;
- conservación de `carrera`;
- exportación de `area`;
- exportación de `carrera`;
- exportación de créditos individuales;
- schema correcto;
- combinación vacía válida;
- regresión completa de la generación funcional.

---

# 61. Pruebas de balance

Deben cubrir:

```text
debajo del máximo
exactamente en el máximo
encima del máximo
una carrera
varias carreras
cero créditos
política modificada
```

---

# 62. Pruebas de límite por área

Deben cubrir:

```text
menos de N
exactamente N
más de N
varias áreas
curso de cero créditos
```

---

# 63. Pruebas de incompatibilidad

Deben cubrir:

```text
ningún curso del par
solo curso A
solo curso B
A y B presentes
consulta simétrica
múltiples pares
```

---

# 64. Pruebas de primera violación

Debe existir al menos un caso que viole simultáneamente:

```text
balance
área
incompatibilidad
```

Resultado esperado:

```text
BALANCE_CARRERA
```

Otro caso:

```text
área + incompatibilidad
```

Resultado:

```text
LIMITE_AREA
```

Otro:

```text
solo incompatibilidad
```

Resultado:

```text
INCOMPATIBILIDAD
```

---

# 65. Pruebas del predicado multimodo

Debe demostrarse al menos:

```text
combinación conocida → enumerar cursos
```

y:

```text
curso parcialmente conocido → encontrar combinaciones
```

---

# 66. Prueba de integración

La integración final debe ejecutar:

```text
datos reales
   ↓
C
   ↓
catalogo JSON
   ↓
Racket
   ↓
combinaciones JSON
   ↓
Prolog
   ↓
resultados JSON
```

Los fixtures permiten desarrollar módulos independientemente, pero no sustituyen esta prueba real.

---

# 67. Invariantes globales

Para toda ejecución válida:

```text
Prolog no crea combinaciones.
```

```text
Prolog no elimina combinaciones.
```

```text
Prolog no modifica selecciones.
```

```text
N combinaciones entran
=
N resultados salen.
```

```text
cumple = true
→ razon = null
```

```text
cumple = false
→ existe exactamente una razon
```

---

# 68. Datos configurables pendientes

El contrato no inventa todavía:

```text
tabla completa prefijo → carrera
área exacta de cada curso
porcentajes máximos por carrera
máximo N de cursos por área
pares incompatibles reales
```

Estos valores deben determinarse utilizando los dos planes reales del equipo.

Su modificación no debe requerir cambiar la arquitectura.

---

# 69. Documentación README

El README debe explicar:

- arquitectura;
- flujo C → Racket → Prolog;
- representación de cursos;
- representación de combinaciones;
- diferencia entre plan, carrera y área;
- clasificación de áreas adoptada;
- ejemplos reales de asignación de área;
- tabla de procedencias;
- política utilizada;
- pares incompatibles y su justificación;
- orden de reglas;
- ejemplo donde cambiar el orden cambia la razón;
- corte;
- negación por falla;
- backtracking;
- predicado multimodo;
- caso límite real;
- ejecución mediante `swipl`;
- ejecución de pruebas.

---

# 70. Principio de simplicidad

La arquitectura evita deliberadamente:

- frameworks genéricos de reglas;
- meta-programación innecesaria;
- duplicación de lógica;
- recálculo de información de etapas anteriores;
- estado global para resultados;
- inferencias académicas dentro de Prolog;
- reglas hardcodeadas que deberían ser datos.

Las tres políticas poseen módulos independientes y se integran únicamente en el evaluador.

---

# 71. Regla para cambios futuros

Antes de agregar una funcionalidad debe determinarse su responsabilidad:

```text
¿es dato académico?
        ↓
        C

¿es generación/filtrado de combinaciones?
        ↓
        Racket

¿es política académica?
        ↓
        Prolog

¿es presentación/integración final?
        ↓
        Java
```

No debe trasladarse una responsabilidad a Prolog simplemente porque Prolog sea la etapa actual.

---

# 72. Definition of Done de Etapa 3

Etapa 3 estará terminada cuando:

- los planes cubran ocho semestres;
- C exporte correctamente la procedencia académica;
- C exporte área;
- las áreas correspondan con la clasificación acordada;
- Racket propague carrera;
- Racket propague área;
- Racket exporte créditos individuales;
- la generación de Racket continúe funcionando sin cambios funcionales;
- Prolog cargue el JSON real de Racket;
- la política sea configurable;
- balance funcione;
- límite por área funcione;
- incompatibilidades funcionen;
- la primera violación sea correcta;
- el corte tenga una justificación clara;
- la negación por falla tenga una justificación clara;
- exista un predicado realmente multimodo;
- las combinaciones se recorran mediante backtracking;
- no se utilice estado global para resultados intermedios;
- la cantidad de resultados coincida con la entrada;
- la salida sea consumible por Java;
- todas las pruebas unitarias pasen;
- la integración completa pase;
- el programa pueda ejecutarse con `swipl`;
- el README documente todas las decisiones requeridas;
- todos los integrantes puedan explicar el código durante la defensa.



![alt text](image.png)

Paralelización recomendada

Después de completar KANE3-34 y KANE3-35, las tres reglas pueden desarrollarse independientemente:

Integrante 1 → KANE3-36 Balance

Integrante 2 → KANE3-37 Área

Integrante 3 → KANE3-38 Incompatibilidades

Todas trabajan contra el mismo modelo:

curso/5
combinacion/3

y convergen posteriormente en KANE3-40.