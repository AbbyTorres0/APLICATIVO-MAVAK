BEGIN;
CREATE SCHEMA IF NOT EXISTS mavak;
-- El importe corresponde al renglón completo de mano de obra.
ALTER TABLE public.servicio_mano_obra
    ADD COLUMN IF NOT EXISTS importe numeric(12,2) CHECK (importe >= 0 AND importe <> 'NaN'::numeric);

CREATE TABLE IF NOT EXISTS mavak.auditoria (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fecha timestamptz NOT NULL DEFAULT clock_timestamp(),
    usuario text NOT NULL,
    tabla text NOT NULL,
    operacion text NOT NULL CHECK (operacion IN ('INSERT', 'UPDATE', 'DELETE')),
    datos_anteriores jsonb,
    datos_nuevos jsonb
);

CREATE OR REPLACE FUNCTION mavak.auditar_cambio()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO mavak.auditoria (usuario, tabla, operacion, datos_anteriores, datos_nuevos)
    VALUES (session_user, TG_TABLE_NAME, TG_OP,
            CASE WHEN TG_OP <> 'INSERT' THEN to_jsonb(OLD) END,
            CASE WHEN TG_OP <> 'DELETE' THEN to_jsonb(NEW) END);
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS auditar_cambio ON public.vehiculo;
CREATE TRIGGER auditar_cambio AFTER INSERT OR UPDATE OR DELETE ON public.vehiculo
FOR EACH ROW EXECUTE FUNCTION mavak.auditar_cambio();

CREATE OR REPLACE PROCEDURE mavak.insertar_vehiculo(
    p_placa text,
    p_marca text,
    p_tipo_vehiculo text,
    p_modelo text,
    p_anio_fabricacion smallint,
    p_numero_chasis text,
    p_kilometraje_actual numeric,
    p_tipo_combustible text,
    p_conductor text
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO public.vehiculo (placa, marca, tipo_vehiculo, modelo, anio_fabricacion, numero_chasis, kilometraje_actual, tipo_combustible, conductor)
    VALUES (p_placa, p_marca, p_tipo_vehiculo, p_modelo, p_anio_fabricacion, p_numero_chasis, p_kilometraje_actual, p_tipo_combustible, p_conductor);
END;
$$;

CREATE OR REPLACE PROCEDURE mavak.actualizar_vehiculo(
    p_placa text,
    p_marca text,
    p_tipo_vehiculo text,
    p_modelo text,
    p_anio_fabricacion smallint,
    p_numero_chasis text,
    p_kilometraje_actual numeric,
    p_tipo_combustible text,
    p_conductor text,
    p_anterior_placa text
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.vehiculo
    SET placa = p_placa,
        marca = p_marca,
        tipo_vehiculo = p_tipo_vehiculo,
        modelo = p_modelo,
        anio_fabricacion = p_anio_fabricacion,
        numero_chasis = p_numero_chasis,
        kilometraje_actual = p_kilometraje_actual,
        tipo_combustible = p_tipo_combustible,
        conductor = p_conductor
    WHERE vehiculo.placa = p_anterior_placa;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El registro ya no existe.' USING ERRCODE = 'P0002';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE mavak.eliminar_vehiculo(
    p_placa text
)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM public.vehiculo WHERE vehiculo.placa = p_placa;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El registro ya no existe.' USING ERRCODE = 'P0002';
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS auditar_cambio ON public.proveedor;
CREATE TRIGGER auditar_cambio AFTER INSERT OR UPDATE OR DELETE ON public.proveedor
FOR EACH ROW EXECUTE FUNCTION mavak.auditar_cambio();

CREATE OR REPLACE PROCEDURE mavak.insertar_proveedor(
    p_ruc text,
    p_razon_social text,
    p_provincia text,
    p_avenida text,
    p_numero text
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO public.proveedor (ruc, razon_social, provincia, avenida, numero)
    VALUES (p_ruc, p_razon_social, p_provincia, p_avenida, p_numero);
END;
$$;

CREATE OR REPLACE PROCEDURE mavak.actualizar_proveedor(
    p_ruc text,
    p_razon_social text,
    p_provincia text,
    p_avenida text,
    p_numero text,
    p_anterior_ruc text
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.proveedor
    SET ruc = p_ruc,
        razon_social = p_razon_social,
        provincia = p_provincia,
        avenida = p_avenida,
        numero = p_numero
    WHERE proveedor.ruc = p_anterior_ruc;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El registro ya no existe.' USING ERRCODE = 'P0002';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE mavak.eliminar_proveedor(
    p_ruc text
)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM public.proveedor WHERE proveedor.ruc = p_ruc;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El registro ya no existe.' USING ERRCODE = 'P0002';
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS auditar_cambio ON public.proveedor_telefono;
CREATE TRIGGER auditar_cambio AFTER INSERT OR UPDATE OR DELETE ON public.proveedor_telefono
FOR EACH ROW EXECUTE FUNCTION mavak.auditar_cambio();

CREATE OR REPLACE PROCEDURE mavak.insertar_proveedor_telefono(
    p_ruc text,
    p_telefono text
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO public.proveedor_telefono (ruc, telefono)
    VALUES (p_ruc, p_telefono);
END;
$$;

CREATE OR REPLACE PROCEDURE mavak.actualizar_proveedor_telefono(
    p_ruc text,
    p_telefono text,
    p_anterior_ruc text,
    p_anterior_telefono text
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.proveedor_telefono
    SET ruc = p_ruc,
        telefono = p_telefono
    WHERE proveedor_telefono.ruc = p_anterior_ruc AND proveedor_telefono.telefono = p_anterior_telefono;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El registro ya no existe.' USING ERRCODE = 'P0002';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE mavak.eliminar_proveedor_telefono(
    p_ruc text,
    p_telefono text
)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM public.proveedor_telefono WHERE proveedor_telefono.ruc = p_ruc AND proveedor_telefono.telefono = p_telefono;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El registro ya no existe.' USING ERRCODE = 'P0002';
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS auditar_cambio ON public.reparacion;
CREATE TRIGGER auditar_cambio AFTER INSERT OR UPDATE OR DELETE ON public.reparacion
FOR EACH ROW EXECUTE FUNCTION mavak.auditar_cambio();

CREATE OR REPLACE PROCEDURE mavak.insertar_reparacion(
    p_numero_ficha text,
    p_numero_orden_trabajo text,
    p_tipo_mantenimiento text,
    p_prioridad text,
    p_fecha_ingreso date,
    p_fecha_salida date,
    p_estado_orden text,
    p_falla_reportada text,
    p_diagnostico text,
    p_garantia text,
    p_proximo_mantenimiento text,
    p_estado_pago text,
    p_placa text,
    p_ruc text
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO public.reparacion (numero_ficha, numero_orden_trabajo, tipo_mantenimiento, prioridad, fecha_ingreso, fecha_salida, estado_orden, falla_reportada, diagnostico, garantia, proximo_mantenimiento, estado_pago, placa, ruc)
    VALUES (p_numero_ficha, p_numero_orden_trabajo, p_tipo_mantenimiento, p_prioridad, p_fecha_ingreso, p_fecha_salida, p_estado_orden, p_falla_reportada, p_diagnostico, p_garantia, p_proximo_mantenimiento, p_estado_pago, p_placa, p_ruc);
END;
$$;

CREATE OR REPLACE PROCEDURE mavak.actualizar_reparacion(
    p_numero_ficha text,
    p_numero_orden_trabajo text,
    p_tipo_mantenimiento text,
    p_prioridad text,
    p_fecha_ingreso date,
    p_fecha_salida date,
    p_estado_orden text,
    p_falla_reportada text,
    p_diagnostico text,
    p_garantia text,
    p_proximo_mantenimiento text,
    p_estado_pago text,
    p_placa text,
    p_ruc text,
    p_anterior_numero_ficha text
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.reparacion
    SET numero_ficha = p_numero_ficha,
        numero_orden_trabajo = p_numero_orden_trabajo,
        tipo_mantenimiento = p_tipo_mantenimiento,
        prioridad = p_prioridad,
        fecha_ingreso = p_fecha_ingreso,
        fecha_salida = p_fecha_salida,
        estado_orden = p_estado_orden,
        falla_reportada = p_falla_reportada,
        diagnostico = p_diagnostico,
        garantia = p_garantia,
        proximo_mantenimiento = p_proximo_mantenimiento,
        estado_pago = p_estado_pago,
        placa = p_placa,
        ruc = p_ruc
    WHERE reparacion.numero_ficha = p_anterior_numero_ficha;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El registro ya no existe.' USING ERRCODE = 'P0002';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE mavak.eliminar_reparacion(
    p_numero_ficha text
)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM public.reparacion WHERE reparacion.numero_ficha = p_numero_ficha;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El registro ya no existe.' USING ERRCODE = 'P0002';
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS auditar_cambio ON public.comprobante;
CREATE TRIGGER auditar_cambio AFTER INSERT OR UPDATE OR DELETE ON public.comprobante
FOR EACH ROW EXECUTE FUNCTION mavak.auditar_cambio();

CREATE OR REPLACE PROCEDURE mavak.insertar_comprobante(
    p_numero_comprobante text,
    p_tipo_comprobante text,
    p_condicion_pago text,
    p_ruc text,
    p_numero_ficha text
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO public.comprobante (numero_comprobante, tipo_comprobante, condicion_pago, ruc, numero_ficha)
    VALUES (p_numero_comprobante, p_tipo_comprobante, p_condicion_pago, p_ruc, p_numero_ficha);
END;
$$;

CREATE OR REPLACE PROCEDURE mavak.actualizar_comprobante(
    p_numero_comprobante text,
    p_tipo_comprobante text,
    p_condicion_pago text,
    p_ruc text,
    p_numero_ficha text,
    p_anterior_numero_comprobante text
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.comprobante
    SET numero_comprobante = p_numero_comprobante,
        tipo_comprobante = p_tipo_comprobante,
        condicion_pago = p_condicion_pago,
        ruc = p_ruc,
        numero_ficha = p_numero_ficha
    WHERE comprobante.numero_comprobante = p_anterior_numero_comprobante;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El registro ya no existe.' USING ERRCODE = 'P0002';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE mavak.eliminar_comprobante(
    p_numero_comprobante text
)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM public.comprobante WHERE comprobante.numero_comprobante = p_numero_comprobante;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El registro ya no existe.' USING ERRCODE = 'P0002';
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS auditar_cambio ON public.repuesto;
CREATE TRIGGER auditar_cambio AFTER INSERT OR UPDATE OR DELETE ON public.repuesto
FOR EACH ROW EXECUTE FUNCTION mavak.auditar_cambio();

CREATE OR REPLACE PROCEDURE mavak.insertar_repuesto(
    p_codigo_repuesto text,
    p_descripcion text
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO public.repuesto (codigo_repuesto, descripcion)
    VALUES (p_codigo_repuesto, p_descripcion);
END;
$$;

CREATE OR REPLACE PROCEDURE mavak.actualizar_repuesto(
    p_codigo_repuesto text,
    p_descripcion text,
    p_anterior_codigo_repuesto text
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.repuesto
    SET codigo_repuesto = p_codigo_repuesto,
        descripcion = p_descripcion
    WHERE repuesto.codigo_repuesto = p_anterior_codigo_repuesto;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El registro ya no existe.' USING ERRCODE = 'P0002';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE mavak.eliminar_repuesto(
    p_codigo_repuesto text
)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM public.repuesto WHERE repuesto.codigo_repuesto = p_codigo_repuesto;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El registro ya no existe.' USING ERRCODE = 'P0002';
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS auditar_cambio ON public.repuesto_utilizado;
CREATE TRIGGER auditar_cambio AFTER INSERT OR UPDATE OR DELETE ON public.repuesto_utilizado
FOR EACH ROW EXECUTE FUNCTION mavak.auditar_cambio();

CREATE OR REPLACE PROCEDURE mavak.insertar_repuesto_utilizado(
    p_numero_ficha text,
    p_codigo_repuesto text,
    p_cantidad integer,
    p_precio_unitario numeric
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO public.repuesto_utilizado (numero_ficha, codigo_repuesto, cantidad, precio_unitario)
    VALUES (p_numero_ficha, p_codigo_repuesto, p_cantidad, p_precio_unitario);
END;
$$;

CREATE OR REPLACE PROCEDURE mavak.actualizar_repuesto_utilizado(
    p_numero_ficha text,
    p_codigo_repuesto text,
    p_cantidad integer,
    p_precio_unitario numeric,
    p_anterior_numero_ficha text,
    p_anterior_codigo_repuesto text
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.repuesto_utilizado
    SET numero_ficha = p_numero_ficha,
        codigo_repuesto = p_codigo_repuesto,
        cantidad = p_cantidad,
        precio_unitario = p_precio_unitario
    WHERE repuesto_utilizado.numero_ficha = p_anterior_numero_ficha AND repuesto_utilizado.codigo_repuesto = p_anterior_codigo_repuesto;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El registro ya no existe.' USING ERRCODE = 'P0002';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE mavak.eliminar_repuesto_utilizado(
    p_numero_ficha text,
    p_codigo_repuesto text
)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM public.repuesto_utilizado WHERE repuesto_utilizado.numero_ficha = p_numero_ficha AND repuesto_utilizado.codigo_repuesto = p_codigo_repuesto;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El registro ya no existe.' USING ERRCODE = 'P0002';
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS auditar_cambio ON public.servicio_mano_obra;
CREATE TRIGGER auditar_cambio AFTER INSERT OR UPDATE OR DELETE ON public.servicio_mano_obra
FOR EACH ROW EXECUTE FUNCTION mavak.auditar_cambio();

CREATE OR REPLACE PROCEDURE mavak.insertar_servicio_mano_obra(
    p_numero_ficha_s text,
    p_descripcion_servicio text,
    p_cantidad integer,
    p_numero_ficha text,
    p_importe numeric
)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_importe IS NULL THEN
        RAISE EXCEPTION 'Ingresa el importe del servicio de mano de obra.';
    END IF;
    INSERT INTO public.servicio_mano_obra (numero_ficha_s, descripcion_servicio, cantidad, numero_ficha, importe)
    VALUES (p_numero_ficha_s, p_descripcion_servicio, p_cantidad, p_numero_ficha, p_importe);
END;
$$;

CREATE OR REPLACE PROCEDURE mavak.actualizar_servicio_mano_obra(
    p_numero_ficha_s text,
    p_descripcion_servicio text,
    p_cantidad integer,
    p_numero_ficha text,
    p_importe numeric,
    p_anterior_numero_ficha_s text
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.servicio_mano_obra
    SET numero_ficha_s = p_numero_ficha_s,
        descripcion_servicio = p_descripcion_servicio,
        cantidad = p_cantidad,
        numero_ficha = p_numero_ficha,
        importe = p_importe
    WHERE servicio_mano_obra.numero_ficha_s = p_anterior_numero_ficha_s;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El registro ya no existe.' USING ERRCODE = 'P0002';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE mavak.eliminar_servicio_mano_obra(
    p_numero_ficha_s text
)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM public.servicio_mano_obra WHERE servicio_mano_obra.numero_ficha_s = p_numero_ficha_s;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El registro ya no existe.' USING ERRCODE = 'P0002';
    END IF;
END;
$$;

COMMIT;
