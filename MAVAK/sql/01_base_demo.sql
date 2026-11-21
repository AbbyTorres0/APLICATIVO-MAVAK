BEGIN;
--
-- PostgreSQL database dump
--


-- Dumped from database version 17.11
-- Dumped by pg_dump version 18.4

-- Started on 2026-10-24 11:51:01

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 221 (class 1259 OID 16440)
-- Name: comprobante; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comprobante (
    numero_comprobante character varying(20) NOT NULL,
    tipo_comprobante character varying(10) NOT NULL,
    condicion_pago character varying(10) NOT NULL,
    ruc character(11) NOT NULL,
    numero_ficha character varying(20) NOT NULL,
    CONSTRAINT comprobante_condicion_pago_check CHECK (((condicion_pago)::text = ANY ((ARRAY['Contado'::character varying, 'Crédito'::character varying])::text[]))),
    CONSTRAINT comprobante_tipo_comprobante_check CHECK (((tipo_comprobante)::text = ANY ((ARRAY['Boleta'::character varying, 'Factura'::character varying])::text[])))
);



--
-- TOC entry 218 (class 1259 OID 16397)
-- Name: proveedor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.proveedor (
    ruc character(11) NOT NULL,
    razon_social character varying(100) NOT NULL,
    provincia character varying(60),
    avenida character varying(100),
    numero character varying(20),
    CONSTRAINT proveedor_ruc_check CHECK ((ruc ~ '^[0-9]{11}$'::text))
);



--
-- TOC entry 219 (class 1259 OID 16403)
-- Name: proveedor_telefono; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.proveedor_telefono (
    ruc character(11) NOT NULL,
    telefono character varying(15) NOT NULL,
    CONSTRAINT proveedor_telefono_telefono_check CHECK (((telefono)::text ~ '^[0-9]{7,15}$'::text))
);



--
-- TOC entry 220 (class 1259 OID 16414)
-- Name: reparacion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reparacion (
    numero_ficha character varying(20) NOT NULL,
    numero_orden_trabajo character varying(20) NOT NULL,
    tipo_mantenimiento character varying(10) NOT NULL,
    prioridad character varying(5) NOT NULL,
    fecha_ingreso date NOT NULL,
    fecha_salida date,
    estado_orden character varying(10) DEFAULT 'Pendiente'::character varying NOT NULL,
    falla_reportada character varying(500) NOT NULL,
    diagnostico character varying(500),
    garantia character varying(100),
    proximo_mantenimiento character varying(100),
    estado_pago character varying(10) DEFAULT 'Pendiente'::character varying NOT NULL,
    placa character varying(7) NOT NULL,
    ruc character(11) NOT NULL,
    CONSTRAINT reparacion_check CHECK (((fecha_salida IS NULL) OR (fecha_salida >= fecha_ingreso))),
    CONSTRAINT reparacion_estado_orden_check CHECK (((estado_orden)::text = ANY ((ARRAY['Pendiente'::character varying, 'En proceso'::character varying, 'Cerrada'::character varying, 'Anulada'::character varying])::text[]))),
    CONSTRAINT reparacion_estado_pago_check CHECK (((estado_pago)::text = ANY ((ARRAY['Pendiente'::character varying, 'Parcial'::character varying, 'Pagado'::character varying])::text[]))),
    CONSTRAINT reparacion_prioridad_check CHECK (((prioridad)::text = ANY ((ARRAY['Baja'::character varying, 'Media'::character varying, 'Alta'::character varying])::text[]))),
    CONSTRAINT reparacion_tipo_mantenimiento_check CHECK (((tipo_mantenimiento)::text = ANY ((ARRAY['Preventivo'::character varying, 'Correctivo'::character varying])::text[])))
);



--
-- TOC entry 222 (class 1259 OID 16457)
-- Name: repuesto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.repuesto (
    codigo_repuesto character varying(20) NOT NULL,
    descripcion character varying(250) NOT NULL
);



--
-- TOC entry 223 (class 1259 OID 16462)
-- Name: repuesto_utilizado; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.repuesto_utilizado (
    numero_ficha character varying(20) NOT NULL,
    codigo_repuesto character varying(20) NOT NULL,
    cantidad integer NOT NULL,
    precio_unitario numeric(10,2),
    CONSTRAINT repuesto_utilizado_cantidad_check CHECK (((cantidad >= 1) AND (cantidad <= 9999))),
    CONSTRAINT repuesto_utilizado_precio_unitario_check CHECK ((precio_unitario >= (0)::numeric))
);



--
-- TOC entry 224 (class 1259 OID 16479)
-- Name: servicio_mano_obra; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.servicio_mano_obra (
    numero_ficha_s character varying(20) NOT NULL,
    descripcion_servicio character varying(250) NOT NULL,
    cantidad integer DEFAULT 1 NOT NULL,
    numero_ficha character varying(20) NOT NULL,
    CONSTRAINT servicio_mano_obra_cantidad_check CHECK (((cantidad >= 1) AND (cantidad <= 9999)))
);



--
-- TOC entry 217 (class 1259 OID 16388)
-- Name: vehiculo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vehiculo (
    placa character varying(7) NOT NULL,
    marca character varying(30) NOT NULL,
    tipo_vehiculo character varying(30) NOT NULL,
    modelo character varying(50) NOT NULL,
    anio_fabricacion smallint NOT NULL,
    numero_chasis character(17) NOT NULL,
    kilometraje_actual numeric(12,2) NOT NULL,
    tipo_combustible character varying(10) NOT NULL,
    conductor character varying(50),
    CONSTRAINT vehiculo_anio_fabricacion_check CHECK ((anio_fabricacion >= 1900)),
    CONSTRAINT vehiculo_kilometraje_actual_check CHECK ((kilometraje_actual >= (0)::numeric))
);



--
-- TOC entry 4963 (class 0 OID 16440)
-- Dependencies: 221
-- Data for Name: comprobante; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.comprobante (numero_comprobante, tipo_comprobante, condicion_pago, ruc, numero_ficha) VALUES
    ('F010-000001', 'Factura', 'Contado', '20000000010', 'FR-0010'),
    ('F011-000001', 'Factura', 'Contado', '20000000011', 'FR-0011'),
    ('F012-000001', 'Factura', 'Crédito', '20000000012', 'FR-0012'),
    ('F011-000002', 'Factura', 'Crédito', '20000000011', 'FR-0013');


--
-- TOC entry 4960 (class 0 OID 16397)
-- Dependencies: 218
-- Data for Name: proveedor; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.proveedor (ruc, razon_social, provincia, avenida, numero) VALUES
    ('20000000010', 'Taller de prueba MAVAK', 'Arequipa', 'Avenida de prueba', '150'),
    ('20000000011', 'Taller de prueba Motor Diesel', 'Arequipa', 'Avenida de prueba Industrial', '210'),
    ('20000000012', 'Taller de prueba Servicio Integral', 'Islay', 'Avenida de prueba del Transporte', '320');


--
-- TOC entry 4961 (class 0 OID 16403)
-- Dependencies: 219
-- Data for Name: proveedor_telefono; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.proveedor_telefono (ruc, telefono) VALUES
    ('20000000010', '900000010'),
    ('20000000011', '900000011'),
    ('20000000012', '900000012');


--
-- TOC entry 4962 (class 0 OID 16414)
-- Dependencies: 220
-- Data for Name: reparacion; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.reparacion (numero_ficha, numero_orden_trabajo, tipo_mantenimiento, prioridad, fecha_ingreso, fecha_salida, estado_orden, falla_reportada, diagnostico, garantia, proximo_mantenimiento, estado_pago, placa, ruc) VALUES
    ('FR-0010', 'OT-2026-0010', 'Correctivo', 'Alta', '2026-10-20', '2026-10-22', 'Cerrada', 'Desgaste de pastillas de freno', 'Reemplazo de pastillas y ajuste de frenos', '60 días', 'Revisión en 5000 km', 'Pagado', 'MVK-010', '20000000010'),
    ('FR-0011', 'OT-2026-0011', 'Preventivo', 'Media', '2026-10-21', '2026-10-22', 'Cerrada', 'Mantenimiento preventivo programado', 'Cambio de filtro de aceite', '30 días', 'Revisión en 10000 km', 'Pagado', 'MVK-011', '20000000011'),
    ('FR-0012', 'OT-2026-0012', 'Correctivo', 'Alta', '2026-10-23', NULL, 'En proceso', 'Desgaste de frenos y fuga de refrigerante', 'Cambio de pastillas y manguera de refrigeración', NULL, NULL, 'Parcial', 'MVK-012', '20000000012'),
    ('FR-0013', 'OT-2026-0013', 'Preventivo', 'Baja', '2026-10-24', NULL, 'Pendiente', 'Revisión preventiva programada', NULL, NULL, 'Revisión según diagnóstico', 'Pendiente', 'MVK-010', '20000000011');


--
-- TOC entry 4964 (class 0 OID 16457)
-- Dependencies: 222
-- Data for Name: repuesto; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.repuesto (codigo_repuesto, descripcion) VALUES
    ('REP-010', 'Pastilla de freno para volquete'),
    ('REP-011', 'Filtro de aceite para motor diésel'),
    ('REP-012', 'Manguera de refrigeración para volquete');


--
-- TOC entry 4965 (class 0 OID 16462)
-- Dependencies: 223
-- Data for Name: repuesto_utilizado; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.repuesto_utilizado (numero_ficha, codigo_repuesto, cantidad, precio_unitario) VALUES
    ('FR-0010', 'REP-010', '4', '150.00'),
    ('FR-0011', 'REP-011', '1', '95.00'),
    ('FR-0012', 'REP-010', '4', '160.00'),
    ('FR-0012', 'REP-012', '1', '180.00');


--
-- TOC entry 4966 (class 0 OID 16479)
-- Dependencies: 224
-- Data for Name: servicio_mano_obra; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.servicio_mano_obra (numero_ficha_s, descripcion_servicio, cantidad, numero_ficha) VALUES
    ('SMO-0100', 'Cambio de pastillas y ajuste de frenos', '1', 'FR-0010'),
    ('SMO-0101', 'Cambio de filtro de aceite', '1', 'FR-0011'),
    ('SMO-0102', 'Desmontaje de pastillas de freno', '1', 'FR-0012'),
    ('SMO-0103', 'Desmontaje de manguera de refrigeración', '1', 'FR-0012');


--
-- TOC entry 4959 (class 0 OID 16388)
-- Dependencies: 217
-- Data for Name: vehiculo; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.vehiculo (placa, marca, tipo_vehiculo, modelo, anio_fabricacion, numero_chasis, kilometraje_actual, tipo_combustible, conductor) VALUES
    ('MVK-010', 'Volvo', 'Volquete', 'FMX', '2022', 'YV200000000000010', '85000.00', 'Diésel', 'Conductor de prueba'),
    ('MVK-011', 'Scania', 'Volquete', 'P410', '2021', 'YS200000000000011', '110000.00', 'Diésel', 'Conductor de prueba 2'),
    ('MVK-012', 'Mercedes Benz', 'Volquete', 'Actros', '2023', 'WDB00000000000012', '65000.00', 'Diésel', 'Conductor de prueba 3');


--
-- TOC entry 4799 (class 2606 OID 16446)
-- Name: comprobante comprobante_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comprobante
    ADD CONSTRAINT comprobante_pkey PRIMARY KEY (numero_comprobante);


--
-- TOC entry 4793 (class 2606 OID 16408)
-- Name: proveedor_telefono pk_proveedor_telefono; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedor_telefono
    ADD CONSTRAINT pk_proveedor_telefono PRIMARY KEY (ruc, telefono);


--
-- TOC entry 4803 (class 2606 OID 16468)
-- Name: repuesto_utilizado pk_repuesto_utilizado; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.repuesto_utilizado
    ADD CONSTRAINT pk_repuesto_utilizado PRIMARY KEY (numero_ficha, codigo_repuesto);


--
-- TOC entry 4791 (class 2606 OID 16402)
-- Name: proveedor proveedor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedor
    ADD CONSTRAINT proveedor_pkey PRIMARY KEY (ruc);


--
-- TOC entry 4795 (class 2606 OID 16429)
-- Name: reparacion reparacion_numero_orden_trabajo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reparacion
    ADD CONSTRAINT reparacion_numero_orden_trabajo_key UNIQUE (numero_orden_trabajo);


--
-- TOC entry 4797 (class 2606 OID 16427)
-- Name: reparacion reparacion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reparacion
    ADD CONSTRAINT reparacion_pkey PRIMARY KEY (numero_ficha);


--
-- TOC entry 4801 (class 2606 OID 16461)
-- Name: repuesto repuesto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.repuesto
    ADD CONSTRAINT repuesto_pkey PRIMARY KEY (codigo_repuesto);


--
-- TOC entry 4805 (class 2606 OID 16485)
-- Name: servicio_mano_obra servicio_mano_obra_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.servicio_mano_obra
    ADD CONSTRAINT servicio_mano_obra_pkey PRIMARY KEY (numero_ficha_s);


--
-- TOC entry 4787 (class 2606 OID 16396)
-- Name: vehiculo vehiculo_numero_chasis_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehiculo
    ADD CONSTRAINT vehiculo_numero_chasis_key UNIQUE (numero_chasis);


--
-- TOC entry 4789 (class 2606 OID 16394)
-- Name: vehiculo vehiculo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehiculo
    ADD CONSTRAINT vehiculo_pkey PRIMARY KEY (placa);


--
-- TOC entry 4809 (class 2606 OID 16447)
-- Name: comprobante fk_comprobante_proveedor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comprobante
    ADD CONSTRAINT fk_comprobante_proveedor FOREIGN KEY (ruc) REFERENCES public.proveedor(ruc);


--
-- TOC entry 4810 (class 2606 OID 16452)
-- Name: comprobante fk_comprobante_reparacion; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comprobante
    ADD CONSTRAINT fk_comprobante_reparacion FOREIGN KEY (numero_ficha) REFERENCES public.reparacion(numero_ficha);


--
-- TOC entry 4807 (class 2606 OID 16435)
-- Name: reparacion fk_reparacion_proveedor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reparacion
    ADD CONSTRAINT fk_reparacion_proveedor FOREIGN KEY (ruc) REFERENCES public.proveedor(ruc);


--
-- TOC entry 4808 (class 2606 OID 16430)
-- Name: reparacion fk_reparacion_vehiculo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reparacion
    ADD CONSTRAINT fk_reparacion_vehiculo FOREIGN KEY (placa) REFERENCES public.vehiculo(placa);


--
-- TOC entry 4811 (class 2606 OID 16469)
-- Name: repuesto_utilizado fk_repuesto_utilizado_reparacion; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.repuesto_utilizado
    ADD CONSTRAINT fk_repuesto_utilizado_reparacion FOREIGN KEY (numero_ficha) REFERENCES public.reparacion(numero_ficha);


--
-- TOC entry 4812 (class 2606 OID 16474)
-- Name: repuesto_utilizado fk_repuesto_utilizado_repuesto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.repuesto_utilizado
    ADD CONSTRAINT fk_repuesto_utilizado_repuesto FOREIGN KEY (codigo_repuesto) REFERENCES public.repuesto(codigo_repuesto);


--
-- TOC entry 4813 (class 2606 OID 16486)
-- Name: servicio_mano_obra fk_servicio_reparacion; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.servicio_mano_obra
    ADD CONSTRAINT fk_servicio_reparacion FOREIGN KEY (numero_ficha) REFERENCES public.reparacion(numero_ficha);


--
-- TOC entry 4806 (class 2606 OID 16409)
-- Name: proveedor_telefono fk_telefono_proveedor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedor_telefono
    ADD CONSTRAINT fk_telefono_proveedor FOREIGN KEY (ruc) REFERENCES public.proveedor(ruc);


-- Completed on 2026-10-24 11:51:02

--
-- PostgreSQL database dump complete
--



COMMIT;
