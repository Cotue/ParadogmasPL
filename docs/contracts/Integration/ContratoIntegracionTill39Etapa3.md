# Contrato de Integración — Etapa 3 Prolog

**Proyecto:** CEmestre — Etapa 3  
**Paradigma:** Lógico  
**Lenguaje:** SWI-Prolog  
**Rama de integración:** `integration/etapa3`  
**Estado:** Integración parcial validada  
**Objetivo:** Consolidar en una única rama estable las historias implementadas hasta KANE3-39, sin modificar todavía `main`.

---

## 1. Objetivo de la integración

La rama:

```text
integration/etapa3
```

se utiliza como punto de integración intermedio antes de realizar un eventual merge hacia:

```text
main
```

El propósito es reunir las historias desarrolladas en ramas separadas, validar sus dependencias y ejecutar regresiones antes de afectar la rama principal.

Esta integración no representa todavía una liberación final hacia `main`.

---

## 2. Historias incluidas

La rama de integración contiene el trabajo correspondiente a:

```text
KANE3-33
KANE3-34
KANE3-35
KANE3-36
KANE3-37
KANE3-38
KANE3-39
```

Las responsabilidades principales integradas son:

### KANE3-33 — Arquitectura base

Define la estructura modular inicial del proyecto.

Incluye módulos para:

```text
io/
domain/
rules/
```

y establece la organización base de la Etapa 3.

---

### KANE3-34 — Carga de combinaciones

Implementa la carga y transformación de combinaciones provenientes del archivo generado por la etapa anterior.

Produce términos de la forma:

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

---

### KANE3-35 — Carga de política académica

Implementa la lectura, validación y carga de hechos configurables de política académica.

Entre los hechos utilizados se encuentran:

```prolog
max_porcentaje_carrera(Carrera, Porcentaje).
max_cursos_area(N).
incompatible(CursoA, CursoB).
```

Los hechos se administran mediante el módulo lógico:

```prolog
politica
```

y son consultados por las reglas académicas posteriores.

---

### KANE3-36 — Balance de créditos por carrera

Evalúa el porcentaje de créditos correspondiente a cada carrera presente en una combinación.

La regla consulta:

```prolog
politica:max_porcentaje_carrera(
    Carrera,
    MaxPorcentaje
)
```

y produce razones de la forma:

```prolog
balance_carrera(Carrera)
```

La comparación evita divisiones innecesarias mediante producto cruzado:

```prolog
CreditosCarrera * 100
>
CreditosTotales * MaxPorcentaje
```

---

### KANE3-37 — Límite de cursos por área

Evalúa la cantidad máxima de cursos permitidos por área académica.

Consulta el valor configurado mediante:

```prolog
politica:max_cursos_area/1
```

y detecta violaciones del límite de área.

---

### KANE3-38 — Incompatibilidades entre cursos

Evalúa pares de cursos incompatibles definidos en la política.

La relación se consulta mediante:

```prolog
politica:incompatible/2
```

y se considera en ambos sentidos durante la evaluación.

---

### KANE3-39 — Consultas relacionales sobre combinaciones

Introduce consultas relacionales y multimodo sobre las combinaciones cargadas.

Incluye el registro y consulta de combinaciones mediante predicados orientados al paradigma lógico y al uso de backtracking.

---

## 3. Dependencias reales entre ramas

Antes de realizar la integración se verificó el grafo de Git mediante:

```powershell
git merge-base --is-ancestor ...
```

El resultado mostró la siguiente relación:

```text
main
  |
KANE3-33
  |
KANE3-34
  |
KANE3-35
  |\
  | \
  |  KANE3-36
  |
 KANE3-37
   |
 KANE3-38
   |
 KANE3-39
```

Los resultados de dependencia fueron:

```text
KANE3-33 → KANE3-34                = sí
KANE3-34 → KANE3-35                = sí
KANE3-35 → KANE3-36                = sí
KANE3-36 → KANE3-37                = no
KANE3-37 → KANE3-38                = sí
KANE3-38 → KANE3-39                = sí
```

Esto confirmó que:

```text
KANE3-36
```

y:

```text
KANE3-37
```

son ramas hermanas que nacieron a partir de KANE3-35.

Por esa razón, KANE3-36 no podía asumirse como ancestro de KANE3-37.

---

## 4. Estrategia de integración utilizada

Se creó una rama específica:

```text
integration/etapa3
```

a partir de:

```text
main
```

Primero se integró:

```text
KANE3-39
```

Como KANE3-39 ya contenía:

```text
KANE3-37
KANE3-38
```

y estas a su vez dependían de KANE3-35 y las historias anteriores, este paso incorporó la siguiente línea completa:

```text
KANE3-33
  ↓
KANE3-34
  ↓
KANE3-35
  ↓
KANE3-37
  ↓
KANE3-38
  ↓
KANE3-39
```

Después se integró:

```text
feature/KANE3-36
```

mediante un merge normal.

El commit de integración generado fue:

```text
85a53f8
```

con el mensaje:

```text
Merge branch 'feature/KANE3-36' into integration/etapa3
```

El grafo resultante conserva ambas líneas de desarrollo.

---

## 5. Resultado del merge

Después de la integración, el grafo quedó conceptualmente:

```text
                   KANE3-36
                  /        \
KANE3-35 ---------          integration/etapa3
        \
         KANE3-37
              \
               KANE3-38
                    \
                     KANE3-39
```

De esta manera, la rama:

```text
integration/etapa3
```

contiene todos los cambios implementados hasta KANE3-39.

---

## 6. Validación posterior a la integración

Después del merge se ejecutaron todas las pruebas existentes dentro de:

```text
tests/
```

Las suites identificadas fueron:

```text
area_limit_test.pl
career_balance_test.pl
combinations_loader_test.pl
combination_queries_test.pl
incompatibility_test.pl
module_loading_test.pl
policy_loader_test.pl
```

Los resultados fueron satisfactorios.

---

## 7. Resultados de pruebas

### Balance por carrera

```text
career_balance_test.pl
9 / 9 pruebas correctas
```

---

### Límite por área

```text
area_limit_test.pl
11 / 11 pruebas correctas
```

---

### Cargador de combinaciones

```text
combinations_loader_test.pl
25 / 25 pruebas correctas
```

---

### Consultas sobre combinaciones

```text
combination_queries_test.pl
7 / 7 pruebas correctas
```

---

### Incompatibilidades

```text
incompatibility_test.pl
12 / 12 pruebas correctas
```

Existe un warning asociado a un choicepoint en una prueba de incompatibilidad.

Este comportamiento no provoca fallo de la suite.

---

### Carga de módulos

```text
module_loading_test.pl
4 / 4 pruebas correctas
```

---

### Carga de política

```text
policy_loader_test.pl
28 / 28 pruebas correctas
```

---

## 8. Regresión general

La integración fue validada ejecutando todas las suites disponibles mediante:

```powershell
Get-ChildItem .\tests -Recurse -Filter "*_test.pl" | ForEach-Object {
    Write-Host "`n=== Ejecutando $($_.FullName) ==="
    swipl -q -s $_.FullName -g run_tests -t halt

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR en $($_.Name)"
        break
    }
}
```

No se detectaron fallos funcionales en las historias integradas.

---

## 9. Ajuste posterior en KANE3-36

Después del merge se identificó un diagnóstico del analizador estático de VS Code en:

```text
src/rules/career_balance.pl
```

El mensaje era:

```text
Predicate politica:max_porcentaje_carrera/2 not defined
```

Este diagnóstico no correspondía a un fallo de ejecución.

Las pruebas de SWI-Prolog demostraban que:

```prolog
politica:max_porcentaje_carrera/2
```

se encontraba disponible correctamente después de cargar la política mediante KANE3-35.

El problema correspondía a que el analizador estático examinaba `career_balance.pl` sin reconocer que el predicado sería definido dinámicamente durante la ejecución.

---

## 10. Solución aplicada al diagnóstico

Se agregó únicamente en:

```text
src/rules/career_balance.pl
```

la declaración:

```prolog
:- dynamic politica:max_porcentaje_carrera/2.
```

La declaración documenta explícitamente que:

```prolog
politica:max_porcentaje_carrera/2
```

es un predicado dinámico cuyo contenido se carga durante la ejecución.

La consulta original se mantuvo:

```prolog
politica:max_porcentaje_carrera(
    Carrera,
    MaxPorcentaje
)
```

No se modificó la lógica de evaluación.

---

## 11. Cambios descartados durante la integración

Inicialmente se evaluó crear un módulo adicional para centralizar los hechos de política.

La propuesta implicaba modificar:

```text
policy_loader.pl
career_balance.pl
area_limit.pl
incompatibility.pl
```

y agregar un archivo adicional para los hechos dinámicos.

Este enfoque produjo nuevos diagnósticos de predicados no definidos en otras historias.

Dado que:

- las pruebas ya eran correctas;
- la ejecución en SWI-Prolog funcionaba;
- el problema original se limitaba a un diagnóstico estático;

se decidió revertir ese refactor.

La arquitectura existente de KANE3-35, KANE3-37 y KANE3-38 se mantuvo sin modificaciones.

La solución final se limitó al ajuste puntual de:

```text
career_balance.pl
```

evitando introducir cambios innecesarios en historias ya funcionales.

---

## 12. Estado del módulo de política

El módulo de carga de política continúa siendo responsable de administrar los hechos dinámicos:

```prolog
politica:max_porcentaje_carrera/2
politica:max_cursos_area/1
politica:incompatible/2
```

Las reglas únicamente consultan estos hechos.

No se modificó el archivo:

```text
data/policy/politica.pl
```

como parte de la integración.

Los valores de política siguen siendo configurables externamente.

---

## 13. Separación de responsabilidades conservada

La integración conserva la separación principal:

```text
io/
    carga y validación de archivos

domain/
    consultas y lógica relacional

rules/
    evaluación de políticas académicas

data/
    datos configurables
```

La integración no introdujo generación de combinaciones dentro de Prolog ni lógica de interfaz.

---

## 14. Estado de Git

La rama activa para continuar la integración es:

```text
integration/etapa3
```

La rama:

```text
main
```

no ha sido modificada todavía.

Esto permite continuar validando las historias siguientes antes de realizar una integración definitiva.

---

## 15. Criterios de integración verificados

La integración se considera válida porque:

1. se verificaron las relaciones reales entre ramas;
2. no se asumieron dependencias inexistentes;
3. KANE3-37, KANE3-38 y KANE3-39 se integraron mediante su línea común;
4. KANE3-36 se integró posteriormente como rama paralela;
5. el merge conserva el historial de ambas líneas;
6. no se utilizó `squash`;
7. no se sobrescribieron historias existentes;
8. todas las suites disponibles terminan correctamente;
9. no existen cambios pendientes derivados del merge;
10. `main` permanece sin modificar;
11. el diagnóstico estático de KANE3-36 fue corregido sin alterar su comportamiento;
12. se descartó un refactor que introducía complejidad y nuevos diagnósticos innecesarios.

---

## 16. Estado final

La rama:

```text
integration/etapa3
```

constituye actualmente la versión integrada y validada de las historias:

```text
KANE3-33
KANE3-34
KANE3-35
KANE3-36
KANE3-37
KANE3-38
KANE3-39
```

Las pruebas existentes permanecen correctas después de combinar las ramas.

El proyecto todavía no se ha integrado a:

```text
main
```

por decisión deliberada.

Las siguientes historias deberán continuar tomando como referencia la versión consolidada en:

```text
integration/etapa3
```

hasta que se decida realizar el merge final hacia la rama principal.