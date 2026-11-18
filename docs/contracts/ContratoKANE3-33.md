# Contrato KANE3-33 — Arquitectura modular base en SWI-Prolog

**Historia:** KANE3-33  
**Etapa:** 3 — Paradigma lógico  
**Lenguaje:** SWI-Prolog  
**Estado:** Implementado

## 1. Objetivo

Establecer la arquitectura modular inicial de la Etapa 3 de CEmestre para permitir que las responsabilidades de entrada/salida, dominio y reglas académicas puedan desarrollarse y probarse de forma independiente.

Esta historia define únicamente la estructura base del proyecto. No implementa reglas académicas ni procesamiento de combinaciones.

## 2. Estructura del proyecto

La estructura base queda definida de la siguiente manera:

```text
ParadogmasPL/
├── data/
│   ├── input/
│   ├── output/
│   └── policy/
│
├── docs/
│   └── contracts/
│
├── src/
│   ├── main.pl
│   │
│   ├── domain/
│   │   ├── combination_queries.pl
│   │   └── evaluator.pl
│   │
│   ├── io/
│   │   ├── combinations_loader.pl
│   │   ├── policy_loader.pl
│   │   └── result_writer.pl
│   │
│   └── rules/
│       ├── area_limit.pl
│       ├── career_balance.pl
│       └── incompatibility.pl
│
└── tests/
    ├── fixtures/
    ├── integration/
    └── unit/
        └── module_loading_test.pl
```

## 3. Responsabilidades de los módulos

### `src/main.pl`

Es el punto de composición de la aplicación.

Su responsabilidad en esta historia es cargar los módulos que forman la arquitectura del proyecto.

No contiene reglas académicas.

### `src/io/combinations_loader.pl`

Módulo reservado para la carga de las combinaciones generadas por Racket.

Su comportamiento funcional se implementará en la historia correspondiente.

### `src/io/policy_loader.pl`

Módulo reservado para la carga de la política académica utilizada por Prolog.

Su comportamiento funcional se implementará en la historia correspondiente.

### `src/io/result_writer.pl`

Módulo reservado para serializar los resultados producidos por Prolog.

Su comportamiento funcional se implementará en la historia correspondiente.

### `src/domain/evaluator.pl`

Módulo reservado para coordinar la evaluación lógica de una combinación.

No implementa reglas académicas directamente en esta historia.

### `src/domain/combination_queries.pl`

Módulo reservado para consultas relacionales sobre las combinaciones y sus cursos.

Los predicados correspondientes se implementarán posteriormente.

### `src/rules/career_balance.pl`

Módulo reservado para la regla de balance de créditos entre carreras.

No realiza operaciones de entrada/salida.

### `src/rules/area_limit.pl`

Módulo reservado para la regla de límite de cursos por área.

No realiza operaciones de entrada/salida.

### `src/rules/incompatibility.pl`

Módulo reservado para la regla de incompatibilidad entre cursos.

No realiza operaciones de entrada/salida.

## 4. Declaración de módulos

Cada componente de `src/` se declara como un módulo independiente de SWI-Prolog.

En esta historia los módulos no exportan predicados funcionales todavía.

Ejemplo:

```prolog
:- module(career_balance, []).
```

Esta decisión evita definir interfaces antes de que sean requeridas por sus respectivas historias de usuario.

## 5. Dependencias entre capas

La arquitectura inicial establece tres grupos principales:

```text
main
 ├── io
 ├── domain
 └── rules
```

Las reglas académicas ubicadas en `src/rules/` no realizan operaciones de entrada/salida.

La lógica de lectura y escritura queda aislada en `src/io/`.

`main.pl` actúa como punto de composición y no contiene lógica académica.

## 6. Pruebas

Se utiliza `plunit`, incluido en SWI-Prolog.

No se agrega ninguna dependencia externa para realizar las pruebas.

La prueba:

```text
tests/unit/module_loading_test.pl
```

verifica que:

- el módulo `main` puede cargarse;
- los módulos de `io` pueden cargarse;
- los módulos de `domain` pueden cargarse;
- los módulos de `rules` pueden cargarse.

La prueba no verifica reglas académicas ni comportamiento funcional.

## 7. Ejecución de verificación

La arquitectura completa puede cargarse mediante:

```powershell
swipl -q -s .\src\main.pl -t halt
```

La prueba de módulos puede ejecutarse mediante:

```powershell
swipl -q -s .\tests\unit\module_loading_test.pl -g run_tests -t halt
```

Una ejecución correcta debe finalizar con código de salida `0`.

## 8. Restricciones

KANE3-33 no debe:

- implementar reglas de balance de carrera;
- implementar límites por área;
- implementar incompatibilidades;
- cargar JSON;
- cargar políticas académicas;
- escribir resultados;
- introducir predicados de consultas funcionales;
- introducir dependencias externas innecesarias.

Estas responsabilidades pertenecen a historias posteriores.

## 9. Criterios de aceptación verificados

1. El repositorio puede cargarse correctamente con SWI-Prolog.
2. Existe la estructura de directorios definida para la Etapa 3.
3. Existe `src/main.pl`.
4. Existen módulos separados para I/O, dominio y reglas.
5. `main.pl` no contiene reglas académicas.
6. Los módulos de reglas no realizan I/O.
7. `plunit` está disponible y configurado mediante la prueba unitaria.
8. Existe una prueba mínima que verifica la carga de todos los módulos.
9. No se introdujeron dependencias externas innecesarias.

## 10. Resultado

KANE3-33 deja preparada la arquitectura base sobre la cual se desarrollarán de manera independiente las historias funcionales posteriores de la Etapa 3.