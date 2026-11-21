"""Campos de los formularios y vistas que el aplicativo puede consultar."""

from dataclasses import dataclass


@dataclass(frozen=True)
class Campo:
    nombre: str
    etiqueta: str
    tipo: str = 'text'
    opcional: bool = False
    opciones: tuple = ()
    referencia: str = ''
    inicial: str = ''


C = Campo
ENTIDADES = {
    'reparacion': ('Reparaciones', ('numero_ficha',), (
        C('numero_ficha', 'N.º de ficha'), C('numero_orden_trabajo', 'Orden de trabajo'),
        C('tipo_mantenimiento', 'Mantenimiento', opciones=('Preventivo', 'Correctivo')),
        C('prioridad', 'Prioridad', opciones=('Baja', 'Media', 'Alta'), inicial='Media'),
        C('fecha_ingreso', 'Fecha de ingreso (AAAA-MM-DD)', 'date'),
        C('fecha_salida', 'Fecha de salida (AAAA-MM-DD)', 'date', True),
        C('estado_orden', 'Estado de la orden', opciones=('Pendiente', 'En proceso', 'Cerrada', 'Anulada'), inicial='Pendiente'),
        C('falla_reportada', 'Falla reportada'), C('diagnostico', 'Diagnóstico', opcional=True),
        C('garantia', 'Garantía', opcional=True),
        C('proximo_mantenimiento', 'Próximo mantenimiento', opcional=True),
        C('estado_pago', 'Estado de pago', opciones=('Pendiente', 'Parcial', 'Pagado'), inicial='Pendiente'),
        C('placa', 'Placa', referencia='vehiculo'), C('ruc', 'RUC del taller', referencia='proveedor'),
    )),
    'vehiculo': ('Volquetes', ('placa',), (
        C('placa', 'Placa'), C('marca', 'Marca'), C('tipo_vehiculo', 'Tipo de vehículo', inicial='Volquete'),
        C('modelo', 'Modelo'), C('anio_fabricacion', 'Año de fabricación', 'smallint'),
        C('numero_chasis', 'N.º de chasis'), C('kilometraje_actual', 'Kilometraje', 'numeric'),
        C('tipo_combustible', 'Combustible'), C('conductor', 'Conductor', opcional=True),
    )),
    'proveedor': ('Talleres y proveedores', ('ruc',), (
        C('ruc', 'RUC'), C('razon_social', 'Razón social'),
        C('provincia', 'Provincia', opcional=True), C('avenida', 'Avenida', opcional=True),
        C('numero', 'Número de dirección', opcional=True),
    )),
    'proveedor_telefono': ('Teléfonos de proveedores', ('ruc', 'telefono'), (
        C('ruc', 'RUC', referencia='proveedor'), C('telefono', 'Teléfono'),
    )),
    'comprobante': ('Comprobantes', ('numero_comprobante',), (
        C('numero_comprobante', 'N.º de comprobante'),
        C('tipo_comprobante', 'Tipo de comprobante', opciones=('Boleta', 'Factura')),
        C('condicion_pago', 'Condición de pago', opciones=('Contado', 'Crédito')),
        C('ruc', 'RUC del emisor', referencia='proveedor'),
        C('numero_ficha', 'N.º de ficha', referencia='reparacion'),
    )),
    'repuesto': ('Catálogo de repuestos', ('codigo_repuesto',), (
        C('codigo_repuesto', 'Código de repuesto'), C('descripcion', 'Descripción'),
    )),
    'repuesto_utilizado': ('Repuestos utilizados', ('numero_ficha', 'codigo_repuesto'), (
        C('numero_ficha', 'N.º de ficha', referencia='reparacion'),
        C('codigo_repuesto', 'Código de repuesto', referencia='repuesto'),
        C('cantidad', 'Cantidad', 'integer', inicial='1'),
        C('precio_unitario', 'Precio unitario (S/)', 'numeric', True),
    )),
    'servicio_mano_obra': ('Mano de obra', ('numero_ficha_s',), (
        C('numero_ficha_s', 'Código del servicio'),
        C('descripcion_servicio', 'Descripción del servicio'),
        C('cantidad', 'Cantidad', 'integer', inicial='1'),
        C('numero_ficha', 'N.º de ficha', referencia='reparacion'),
        C('importe', 'Importe del renglón (S/)', 'numeric', True),
    )),
}

REPORTES = (
    ('Historial por volquete', 'historial', 'placa, fecha_ingreso DESC, numero_ficha'),
    ('Órdenes abiertas y taller', 'ordenes_abiertas', 'fecha_ingreso, numero_ficha'),
    ('Comprobantes y emisores', 'comprobantes', 'numero_comprobante'),
    ('Consumo de repuestos', 'consumo_repuestos', 'numero_ficha, codigo_repuesto'),
    ('Mano de obra por ficha', 'mano_de_obra', 'numero_ficha, numero_ficha_s'),
    ('Directorio de proveedores', 'directorio', 'razon_social, ruc, telefono'),
    ('Carga histórica por volquete', 'carga_volquete', 'reparaciones DESC, placa'),
    ('Costos registrados por ficha', 'costos', 'numero_ficha'),
    ('Resumen por estado de pago', 'resumen_pagos', 'estado_pago'),
    ('Actividad mensual', 'actividad_mensual', 'mes DESC, tipo_mantenimiento'),
)
