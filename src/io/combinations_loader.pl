:- module(combinations_loader, [
    cargar_combinaciones/2
]).

:- use_module(library(http/json)).


% =========================================================
% Configuracion del loader
% =========================================================

% Version del schema JSON soportada por esta etapa.
version_soportada("3.0").


% =========================================================
% Punto de entrada publico
% =========================================================

% cargar_combinaciones(+RutaArchivo, -Combinaciones)
%
% Abre el archivo JSON, lo convierte temporalmente a un
% diccionario Prolog, valida su schema y transforma las
% combinaciones JSON a terminos del dominio.
cargar_combinaciones(RutaArchivo, Combinaciones) :-
    setup_call_cleanup(
        open(RutaArchivo, read, Stream, [encoding(utf8)]),
        json_read_dict(Stream, Json),
        close(Stream)
    ),
    validar_schema(Json),
    obtener_combinaciones(Json, CombinacionesJson),
    convertir_combinaciones(CombinacionesJson, Combinaciones).


% =========================================================
% Validacion del schema raiz
% =========================================================

% Verifica que exista schemaVersion y que corresponda
% con la version soportada.
validar_schema(Json) :-
    (
        get_dict(schemaVersion, Json, Version)
    ->
        validar_version(Version)
    ;
        throw(
            error(
                e3_schema(campo_faltante(schemaVersion)),
                context(cargar_combinaciones/2, 'Falta schemaVersion')
            )
        )
    ).


% Verifica que la version recibida sea exactamente
% la version soportada por el loader.
validar_version(Version) :-
    version_soportada(VersionSoportada),
    (
        Version == VersionSoportada
    ->
        true
    ;
        throw(
            error(
                e3_schema(version_no_soportada(Version)),
                context(cargar_combinaciones/2, 'Version de schema no soportada')
            )
        )
    ).


% Obtiene la lista de combinaciones desde el objeto raiz.
obtener_combinaciones(Json, Combinaciones) :-
    (
        get_dict(combinaciones, Json, Combinaciones)
    ->
        validar_lista(combinaciones, Combinaciones)
    ;
        throw(
            error(
                e3_schema(campo_faltante(combinaciones)),
                context(cargar_combinaciones/2, 'Falta combinaciones')
            )
        )
    ).


% =========================================================
% Conversion de combinaciones
% =========================================================

% Inicia la conversion de combinaciones asignando
% identificadores secuenciales desde 1.
convertir_combinaciones(CombinacionesJson, Combinaciones) :-
    convertir_combinaciones(CombinacionesJson, 1, Combinaciones).


% Caso base: no quedan combinaciones por convertir.
convertir_combinaciones([], _, []).


% Convierte una combinacion y continua recursivamente
% con las restantes incrementando el identificador.
convertir_combinaciones(
    [CombinacionJson | RestoJson],
    Id,
    [Combinacion | Resto]
) :-
    convertir_combinacion(
        CombinacionJson,
        Id,
        Combinacion
    ),
    SiguienteId is Id + 1,
    convertir_combinaciones(
        RestoJson,
        SiguienteId,
        Resto
    ).


% Convierte una combinacion JSON al termino:
%
% combinacion(Id, Cursos, CreditosTotales)
convertir_combinacion(
    CombinacionJson,
    Id,
    combinacion(Id, Cursos, CreditosTotales)
) :-
    obtener_campo_requerido(
        CombinacionJson,
        creditosTotales,
        CreditosTotales
    ),
    obtener_campo_requerido(
        CombinacionJson,
        selecciones,
        SeleccionesJson
    ),
    
    validar_lista(
    selecciones,
    SeleccionesJson
    ),

    validar_entero_no_negativo(
        creditosTotales,
        CreditosTotales
    ),

    convertir_selecciones(
        SeleccionesJson,
        Cursos
    ),

    sumar_creditos(
        Cursos,
        CreditosCalculados
    ),

    validar_creditos_totales(
        CreditosTotales,
        CreditosCalculados
    ).


% =========================================================
% Operaciones auxiliares sobre combinaciones
% =========================================================

% Caso base de la suma de creditos.
sumar_creditos([], 0).


% Suma recursivamente los creditos de los cursos
% contenidos en una combinacion.
sumar_creditos(
    [curso(_, _, Creditos, _, _) | Resto],
    Total
) :-
    sumar_creditos(Resto, TotalResto),
    Total is Creditos + TotalResto.
validar_creditos_totales(
    CreditosTotales,
    CreditosCalculados
) :-
    (
        CreditosTotales =:= CreditosCalculados
    ->
        true
    ;
        throw(
            error(
                e3_schema(
                    creditos_totales_inconsistentes(
                        CreditosTotales,
                        CreditosCalculados
                    )
                ),
                context(
                    cargar_combinaciones/2,
                    'La suma de creditos no coincide con creditosTotales'
                )
            )
        )
    ).

% =========================================================
% Conversion de selecciones
% =========================================================

% Caso base: no quedan selecciones por convertir.
convertir_selecciones([], []).


% Convierte cada seleccion JSON a un termino curso/5.
convertir_selecciones(
    [SeleccionJson | RestoJson],
    [Curso | Resto]
) :-
    convertir_seleccion(
        SeleccionJson,
        Curso
    ),
    convertir_selecciones(
        RestoJson,
        Resto
    ).


% Convierte una seleccion JSON al termino:
%
% curso(Codigo, Grupo, Creditos, Carrera, Area)
convertir_seleccion(
    SeleccionJson,
    curso(
        Codigo,
        Grupo,
        Creditos,
        Carrera,
        Area
    )
) :-
    obtener_campo_requerido(
        SeleccionJson,
        curso,
        CodigoJson
    ),
    obtener_campo_requerido(
        SeleccionJson,
        grupo,
        Grupo
    ),
    obtener_campo_requerido(
        SeleccionJson,
        creditos,
        Creditos
    ),
    obtener_campo_requerido(
        SeleccionJson,
        carrera,
        CarreraJson
    ),
    obtener_campo_requerido(
        SeleccionJson,
        area,
        AreaJson
    ),

    validar_texto_no_vacio(curso, CodigoJson),
    validar_entero_positivo(grupo, Grupo),
    validar_entero_no_negativo(creditos, Creditos),
    validar_texto_no_vacio(carrera, CarreraJson),
    validar_texto_no_vacio(area, AreaJson),

    atom_string(Codigo, CodigoJson),
    atom_string(Carrera, CarreraJson),
    atom_string(Area, AreaJson).


% =========================================================
% Validaciones reutilizables
% =========================================================

% Obtiene un campo obligatorio de un diccionario JSON.
% Si no existe, genera un error de schema.
obtener_campo_requerido(Dict, Campo, Valor) :-
    (
        get_dict(Campo, Dict, Valor)
    ->
        true
    ;
        throw(
            error(
                e3_schema(campo_faltante(Campo)),
                context(
                    cargar_combinaciones/2,
                    'Falta un campo requerido'
                )
            )
        )
    ).

% Verifica que un campo tenga como valor una lista.
validar_lista(Campo, Valor) :-
    (
        is_list(Valor)
    ->
        true
    ;
        throw(
            error(
                e3_schema(tipo_invalido(Campo, Valor)),
                context(
                    cargar_combinaciones/2,
                    'El campo debe contener una lista'
                )
            )
        )
    ).

% Verifica que un valor sea un string no vacio.
validar_texto_no_vacio(Campo, Valor) :-
    (
        string(Valor),
        Valor \== ""
    ->
        true
    ;
        lanzar_valor_invalido(Campo, Valor)
    ).


% Verifica que un valor sea un entero mayor que cero.
validar_entero_positivo(Campo, Valor) :-
    (
        integer(Valor),
        Valor > 0
    ->
        true
    ;
        lanzar_valor_invalido(Campo, Valor)
    ).


% Verifica que un valor sea un entero mayor o igual que cero.
validar_entero_no_negativo(Campo, Valor) :-
    (
        integer(Valor),
        Valor >= 0
    ->
        true
    ;
        lanzar_valor_invalido(Campo, Valor)
    ).


% Lanza el error comun utilizado cuando un campo
% contiene un valor invalido.
lanzar_valor_invalido(Campo, Valor) :-
    throw(
        error(
            e3_schema(valor_invalido(Campo, Valor)),
            context(
                cargar_combinaciones/2,
                'Valor invalido en campo requerido'
            )
        )
    ).