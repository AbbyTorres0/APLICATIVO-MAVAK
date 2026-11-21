"""Acceso a PostgreSQL. Cada operación se ejecuta en su propia transacción."""

import psycopg
from psycopg import sql

from modelo import ENTIDADES, REPORTES


def consultar(config, sentencia, parametros=()):
    with psycopg.connect(**config, connect_timeout=5, options='-c statement_timeout=10000') as conexion:
        with conexion.cursor() as cursor:
            cursor.execute(sentencia, parametros)
            if cursor.description:
                return [col.name for col in cursor.description], cursor.fetchall()


def listar(config, tabla):
    _, claves, campos = ENTIDADES[tabla]
    sentencia = sql.SQL('SELECT {} FROM public.{} ORDER BY {}').format(
        sql.SQL(', ').join(sql.Identifier(c.nombre) for c in campos),
        sql.Identifier(tabla),
        sql.SQL(', ').join(map(sql.Identifier, claves)),
    )
    return consultar(config, sentencia)[1]


def opciones(config, tabla):
    _, (clave,), _ = ENTIDADES[tabla]
    sentencia = sql.SQL('SELECT {0} FROM public.{1} ORDER BY {0}').format(
        sql.Identifier(clave), sql.Identifier(tabla))
    return [str(fila[0]).rstrip() for fila in consultar(config, sentencia)[1]]


def reporte(config, indice):
    _, vista, orden = REPORTES[indice]
    return consultar(config, sql.SQL('SELECT * FROM mavak.{} ORDER BY {}').format(
        sql.Identifier(vista), sql.SQL(orden)))


def guardar(config, tabla, accion, valores, clave_anterior=()):
    _, claves, campos = ENTIDADES[tabla]
    tipos_clave = tuple(next(c.tipo for c in campos if c.nombre == nombre) for nombre in claves)
    tipos = () if accion == 'eliminar' else tuple(c.tipo for c in campos)
    tipos += tipos_clave if accion in ('actualizar', 'eliminar') else ()
    marcadores = sql.SQL(', ').join(sql.SQL('%s::{}').format(sql.SQL(tipo)) for tipo in tipos)
    consultar(config, sql.SQL('CALL mavak.{}({})').format(
        sql.Identifier(f'{accion}_{tabla}'), marcadores), (*valores, *clave_anterior))
