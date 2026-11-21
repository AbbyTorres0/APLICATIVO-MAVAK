BEGIN;

-- 01. Historial de reparaciones por volquete.
CREATE OR REPLACE VIEW mavak.historial AS
SELECT v.placa, v.marca, v.modelo, r.numero_ficha, r.numero_orden_trabajo,
       r.fecha_ingreso, r.fecha_salida, r.tipo_mantenimiento, r.estado_orden, r.diagnostico
FROM public.vehiculo v JOIN public.reparacion r ON r.placa = v.placa;

-- 02. Órdenes abiertas y taller asignado.
CREATE OR REPLACE VIEW mavak.ordenes_abiertas AS
SELECT r.numero_ficha, r.numero_orden_trabajo, r.placa, p.razon_social,
       r.fecha_ingreso, r.prioridad, r.estado_orden, r.falla_reportada
FROM public.reparacion r JOIN public.proveedor p ON p.ruc = r.ruc
WHERE r.estado_orden IN ('Pendiente', 'En proceso');

-- 03. Comprobantes y proveedor emisor.
CREATE OR REPLACE VIEW mavak.comprobantes AS
SELECT c.numero_comprobante, c.tipo_comprobante, c.condicion_pago, p.razon_social,
       r.numero_ficha, r.placa, r.estado_pago
FROM public.comprobante c
JOIN public.proveedor p ON p.ruc = c.ruc
JOIN public.reparacion r ON r.numero_ficha = c.numero_ficha;

-- 04. Detalle de repuestos con importe por renglón.
CREATE OR REPLACE VIEW mavak.consumo_repuestos AS
SELECT r.numero_ficha, r.placa, p.codigo_repuesto, p.descripcion,
       u.cantidad, u.precio_unitario, u.cantidad * u.precio_unitario AS importe
FROM public.repuesto_utilizado u
JOIN public.repuesto p ON p.codigo_repuesto = u.codigo_repuesto
JOIN public.reparacion r ON r.numero_ficha = u.numero_ficha;

-- 05. Mano de obra por ficha.
CREATE OR REPLACE VIEW mavak.mano_de_obra AS
SELECT r.numero_ficha, r.placa, s.numero_ficha_s, s.descripcion_servicio,
       s.cantidad, s.importe
FROM public.servicio_mano_obra s
JOIN public.reparacion r ON r.numero_ficha = s.numero_ficha;

-- 06. Directorio de proveedores, incluso sin teléfono.
CREATE OR REPLACE VIEW mavak.directorio AS
SELECT p.ruc, p.razon_social, p.provincia, p.avenida, p.numero, t.telefono
FROM public.proveedor p LEFT JOIN public.proveedor_telefono t ON t.ruc = p.ruc;

-- 07. Carga histórica por volquete, incluso sin reparaciones.
CREATE OR REPLACE VIEW mavak.carga_volquete AS
SELECT v.placa, v.marca, v.modelo, count(r.numero_ficha) AS reparaciones,
       count(*) FILTER (WHERE r.estado_orden IN ('Pendiente', 'En proceso')) AS abiertas,
       max(r.fecha_ingreso) AS ultimo_ingreso
FROM public.vehiculo v LEFT JOIN public.reparacion r ON r.placa = v.placa
GROUP BY v.placa, v.marca, v.modelo;

-- 08. Costos registrados. Cada detalle se agrega antes del JOIN.
CREATE OR REPLACE VIEW mavak.costos AS
WITH piezas AS (
    SELECT numero_ficha, sum(cantidad * precio_unitario) AS subtotal,
           count(*) FILTER (WHERE precio_unitario IS NULL) AS sin_costo
    FROM public.repuesto_utilizado GROUP BY numero_ficha
), servicios AS (
    SELECT numero_ficha, sum(importe) AS subtotal,
           count(*) FILTER (WHERE importe IS NULL) AS sin_costo
    FROM public.servicio_mano_obra GROUP BY numero_ficha
)
SELECT r.numero_ficha, r.placa, coalesce(p.subtotal, 0) AS repuestos_registrados,
       coalesce(s.subtotal, 0) AS mano_obra_registrada,
       coalesce(p.sin_costo, 0) + coalesce(s.sin_costo, 0) AS renglones_sin_costo,
       CASE WHEN coalesce(p.sin_costo, 0) + coalesce(s.sin_costo, 0) = 0
            THEN coalesce(p.subtotal, 0) + coalesce(s.subtotal, 0) END AS total_registrado
FROM public.reparacion r
LEFT JOIN piezas p ON p.numero_ficha = r.numero_ficha
LEFT JOIN servicios s ON s.numero_ficha = r.numero_ficha;

-- 09. Órdenes agrupadas por estado de pago.
CREATE OR REPLACE VIEW mavak.resumen_pagos AS
SELECT estado_pago, count(*) AS reparaciones
FROM public.reparacion GROUP BY estado_pago;

-- 10. Mantenimientos realizados o registrados por mes y tipo.
CREATE OR REPLACE VIEW mavak.actividad_mensual AS
SELECT date_trunc('month', fecha_ingreso::timestamp)::date AS mes,
       tipo_mantenimiento, count(*) AS reparaciones
FROM public.reparacion
GROUP BY 1, 2;

COMMIT;
