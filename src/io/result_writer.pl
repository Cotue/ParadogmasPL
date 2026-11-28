:- module(result_writer, [
    escribir_resultados/2,
    evaluados_a_json/2
]).

:- use_module(library(http/json)).


% Version del contrato de salida Prolog -> Java.
version_salida("1.0").



escribir_resultados(RutaArchivo, Evaluados) :-
    evaluados_a_json(Evaluados, Json),
    catch(
        escribir_json(RutaArchivo, Json),
        Causa,
        lanzar_error_salida(RutaArchivo, Causa)
    ).



evaluados_a_json(
    Evaluados,
    _{schemaVersion: Version, combinaciones: Combinaciones}
) :-
    version_salida(Version),
    convertir_evaluados(Evaluados, Combinaciones).



escribir_json(RutaArchivo, Json) :-
    setup_call_cleanup(
        open(RutaArchivo, write, Stream, [encoding(utf8)]),
        (   json_write_dict(Stream, Json),
            nl(Stream)
        ),
        close(Stream)
    ).


convertir_evaluados([], []).

convertir_evaluados([Evaluado | Resto], [Combinacion | RestoJson]) :-
    convertir_evaluado(Evaluado, Combinacion),
    convertir_evaluados(Resto, RestoJson).



convertir_evaluado(
    evaluado(combinacion(_Id, Cursos, CreditosTotales), Resultado),
    _{
        selecciones: Selecciones,
        creditosTotales: CreditosTotales,
        cumple: Cumple,
        razon: Razon
    }
) :-
    !,
    convertir_cursos(Cursos, Selecciones),
    convertir_resultado(Resultado, Cumple, Razon).

convertir_evaluado(Otro, _) :-
    lanzar_error_resultado(evaluado_invalido(Otro)).


% convertir_cursos(+Cursos, -Selecciones)
convertir_cursos([], []) :-
    !.

convertir_cursos([Curso | Resto], [Seleccion | RestoJson]) :-
    !,
    convertir_curso(Curso, Seleccion),
    convertir_cursos(Resto, RestoJson).

convertir_cursos(Otro, _) :-
    lanzar_error_resultado(cursos_invalidos(Otro)).


% convertir_curso(+Curso, -SeleccionJson)
convertir_curso(
    curso(Codigo, Grupo, Creditos, Carrera, Area),
    _{
        curso: CodigoTexto,
        grupo: Grupo,
        creditos: Creditos,
        carrera: CarreraTexto,
        area: AreaTexto
    }
) :-
    !,
    a_texto(Codigo, CodigoTexto),
    a_texto(Carrera, CarreraTexto),
    a_texto(Area, AreaTexto).

convertir_curso(Otro, _) :-
    lanzar_error_resultado(curso_invalido(Otro)).


convertir_resultado(resultado(true, ninguna), true, null) :-
    !.

convertir_resultado(resultado(false, Razon), false, RazonJson) :-
    !,
    convertir_razon(Razon, RazonJson).

convertir_resultado(Otro, _, _) :-
    lanzar_error_resultado(resultado_invalido(Otro)).


convertir_razon(
    balance_carrera(Carrera),
    _{codigo: "BALANCE_CARRERA", carrera: CarreraTexto}
) :-
    !,
    a_texto(Carrera, CarreraTexto).

convertir_razon(
    limite_area(Area),
    _{codigo: "LIMITE_AREA", area: AreaTexto}
) :-
    !,
    a_texto(Area, AreaTexto).

convertir_razon(
    incompatibilidad(CursoA, CursoB),
    _{codigo: "INCOMPATIBILIDAD", cursoA: TextoA, cursoB: TextoB}
) :-
    !,
    a_texto(CursoA, TextoA),
    a_texto(CursoB, TextoB).

convertir_razon(Otra, _) :-
    lanzar_error_resultado(razon_desconocida(Otra)).




a_texto(Valor, Texto) :-
    atom_string(Valor, Texto).


% lanzar_error_salida(+Ruta, +Causa)
lanzar_error_salida(Ruta, Causa) :-
    throw(
        error(
            e3_output_io(escritura_fallida(Ruta, Causa)),
            context(
                escribir_resultados/2,
                'No se pudo crear o escribir el archivo de salida'
            )
        )
    ).


% lanzar_error_resultado(+Detalle)
lanzar_error_resultado(Detalle) :-
    throw(
        error(
            e3_resultado(Detalle),
            context(
                evaluados_a_json/2,
                'Resultado interno con forma invalida'
            )
        )
    ).
