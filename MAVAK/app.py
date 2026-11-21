"""Aplicativo de escritorio para el registro de reparaciones de MAVAK."""

import os
import tkinter as tk
from dataclasses import replace
from datetime import date
from decimal import Decimal, InvalidOperation
from tkinter import font, messagebox, ttk

import psycopg

import bd
from modelo import ENTIDADES, REPORTES


FONDO = '#0b1020'
PAPEL = '#141d30'
TINTA = '#eaf0fc'
SECUNDARIO = '#a4b2cb'
BORDE = '#2b3955'
MARINO = '#101829'
ACENTO = '#a9a4ff'
AZUL = '#364486'
CIAN = '#62e2e7'
MAGENTA = '#e58ec7'
VIOLETA = '#a99bff'
CAMPO = '#0f1728'


def franja_rgb(padre, alto=3):
    """Dibuja una franja cian, violeta y magenta con una caída suave de luz."""
    lienzo = tk.Canvas(padre, width=1, height=alto, background=PAPEL, highlightthickness=0,
                       borderwidth=0, takefocus=False)
    tonos = [tuple(canal // 257 for canal in lienzo.winfo_rgb(color))
             for color in (CIAN, VIOLETA, MAGENTA)]
    fondo = tuple(canal // 257 for canal in lienzo.winfo_rgb(PAPEL))

    def pintar(evento):
        lienzo.delete('luz')
        pasos = 96
        mitad = pasos // 2
        for i in range(pasos):
            tramo, avance = divmod(i, mitad)
            origen, destino = tonos[tramo:tramo + 2]
            fraccion = avance / (mitad - 1)
            rgb = tuple(round(a + (b - a) * fraccion) for a, b in zip(origen, destino))
            x1, x2 = i * evento.width / pasos, (i + 1) * evento.width / pasos
            for y, intensidad in enumerate((0.90, 0.64, 0.25)):
                mezcla = tuple(round(f + (c - f) * intensidad) for f, c in zip(fondo, rgb))
                color = "#{:02x}{:02x}{:02x}".format(*mezcla)
                lienzo.create_line(x1, y, x2 + 1, y, fill=color, tags='luz')

    lienzo.bind('<Configure>', pintar)
    return lienzo


def configurar_estilos(raiz):
    raiz.configure(background=FONDO)
    normal = font.nametofont('TkDefaultFont', root=raiz)
    familia = 'Segoe UI' if 'Segoe UI' in font.families(raiz) else normal.actual('family')
    normal.configure(family=familia, size=10)
    negrita = (familia, 10, 'bold')
    raiz.fuente_indicador = (familia, 24, 'bold')
    estilo = ttk.Style(raiz)
    estilo.theme_use('clam')
    estilo.configure('.', font=normal, background=FONDO, foreground=TINTA)
    estilo.configure('TFrame', background=FONDO)
    estilo.configure('Papel.TFrame', background=PAPEL)
    estilo.configure('Marino.TFrame', background=MARINO)
    estilo.configure('Acento.TFrame', background=VIOLETA)
    estilo.configure('Separador.TFrame', background=BORDE)
    estilo.configure('Monograma.TLabel', background='#25284c', foreground=CIAN,
                     font=(familia, 15, 'bold'))
    estilo.configure('Grupo.TLabel', background=MARINO, foreground=SECUNDARIO,
                     font=(familia, 9, 'bold'))
    estilo.configure('TLabel', background=FONDO, foreground=TINTA)
    estilo.configure('Marca.TLabel', background=MARINO, foreground=TINTA,
                     font=(familia, 19, 'bold'))
    estilo.configure('MarcaSecundaria.TLabel', background=MARINO, foreground=SECUNDARIO)
    estilo.configure('Titulo.TLabel', font=(familia, 25, 'bold'))
    estilo.configure('Formulario.TLabel', background=PAPEL, font=(familia, 18, 'bold'))
    estilo.configure('Estado.TLabel', background=PAPEL, foreground=SECUNDARIO)
    estilo.configure('Campo.TLabel', background=PAPEL, foreground=SECUNDARIO, font=negrita)

    estilo.configure('TButton', padding=(12, 7), background=PAPEL, bordercolor=BORDE,
                     lightcolor=PAPEL, darkcolor=PAPEL, focusthickness=1, focuscolor=CIAN)
    estilo.map('TButton', background=[('pressed', '#263251'), ('active', '#1d2943')],
               foreground=[('disabled', '#8293af')])
    estilo.configure('Principal.TButton', background=ACENTO, foreground=FONDO, bordercolor='#c3b4ff',
                     lightcolor=ACENTO, darkcolor=ACENTO, focuscolor=FONDO, font=negrita)
    estilo.map('Principal.TButton', background=[('pressed', '#908bed'), ('active', '#c6bbff')])
    estilo.configure('Eliminar.TButton', foreground='#f2a9c4')
    estilo.configure('Navegacion.TButton', anchor='w', padding=(9, 5), font=negrita,
                     background=MARINO, foreground=SECUNDARIO, bordercolor=MARINO,
                     lightcolor=MARINO, darkcolor=MARINO, focuscolor=CIAN)
    estilo.map('Navegacion.TButton', background=[('pressed', '#283553'), ('active', '#202b44')],
               foreground=[('active', TINTA)])
    estilo.configure('Actual.Navegacion.TButton', background='#203451', foreground=CIAN,
                     bordercolor='#396181', lightcolor='#203451', darkcolor='#203451')
    estilo.map('Actual.Navegacion.TButton', foreground=[('disabled', CIAN)])

    for componente in ('TEntry', 'TCombobox'):
        estilo.configure(componente, padding=6, fieldbackground=CAMPO, bordercolor=BORDE,
                         lightcolor=CAMPO, darkcolor=CAMPO, insertcolor=TINTA,
                         selectbackground=AZUL, selectforeground=TINTA)
        estilo.map(componente, bordercolor=[('focus', CIAN)])
    estilo.configure('TCombobox', background='#202c45', arrowcolor=TINTA)
    estilo.map('TCombobox', fieldbackground=[('readonly', CAMPO)], arrowcolor=[('readonly', TINTA)],
               selectbackground=[('readonly', CAMPO)], selectforeground=[('readonly', TINTA)],
               bordercolor=[('focus', CIAN)])
    raiz.option_add('*TCombobox*Listbox.font', normal)
    raiz.option_add('*TCombobox*Listbox.background', PAPEL)
    raiz.option_add('*TCombobox*Listbox.foreground', TINTA)
    raiz.option_add('*TCombobox*Listbox.selectBackground', AZUL)
    raiz.option_add('*TCombobox*Listbox.selectForeground', TINTA)

    estilo.configure('Treeview', background=PAPEL, fieldbackground=PAPEL, foreground=TINTA,
                     bordercolor=BORDE, borderwidth=0, rowheight=normal.metrics('linespace') + 17)
    estilo.configure('Treeview.Heading', background='#1d2a43', foreground='#c9d8f4',
                     font=negrita, padding=(8, 9), borderwidth=0, relief='flat')
    estilo.map('Treeview.Heading', background=[('active', '#24324d')])
    estilo.map('Treeview', background=[('selected', AZUL)], foreground=[('selected', TINTA)])
    for orientacion in ('Vertical', 'Horizontal'):
        estilo.configure(f'{orientacion}.TScrollbar', arrowsize=12, background='#33415e',
                         troughcolor=CAMPO, bordercolor=PAPEL,
                         arrowcolor=SECUNDARIO, lightcolor='#33415e', darkcolor='#33415e')
        estilo.map(f'{orientacion}.TScrollbar', background=[('active', '#55688a')])


def mostrar_error(ventana, error):
    if isinstance(error, psycopg.Error):
        mensajes = {
            '23503': 'Hay registros vinculados o la referencia seleccionada ya no existe.',
            '23505': 'Ya existe un registro con ese identificador o valor único.',
            '23514': 'Un dato incumple una restricción de la base. Revisa fechas, cantidades y formatos.',
            '22001': 'Un texto supera la longitud permitida por la base de datos.',
            '22003': 'Un número supera el rango admitido.',
            '42P01': 'Falta instalar una tabla o vista. Revisa los scripts SQL del proyecto.',
            '42883': 'Falta instalar un procedimiento. Ejecuta sql/02_aplicativo.sql.',
        }
        mensaje = mensajes.get(error.sqlstate)
        if not mensaje:
            mensaje = (error.diag.message_primary or str(error)).strip()
    else:
        mensaje = str(error)
    messagebox.showerror('MAVAK', mensaje, parent=ventana)


def convertir(campo, valor):
    valor = valor.strip()
    if not valor:
        if campo.opcional:
            return None
        raise ValueError(f'Completa «{campo.etiqueta}».')
    try:
        if campo.tipo == 'date':
            fecha = date.fromisoformat(valor)
            if fecha.isoformat() != valor:
                raise ValueError
            return fecha
        if campo.tipo in ('smallint', 'integer'):
            return int(valor)
        if campo.tipo == 'numeric':
            numero = Decimal(valor.replace(',', '.'))
            if not numero.is_finite():
                raise ValueError
            return numero
    except (ValueError, InvalidOperation):
        raise ValueError(f'Revisa el formato de «{campo.etiqueta}».') from None
    return valor


class Aplicativo(ttk.Frame):
    def __init__(self, raiz, config):
        super().__init__(raiz)
        self.raiz = raiz
        self.config = config
        self.tabla = 'reparacion'
        self.reportes = False
        self.filas = []
        self.valores_visibles = []
        self.pack(fill='both', expand=True)

        lateral = ttk.Frame(self, style='Marino.TFrame', padding=(14, 12))
        lateral.pack(side='left', fill='y')
        marca = ttk.Frame(lateral, style='Marino.TFrame')
        marca.pack(fill='x', pady=(0, 8))
        ttk.Label(marca, text='M', anchor='center', width=3, style='Monograma.TLabel').pack(
            side='left', padx=(0, 9), ipady=7)
        empresa = ttk.Frame(marca, style='Marino.TFrame')
        empresa.pack(side='left')
        ttk.Label(empresa, text='MAVAK', style='Marca.TLabel').pack(anchor='w')
        ttk.Label(empresa, text='E.I.R.L.', style='MarcaSecundaria.TLabel').pack(anchor='w')

        franja_rgb(lateral).pack(fill='x', pady=(0, 10))
        ttk.Label(lateral, text='REGISTROS', style='Grupo.TLabel').pack(anchor='w', padx=9, pady=(0, 5))
        self.navegacion = {}
        for tabla, (nombre, _, _) in ENTIDADES.items():
            boton = ttk.Button(lateral, text=nombre, style='Navegacion.TButton',
                               command=lambda tabla=tabla: self.abrir_tabla(tabla))
            boton.pack(fill='x', pady=(0, 1))
            self.navegacion[tabla] = boton

        ttk.Frame(lateral, style='Separador.TFrame', height=1).pack(fill='x', pady=(5, 6))
        self.boton_reportes = ttk.Button(lateral, text='Reportes', style='Navegacion.TButton',
                                         command=self.abrir_reportes)
        self.boton_reportes.pack(fill='x')
        ttk.Label(lateral, text=f'Base de datos  ·  {config["dbname"]}',
                  style='MarcaSecundaria.TLabel', wraplength=178).pack(
                      side='bottom', anchor='w', padx=8, pady=(8, 0))

        contenido = ttk.Frame(self, padding=(20, 15))
        contenido.pack(side='left', fill='both', expand=True)
        cabecera = ttk.Frame(contenido)
        cabecera.pack(fill='x', pady=(0, 12))
        self.titulo = ttk.Label(cabecera, style='Titulo.TLabel')
        self.titulo.pack(side='left')
        ttk.Button(cabecera, text='Actualizar', width=9, command=self.cargar).pack(side='right')

        self.resumen = ttk.Frame(contenido)
        self.indicadores = []
        for indice, (rotulo, fondo, acento) in enumerate((
            ('Fichas registradas', '#132840', CIAN),
            ('Órdenes abiertas', '#222445', VIOLETA),
            ('Órdenes cerradas', '#2b203b', MAGENTA),
        )):
            self.resumen.columnconfigure(indice, weight=1, uniform='indicador')
            tarjeta = tk.Frame(self.resumen, background=fondo, highlightbackground=BORDE,
                               highlightcolor=BORDE, highlightthickness=1)
            tarjeta.grid(row=0, column=indice, sticky='nsew', padx=(0, 8) if indice < 2 else 0)
            tk.Frame(tarjeta, background=acento, width=4).pack(side='left', fill='y')
            texto = tk.Frame(tarjeta, background=fondo, padx=10, pady=5)
            texto.pack(side='left', fill='y')
            tk.Label(texto, text=rotulo, background=fondo, foreground=SECUNDARIO,
                     anchor='w', padx=0, pady=0).pack(anchor='w')
            valor = tk.Label(texto, background=fondo, foreground=acento, anchor='w',
                             font=self.raiz.fuente_indicador, padx=0, pady=0)
            valor.pack(anchor='w')
            self.indicadores.append(valor)

        self.tarjeta = tk.Frame(contenido, background=PAPEL, highlightbackground=BORDE,
                                highlightcolor=BORDE, highlightthickness=1)
        self.tarjeta.pack(fill='both', expand=True)
        franja_rgb(self.tarjeta).pack(fill='x')
        barra = ttk.Frame(self.tarjeta, style='Papel.TFrame', padding=(10, 7))
        barra.pack(fill='x')
        self.selector = ttk.Combobox(barra, state='readonly', width=26, values=[r[0] for r in REPORTES])
        self.selector.current(0)
        self.selector.bind('<<ComboboxSelected>>', lambda _: self.cambiar_reporte())

        self.busqueda = tk.StringVar()
        self.buscador = ttk.Frame(barra, style='Papel.TFrame')
        self.buscador.pack(side='left', fill='x', expand=True, padx=(0, 10))
        ttk.Label(self.buscador, text='Buscar', style='Campo.TLabel').pack(side='left', padx=(0, 7))
        campo_busqueda = ttk.Entry(self.buscador, textvariable=self.busqueda, width=12)
        campo_busqueda.pack(side='left', fill='x', expand=True)
        campo_busqueda.bind('<Escape>', lambda _: self.busqueda.set(''))

        self.acciones = ttk.Frame(barra, style='Papel.TFrame')
        self.nuevo = ttk.Button(self.acciones, text='+ Nuevo', width=8, style='Principal.TButton',
                                command=lambda: self.formulario(False))
        self.nuevo.pack(side='left', padx=(0, 5))
        self.editar = ttk.Button(self.acciones, text='Editar', width=6, command=lambda: self.formulario(True))
        self.editar.pack(side='left', padx=(0, 5))
        self.borrar = ttk.Button(self.acciones, text='Eliminar', width=7, style='Eliminar.TButton',
                                 command=self.eliminar)
        self.borrar.pack(side='left')

        cuerpo = ttk.Frame(self.tarjeta, style='Papel.TFrame')
        cuerpo.pack(fill='both', expand=True, padx=1, pady=(0, 1))
        cuerpo.rowconfigure(0, weight=1)
        cuerpo.columnconfigure(0, weight=1)
        self.grilla = ttk.Treeview(cuerpo, show='headings', selectmode='browse')
        self.grilla.grid(row=0, column=0, sticky='nsew')
        vertical = ttk.Scrollbar(cuerpo, orient='vertical', command=self.grilla.yview)
        vertical.grid(row=0, column=1, sticky='ns')
        horizontal = ttk.Scrollbar(cuerpo, orient='horizontal', command=self.grilla.xview)
        horizontal.grid(row=1, column=0, sticky='ew')
        self.grilla.configure(yscrollcommand=vertical.set, xscrollcommand=horizontal.set)
        self.grilla.tag_configure('alterna', background='#182339')
        self.grilla.bind('<<TreeviewSelect>>', self.actualizar_acciones)
        self.grilla.bind('<Double-1>', self.editar_fila)
        self.estado = ttk.Label(self.tarjeta, style='Estado.TLabel', padding=(10, 6))
        self.estado.pack(fill='x')
        self.fuente_tabla = font.nametofont('TkDefaultFont', root=raiz)
        self.fuente_cabecera = self.fuente_tabla.copy()
        self.fuente_cabecera.configure(weight='bold')
        self.busqueda.trace_add('write', lambda *_: self.mostrar_filas())
        self.abrir_tabla(self.tabla)

    def actualizar_acciones(self, _evento=None):
        estado = 'normal' if not self.reportes and self.grilla.selection() else 'disabled'
        self.editar.configure(state=estado)
        self.borrar.configure(state=estado)

    def editar_fila(self, evento):
        fila = self.grilla.identify_row(evento.y)
        if fila and not self.reportes:
            self.grilla.selection_set(fila)
            self.formulario(True)

    def abrir_tabla(self, tabla):
        self.reportes = False
        self.tabla = tabla
        self.cambiar_seccion()

    def abrir_reportes(self):
        self.reportes = True
        self.cambiar_seccion()

    def cambiar_reporte(self):
        self.busqueda.set('')
        self.cargar()

    def cambiar_seccion(self):
        normal = 'Navegacion.TButton'
        actual = 'Actual.Navegacion.TButton'
        for tabla, boton in self.navegacion.items():
            activo = not self.reportes and tabla == self.tabla
            boton.configure(style=actual if activo else normal, state='disabled' if activo else 'normal')
        self.boton_reportes.configure(style=actual if self.reportes else normal,
                                       state='disabled' if self.reportes else 'normal')
        self.acciones.pack_forget()
        self.selector.pack_forget()
        self.resumen.pack_forget()
        if self.reportes:
            self.selector.pack(side='right', before=self.buscador)
        else:
            self.acciones.pack(side='right', before=self.buscador)
            if self.tabla == 'reparacion':
                self.resumen.pack(fill='x', before=self.tarjeta, pady=(0, 10))
        self.busqueda.set('')
        self.cargar()

    def cargar(self):
        self.filas = []
        self.valores_visibles = []
        self.grilla.delete(*self.grilla.get_children())
        self.actualizar_acciones()
        if not self.reportes and self.tabla == 'reparacion':
            for etiqueta in self.indicadores:
                etiqueta.configure(text='—')
        try:
            if self.reportes:
                indice = self.selector.current()
                self.titulo.configure(text=REPORTES[indice][0])
                columnas, self.filas = bd.reporte(self.config, indice)
                nombres = {
                    campo.nombre: campo.etiqueta.split(' (AAAA-MM-DD)')[0]
                    for _, _, campos_entidad in ENTIDADES.values() for campo in campos_entidad
                }
                etiquetas = [nombres.get(col, col.replace('_', ' ').capitalize()) for col in columnas]
            else:
                nombre, _, campos = ENTIDADES[self.tabla]
                self.titulo.configure(text=nombre)
                columnas = [campo.nombre for campo in campos]
                etiquetas = [campo.etiqueta.split(' (AAAA-MM-DD)')[0] for campo in campos]
                self.filas = bd.listar(self.config, self.tabla)
        except psycopg.Error as error:
            self.estado.configure(text='Error al cargar los datos')
            mostrar_error(self.raiz, error)
            return

        if not self.reportes and self.tabla == 'reparacion':
            indice_estado = columnas.index('estado_orden')
            estados = [fila[indice_estado] for fila in self.filas]
            abiertas = sum(estado in ('Pendiente', 'En proceso') for estado in estados)
            for etiqueta, valor in zip(self.indicadores, (len(estados), abiertas, estados.count('Cerrada'))):
                etiqueta.configure(text=valor)
        self.valores_visibles = [
            tuple('' if valor is None else str(valor).rstrip() for valor in fila)
            for fila in self.filas
        ]
        # Las fichas abren con sus datos operativos junto al número de orden.
        if not self.reportes and self.tabla == 'reparacion':
            principales = ('numero_ficha', 'placa', 'estado_orden', 'prioridad',
                           'fecha_ingreso', 'numero_orden_trabajo')
            orden = (*principales, *(col for col in columnas if col not in principales))
        else:
            orden = columnas
        self.grilla.configure(columns=columnas, displaycolumns=orden)
        ejemplos = self.valores_visibles[:100]
        for indice, (columna, etiqueta) in enumerate(zip(columnas, etiquetas)):
            ancho_titulo = self.fuente_cabecera.measure(etiqueta) + 24
            ancho_datos = max((self.fuente_tabla.measure(fila[indice])
                               for fila in ejemplos), default=0) + 24
            ancho = max(83, ancho_titulo, min(ancho_datos, 300))
            self.grilla.heading(columna, text=etiqueta, anchor='w')
            self.grilla.column(columna, width=ancho, minwidth=ancho)
        self.grilla.xview_moveto(0)
        self.mostrar_filas()

    def mostrar_filas(self):
        termino = self.busqueda.get().strip().casefold()
        self.grilla.delete(*self.grilla.get_children())
        cantidad = 0
        for numero, fila in enumerate(self.valores_visibles):
            if termino and not any(termino in dato.casefold() for dato in fila):
                continue
            etiquetas_fila = ('alterna',) if cantidad % 2 else ()
            self.grilla.insert('', 'end', iid=str(numero), values=fila, tags=etiquetas_fila)
            cantidad += 1
        self.grilla.yview_moveto(0)
        self.actualizar_acciones()
        if termino:
            texto = f'{cantidad} de {len(self.filas)} registros'
        elif cantidad:
            texto = f'{cantidad} registro' + ('s' if cantidad != 1 else '')
        else:
            texto = 'No hay registros para mostrar.'
        self.estado.configure(text=texto)

    def seleccion(self):
        seleccion = self.grilla.selection()
        if seleccion:
            return self.filas[int(seleccion[0])]
        messagebox.showinfo('MAVAK', 'Selecciona una fila de la tabla.', parent=self.raiz)

    def clave(self, fila):
        _, claves, campos = ENTIDADES[self.tabla]
        valores = dict(zip((c.nombre for c in campos), fila))
        return tuple(str(valores[nombre]).rstrip() for nombre in claves)

    def eliminar(self):
        fila = self.seleccion()
        if fila is None:
            return
        clave = self.clave(fila)
        if messagebox.askyesno('Eliminar registro', f'¿Eliminar el registro {" / ".join(clave)}?', parent=self.raiz):
            try:
                bd.guardar(self.config, self.tabla, 'eliminar', (), clave)
            except psycopg.Error as error:
                mostrar_error(self.raiz, error)
                return
            self.cargar()

    def formulario(self, editar):
        fila = self.seleccion() if editar else None
        if editar and fila is None:
            return
        _, _, campos = ENTIDADES[self.tabla]
        if self.tabla == 'servicio_mano_obra' and not editar:
            campos = tuple(replace(c, opcional=False) if c.nombre == 'importe' else c for c in campos)
        try:
            referencias = {tabla: bd.opciones(self.config, tabla)
                           for tabla in dict.fromkeys(c.referencia for c in campos if c.referencia)}
        except psycopg.Error as error:
            mostrar_error(self.raiz, error)
            return

        ventana = tk.Toplevel(self.raiz, background=FONDO)
        titulo = 'Editar registro' if editar else 'Nuevo registro'
        ventana.title(titulo)
        ventana.transient(self.raiz)
        panel = ttk.Frame(ventana, padding=(22, 18), style='Papel.TFrame')
        panel.pack(fill='both', expand=True, padx=12, pady=12)
        columnas = 2 if len(campos) > 7 else 1
        ttk.Label(panel, text=titulo, style='Formulario.TLabel').grid(
            row=0, column=0, columnspan=columnas, sticky='w', pady=(0, 11))
        for columna in range(columnas):
            panel.columnconfigure(columna, weight=1, uniform='campo')
        variables = []
        for indice, campo in enumerate(campos):
            dato = fila[indice] if editar else campo.inicial
            variable = tk.StringVar(ventana, '' if dato is None else str(dato).rstrip())
            variables.append(variable)
            etiqueta = campo.etiqueta + (' · opcional' if campo.opcional else '')
            renglon, columna = divmod(indice, columnas)
            grupo = ttk.Frame(panel, style='Papel.TFrame')
            grupo.grid(row=renglon + 1, column=columna, sticky='ew',
                       padx=(0, 14) if columnas == 2 and columna == 0 else 0, pady=(0, 6))
            ttk.Label(grupo, text=etiqueta, style='Campo.TLabel').pack(anchor='w', pady=(0, 2))
            if campo.referencia or campo.opciones:
                opciones = referencias[campo.referencia] if campo.referencia else campo.opciones
                entrada = ttk.Combobox(grupo, textvariable=variable, values=opciones,
                                        state='readonly', width=28)
            else:
                entrada = ttk.Entry(grupo, textvariable=variable, width=31)
            entrada.pack(fill='x')
            if indice == 0:
                primero = entrada

        def guardar():
            try:
                valores = tuple(convertir(c, v.get()) for c, v in zip(campos, variables))
                bd.guardar(self.config, self.tabla, 'actualizar' if editar else 'insertar',
                           valores, self.clave(fila) if editar else ())
            except (ValueError, psycopg.Error) as error:
                mostrar_error(ventana, error)
                return
            ventana.destroy()
            self.cargar()

        acciones = ttk.Frame(panel)
        acciones.configure(style='Papel.TFrame')
        ultima_fila = (len(campos) - 1) // columnas + 2
        acciones.grid(row=ultima_fila, column=0, columnspan=columnas, sticky='e', pady=(10, 0))
        ttk.Button(acciones, text='Cancelar', command=ventana.destroy).pack(side='left', padx=6)
        ttk.Button(acciones, text='Guardar', style='Principal.TButton', command=guardar).pack(side='left')
        ventana.bind('<Escape>', lambda _: ventana.destroy())
        ventana.update_idletasks()
        ancho, alto = ventana.winfo_reqwidth(), ventana.winfo_reqheight()
        x = self.raiz.winfo_rootx() + (self.raiz.winfo_width() - ancho) // 2
        y = self.raiz.winfo_rooty() + (self.raiz.winfo_height() - alto) // 2
        ventana.geometry(f'+{max(x, 0)}+{max(y, 0)}')
        ventana.wait_visibility()
        ventana.grab_set()
        primero.focus_set()


def dibujar_volquete(lienzo):
    """Dibuja una vista lateral del volquete y la ajusta al tamaño del panel."""
    lienzo.delete('all')
    ancho, alto = lienzo.winfo_width(), lienzo.winfo_height()
    escala = min(ancho / 360, alto / 210)
    if escala < 0.1:
        return
    inicio_x = (ancho - 360 * escala) / 2
    inicio_y = (alto - 210 * escala) / 2

    def puntos(coordenadas):
        return [
            (inicio_y if i % 2 else inicio_x) + valor * escala
            for i, valor in enumerate(coordenadas)
        ]

    def linea(*coordenadas, color='#66849e', grosor=1):
        lienzo.create_line(*puntos(coordenadas), fill=color, width=max(1, grosor * escala),
                           capstyle='round', joinstyle='round')

    def forma(*coordenadas, relleno, borde='', grosor=1):
        lienzo.create_polygon(*puntos(coordenadas), fill=relleno, outline=borde,
                             width=max(1, grosor * escala), joinstyle='round')

    fondo = tuple(canal // 257 for canal in lienzo.winfo_rgb(MARINO))
    for centro_x, centro_y, color in ((106, 101, (64, 187, 251)), (265, 105, (167, 113, 255))):
        for radio in range(90, 0, -3):
            intensidad = ((90 - radio) / 90) ** 2 * 0.28
            canales = (round(base + (tinte - base) * intensidad) for base, tinte in zip(fondo, color))
            relleno = '#{:02x}{:02x}{:02x}'.format(*canales)
            lienzo.create_oval(*puntos((centro_x - radio, centro_y - radio * 0.83,
                                      centro_x + radio, centro_y + radio * 0.83)),
                              fill=relleno, outline='')

    for x in range(20, 350, 24):
        linea(x, 23, x, 177, color='#26364e')
    for y in range(23, 178, 22):
        linea(20, y, 338, y, color='#26364e')
    linea(20, 177, 339, 177, color='#405575')
    for x in (20, 338):
        linea(x, 186, x, 192, color='#405575')
    linea(20, 189, 338, 189, color='#405575')

    forma(48, 135, 313, 135, 313, 152, 48, 152, relleno='#283c58')
    forma(65, 117, 206, 117, 229, 102, 229, 137, 62, 137,
          relleno='#3a4b71')
    forma(228, 134, 228, 67, 280, 67, 312, 108, 312, 145, 228, 145,
          relleno='#26344f', borde='#83b7ed', grosor=2)
    forma(244, 79, 274, 79, 296, 107, 244, 107, relleno='#5d87af')
    linea(242, 114, 242, 131, color='#7c96cc')
    linea(251, 118, 260, 118, color='#b1c4d5')
    linea(312, 119, 312, 130, color='#77dcff', grosor=2)

    forma(41, 78, 220, 78, 204, 125, 77, 125, relleno='#283447',
          borde='#818ddd', grosor=2)
    forma(35, 73, 222, 73, 223, 80, 40, 80, relleno='#365684')
    for i, color in enumerate(('#6be1ff', '#74ccff', '#82baff', '#92a7ff', '#a89bff', '#c18eff')):
        x = 40 + i * 30
        linea(x, 75, x + 30, 75, color=color, grosor=3)
    for x in (76, 109, 142, 175):
        linea(x, 88, x + 12, 115, color='#6778b0', grosor=1.5)
    for x in (82, 136, 280):
        lienzo.create_oval(*puntos((x - 20, 137, x + 20, 177)),
                          fill=MARINO, outline='#8298bb', width=max(1, 2 * escala))
        lienzo.create_oval(*puntos((x - 8, 149, x + 8, 165)),
                          fill='#5f78a3', outline='')


def iniciar():
    raiz = tk.Tk()
    raiz.title('MAVAK | Registro de reparaciones')
    raiz.geometry('1180x690')
    raiz.minsize(900, 530)
    configurar_estilos(raiz)

    estilo = ttk.Style(raiz)
    familia = font.nametofont('TkDefaultFont', root=raiz).actual('family')
    fuente_titulo = font.Font(root=raiz, family=familia, size=32, weight='bold')
    estilo.configure('InicioMarca.TLabel', background=MARINO, foreground='#86dfff',
                     font=(familia, 13, 'bold'))
    estilo.configure('InicioTitulo.TLabel', background=MARINO, foreground=TINTA,
                     font=fuente_titulo)
    estilo.configure('InicioAyuda.TLabel', background=PAPEL, foreground=SECUNDARIO)

    pantalla = ttk.Frame(raiz)
    pantalla.pack(fill='both', expand=True)
    pantalla.rowconfigure(0, weight=1)
    pantalla.columnconfigure(0, weight=44, uniform='inicio')
    pantalla.columnconfigure(1, weight=56, uniform='inicio')

    marca = ttk.Frame(pantalla, style='Marino.TFrame')
    marca.grid(row=0, column=0, sticky='nsew')
    hero = ttk.Frame(marca, style='Marino.TFrame', padding=(35, 18))
    hero.place(relx=0, rely=0.5, anchor='w', relwidth=1)
    ttk.Label(hero, text='MAVAK E.I.R.L.', style='InicioMarca.TLabel').pack(anchor='w')
    ttk.Label(hero, text='Registro de\nreparaciones', style='InicioTitulo.TLabel',
              justify='left').pack(anchor='w', pady=(14, 5))
    ttk.Label(hero, text='Flota de volquetes', style='MarcaSecundaria.TLabel').pack(anchor='w')
    ancho_titulo = max(fuente_titulo.measure(linea) for linea in ('Registro de', 'reparaciones'))

    def ajustar_titulo(evento):
        espacio_disponible = max(1, evento.width - 72)
        medida = min(32, max(18, 32 * espacio_disponible // ancho_titulo))
        if medida != fuente_titulo.cget('size'):
            fuente_titulo.configure(size=medida)

    hero.bind('<Configure>', ajustar_titulo)
    lienzo = tk.Canvas(hero, height=204, background=MARINO, highlightthickness=0,
                       borderwidth=0, takefocus=False)
    lienzo.pack(fill='x', pady=(23, 0))
    lienzo.bind('<Configure>', lambda _: dibujar_volquete(lienzo))

    espacio = ttk.Frame(pantalla, padding=(22, 14))
    espacio.grid(row=0, column=1, sticky='nsew')
    borde = tk.Frame(espacio, background=PAPEL, highlightbackground=BORDE,
                     highlightcolor=BORDE, highlightthickness=1)
    borde.pack(expand=True)
    franja_rgb(borde, alto=3).pack(fill='x')
    conexion = ttk.Frame(borde, padding=(29, 24), style='Papel.TFrame')
    conexion.pack(fill='both', expand=True)
    conexion.columnconfigure(0, weight=1, uniform='conexion')
    conexion.columnconfigure(1, weight=1, uniform='conexion')
    ttk.Label(conexion, text='Conexión a PostgreSQL', style='Formulario.TLabel', wraplength=350).grid(
        row=0, column=0, columnspan=2, sticky='w')
    ttk.Label(conexion, text='Ingresa los datos de la conexión que usas en pgAdmin.',
              style='InicioAyuda.TLabel', wraplength=350).grid(
        row=1, column=0, columnspan=2, sticky='w', pady=(4, 18))

    campos = (
        ('host', 'Servidor', 'PGHOST', 'localhost'),
        ('port', 'Puerto', 'PGPORT', '5432'),
        ('dbname', 'Base de datos', 'PGDATABASE', 'mavak'),
        ('user', 'Usuario', 'PGUSER', 'postgres'),
        ('password', 'Contraseña', 'PGPASSWORD', ''),
    )
    variables = {}
    for indice, (nombre, etiqueta, entorno, defecto) in enumerate(campos):
        fila, columna = divmod(indice, 2)
        contrasena = nombre == 'password'
        grupo = ttk.Frame(conexion, style='Papel.TFrame')
        grupo.grid(row=fila + 2, column=columna, columnspan=2 if contrasena else 1,
                   sticky='ew', padx=(0, 13) if columna == 0 and not contrasena else 0,
                   pady=(0, 12))
        variable = tk.StringVar(raiz, os.environ.get(entorno, defecto))
        variables[nombre] = variable
        ttk.Label(grupo, text=etiqueta, style='Campo.TLabel').pack(anchor='w', pady=(0, 4))
        entrada = ttk.Entry(grupo, textvariable=variable, show='*' if contrasena else '', width=15)
        entrada.pack(fill='x')
    entrada.focus_set()

    def conectar():
        config = {nombre: variable.get() for nombre, variable in variables.items()}
        if not config['password']:
            del config['password']  # Permite que libpq use su archivo de contraseñas.
        try:
            bd.consultar(config, 'SELECT 1 FROM public.reparacion LIMIT 0')
            bd.consultar(config, 'SELECT 1 FROM mavak.costos LIMIT 0')
        except psycopg.Error as error:
            mostrar_error(raiz, error)
            return
        pantalla.destroy()
        raiz.unbind('<Return>')
        Aplicativo(raiz, config)

    ttk.Button(conexion, text='Conectar', style='Principal.TButton', command=conectar).grid(
        row=5, column=0, columnspan=2, sticky='ew', pady=(3, 0))
    raiz.bind('<Return>', lambda _: conectar())
    raiz.mainloop()


if __name__ == '__main__':
    iniciar()
