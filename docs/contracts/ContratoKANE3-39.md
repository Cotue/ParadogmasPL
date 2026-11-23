# Contrato KANE3-39 — Consultas relacionales multimodo

**Historia:** KANE3-39  
**Etapa:** 3 — Paradigma lógico  
**Lenguaje:** SWI-Prolog  
**Módulo principal:** `src/domain/combination_queries.pl`  
**Estado:** Implementado

## 1. Objetivo

Ofrecer un predicado relacional que pueda consultarse en distintos modos
aprovechando la unificación y el backtracking, y dejar las combinaciones
disponibles como hechos `combinacion/3` para el resto del programa.

---

## 2. Interfaz pública

```prolog
:- module(combination_queries, [
    registrar_combinaciones/1,
    combinacion/3,
    curso_en_combinacion/2
]).

:- dynamic combinacion/3.
```

| Predicado | Uso |
|---|---|
| `registrar_combinaciones(+Lista)` | Convierte la lista de `cargar_combinaciones/2` en hechos `combinacion/3`. |
| `combinacion(?Id, ?Cursos, ?CreditosTotales)` | Hechos con las combinaciones cargadas. |
| `curso_en_combinacion(?Id, ?Curso)` | Relaciona cada combinación con cada uno de sus cursos. |

---

## 3. Registro de combinaciones

`cargar_combinaciones/2` (KANE3-34) devuelve una lista y no crea hechos.
`registrar_combinaciones/1` es el paso que la convierte en hechos:

```text
cargar_combinaciones/2  →  lista  →  registrar_combinaciones/1  →  combinacion/3
```

- Borra los hechos `combinacion/3` anteriores con `retractall/1`.
- Agrega cada combinación con `assertz/1`, en el mismo orden de la lista.
- Una lista vacía deja cero hechos.

Es el único uso de `assert/retract` del módulo y solo carga datos de entrada,
como permite la sección 46 del contrato maestro. No se guardan resultados,
contadores ni estados intermedios.

Se ubicó en este módulo para no modificar `combinations_loader.pl`
(KANE3-34, ya cerrado).

---

## 4. Predicado multimodo

```prolog
curso_en_combinacion(Id, Curso) :-
    combinacion(Id, Cursos, _),
    member(Curso, Cursos).
```

Una sola cláusula sirve para todos los modos. No hay casos especiales según qué
argumentos lleguen ligados: el modo lo decide la unificación.

- `combinacion/3` recorre las combinaciones por backtracking.
- `member/2` recorre los cursos de cada una por backtracking.
- La unificación con `curso/5` filtra y completa los atributos.

---

## 5. Modos de consulta

Los ejemplos usan estas combinaciones de prueba:

```prolog
combinacion(1, [curso('CE1101', 1, 4, computadores, computadores),
                curso('MA1102', 1, 4, matematica, matematicas)], 8).
combinacion(2, [curso('CE1101', 2, 4, computadores, computadores),
                curso('FI1101', 1, 4, fisica, ciencias_naturales)], 8).
combinacion(3, [curso('MA1103', 2, 4, matematica, matematicas),
                curso('CE2101', 1, 4, computadores, computadores)], 8).
```

### 5.1 Combinación conocida → enumerar cursos

```prolog
?- curso_en_combinacion(1, C).
C = curso('CE1101', 1, 4, computadores, computadores) ;
C = curso('MA1102', 1, 4, matematica, matematicas).
```

### 5.2 Curso parcialmente conocido → encontrar combinaciones

```prolog
?- curso_en_combinacion(Id, curso('CE1101', G, Cr, Ca, A)).
Id = 1, G = 1, Cr = 4, Ca = computadores, A = computadores ;
Id = 2, G = 2, Cr = 4, Ca = computadores, A = computadores.
```

Se unifican grupo, créditos, carrera y área a partir del código.

### 5.3 Buscar por un atributo

```prolog
?- curso_en_combinacion(Id, curso(Cod, _, _, _, matematicas)).
Id = 1, Cod = 'MA1102' ;
Id = 3, Cod = 'MA1103'.
```

### 5.4 Ambos conocidos → comprobación

```prolog
?- curso_en_combinacion(2, curso('FI1101', 1, 4, fisica, ciencias_naturales)).
true.

?- curso_en_combinacion(1, curso('FI1101', _, _, _, _)).
false.
```

---

## 6. Restricciones

El módulo:

- no realiza I/O;
- no evalúa reglas académicas;
- solo usa `assert/retract` dentro de `registrar_combinaciones/1`.

---

## 7. Pruebas

Archivo: `tests/unit/combination_queries_test.pl`

| Caso | Modo |
|---|---|
| Id conocido, curso libre | Enumera los cursos en orden |
| Curso parcialmente ligado, Id libre | Encuentra las combinaciones y unifica atributos |
| Búsqueda por área | Filtra por un solo atributo |
| Id y curso ligados | Verdadero y falso |
| Curso inexistente | Falla |
| `registrar_combinaciones/1` dos veces | Reemplaza los hechos anteriores |
| `registrar_combinaciones([])` | Deja cero hechos |

Ejecución:

```powershell
swipl -q -s .\tests\unit\combination_queries_test.pl -g run_tests -t halt
```

Todos los tests unitarios del proyecto terminan con código de salida 0.

---

## 8. Criterios de aceptación

1. Existe `curso_en_combinacion/2`.
2. Enumera los cursos de una combinación (5.1).
3. Funciona con un curso parcialmente ligado (5.2).
4. Unifica grupo, créditos, carrera y área (5.2).
5. Soporta todos los modos con una sola implementación (sección 4).
6. Usa unificación y backtracking (sección 4).
7. Se usa en funcionalidad real del proyecto. **Pendiente: se conecta en KANE3-40.**
8. Hay pruebas para al menos dos modos (sección 7).
9. Los ejemplos quedan listos para la documentación (sección 5).

---

## 9. Pendientes

- KANE3-40: llamar a `registrar_combinaciones/1` después de
  `cargar_combinaciones/2`, recorrer `combinacion/3` por backtracking y usar
  `curso_en_combinacion/2` en funcionalidad real (criterio 7).
