import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../repositories/cliente_repository.dart';
import '../repositories/revista_repository.dart';
import '../repositories/empleado_repository.dart';
import '../repositories/suscripcion_repository.dart';
import '../repositories/entrega_repository.dart';

/// Servicio especializado para la generación y exportación de reportes
/// en formatos PDF y Excel (.xlsx) para el sistema Revistas, S.A.
class ReporteService {
  final ClienteRepository _clienteRepo = ClienteRepository();
  final RevistaRepository _revistaRepo = RevistaRepository();
  final EmpleadoRepository _empleadoRepo = EmpleadoRepository();
  final SuscripcionRepository _suscripcionRepo = SuscripcionRepository();
  final EntregaRepository _entregaRepo = EntregaRepository();

  final _formatoFechaHora = DateFormat('dd/MM/yyyy HH:mm');
  final _formatoFecha = DateFormat('dd/MM/yyyy');

  String _formatearFecha(String? fechaIso) {
    if (fechaIso == null || fechaIso.trim().isEmpty) return '-';
    try {
      return _formatoFecha.format(DateTime.parse(fechaIso));
    } catch (_) {
      return fechaIso;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. REPORTE GENERAL EN PDF
  // ═══════════════════════════════════════════════════════════════════════════

  /// Genera un documento PDF exhaustivo con el estado general de la empresa:
  /// Resumen estadístico, métricas clave, suscripciones y listado de entregas.
  Future<Uint8List> generarPdfReporteGeneral() async {
    final pdf = pw.Document();

    final clientes = await _clienteRepo.obtenerTodos();
    final revistas = await _revistaRepo.obtenerTodas();
    final empleados = await _empleadoRepo.obtenerTodos();
    final suscripciones = await _suscripcionRepo.obtenerTodas();
    final entregas = await _entregaRepo.obtenerTodas();
    final stats = await _entregaRepo.obtenerEstadisticas();

    final fechaEmision = _formatoFechaHora.format(DateTime.now());

    final azulPrimario = PdfColor.fromInt(0xFF1565C0);
    final azulOscuro = PdfColor.fromInt(0xFF0D47A1);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _construirEncabezadoPdf(
          titulo: 'REPORTE GENERAL DEL SISTEMA',
          subtitulo: 'Informe Ejecutivo de Operaciones y Entregas',
          fechaEmision: fechaEmision,
          colorPrimario: azulPrimario,
        ),
        footer: (context) => _construirPiePaginaPdf(context),
        build: (context) => [
          pw.SizedBox(height: 16),

          // ── Resumen Ejecutivo (KPIs) ──
          pw.Text(
            '1. Resumen Estadístico',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: azulOscuro,
            ),
          ),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: azulPrimario),
                children: [
                  _celdaCabeceraPdf('Métrica / Módulo'),
                  _celdaCabeceraPdf('Cantidad Registrada'),
                  _celdaCabeceraPdf('Estado General'),
                ],
              ),
              _filaKpiPdf('Clientes Registrados', '${clientes.length}', 'Activos en catálogo'),
              _filaKpiPdf('Revistas Publicadas', '${revistas.length}', 'Títulos disponibles'),
              _filaKpiPdf('Personal de Reparto', '${empleados.length}', 'Mensajeros asignados'),
              _filaKpiPdf('Suscripciones Activas', '${suscripciones.length}', 'Contratos vigentes'),
              _filaKpiPdf('Entregas Realizadas', '${stats['realizadas'] ?? 0}', 'Entregadas con éxito', colorTexto: PdfColors.green800),
              _filaKpiPdf('Entregas Pendientes', '${stats['pendientes'] ?? 0}', 'En proceso de ruta', colorTexto: PdfColors.orange800),
              _filaKpiPdf('Entregas Atrasadas', '${stats['atrasadas'] ?? 0}', 'Requieren atención', colorTexto: PdfColors.red800),
            ],
          ),

          pw.SizedBox(height: 20),

          // ── Detalle de Suscripciones ──
          pw.Text(
            '2. Suscripciones Vigentes (${suscripciones.length})',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: azulOscuro,
            ),
          ),
          pw.SizedBox(height: 8),

          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerDecoration: pw.BoxDecoration(color: azulPrimario),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            headers: ['No. Suscripción', 'Cliente', 'Revista', 'Vigencia Inicio', 'Vigencia Fin'],
            data: suscripciones.map((s) => [
              s.numeroSuscripcion,
              s.clienteNombre ?? '-',
              s.revistaNombre ?? '-',
              _formatearFecha(s.fechaInicio),
              _formatearFecha(s.fechaFin),
            ]).toList(),
          ),

          pw.SizedBox(height: 20),

          // ── Detalle de Entregas ──
          pw.Text(
            '3. Control y Estado de Entregas (${entregas.length})',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: azulOscuro,
            ),
          ),
          pw.SizedBox(height: 8),

          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerDecoration: pw.BoxDecoration(color: azulPrimario),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8.5,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            headers: [
              'No. Envío',
              'Suscripción',
              'Cliente',
              'Revista',
              'Repartidor',
              'F. Prog.',
              'F. Entrega',
              'Estado'
            ],
            data: entregas.map((e) {
              final estado = e.esRealizada
                  ? 'Realizada'
                  : (e.esAtrasada ? 'Atrasada' : 'Pendiente');
              return [
                e.numeroEnvio,
                e.suscripcionNumero ?? '-',
                e.clienteNombre ?? '-',
                e.revistaNombre ?? '-',
                e.empleadoNombre ?? '-',
                _formatearFecha(e.fechaProgramada),
                _formatearFecha(e.fechaEntrega),
                estado,
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. REPORTE GENERAL EN EXCEL (.xlsx)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Genera un archivo Excel (.xlsx) completo con múltiples hojas:
  /// Resumen, Clientes, Revistas, Empleados, Suscripciones y Entregas.
  Future<List<int>> generarExcelReporteGeneral() async {
    final excel = Excel.createExcel();

    // Renombrar la hoja por defecto
    const hojaResumen = 'Resumen Ejecutivo';
    excel.rename('Sheet1', hojaResumen);
    final sheetResumen = excel[hojaResumen];

    final clientes = await _clienteRepo.obtenerTodos();
    final revistas = await _revistaRepo.obtenerTodas();
    final empleados = await _empleadoRepo.obtenerTodos();
    final suscripciones = await _suscripcionRepo.obtenerTodas();
    final entregas = await _entregaRepo.obtenerTodas();
    final stats = await _entregaRepo.obtenerEstadisticas();

    final fechaEmision = _formatoFechaHora.format(DateTime.now());

    // ── Hoja 1: Resumen ──
    _escribirTituloExcel(sheetResumen, 'REVISTAS, S.A. - REPORTE GENERAL DEL SISTEMA', fechaEmision);
    _escribirCabeceraExcel(sheetResumen, 3, ['Módulo / Métrica', 'Valor', 'Descripción']);

    sheetResumen.appendRow([TextCellValue('Total de Clientes'), IntCellValue(clientes.length), TextCellValue('Clientes registrados en el sistema')]);
    sheetResumen.appendRow([TextCellValue('Total de Revistas'), IntCellValue(revistas.length), TextCellValue('Títulos de revistas disponibles')]);
    sheetResumen.appendRow([TextCellValue('Total de Empleados'), IntCellValue(empleados.length), TextCellValue('Personal de entrega activo')]);
    sheetResumen.appendRow([TextCellValue('Total de Suscripciones'), IntCellValue(suscripciones.length), TextCellValue('Suscripciones activas')]);
    sheetResumen.appendRow([TextCellValue('Entregas Realizadas'), IntCellValue(stats['realizadas'] ?? 0), TextCellValue('Entregas completadas y confirmadas')]);
    sheetResumen.appendRow([TextCellValue('Entregas Pendientes'), IntCellValue(stats['pendientes'] ?? 0), TextCellValue('Entregas pendientes en ruta')]);
    sheetResumen.appendRow([TextCellValue('Entregas Atrasadas'), IntCellValue(stats['atrasadas'] ?? 0), TextCellValue('Entregas pendientes vencidas')]);

    // ── Hoja 2: Clientes ──
    final sheetClientes = excel['Clientes'];
    _escribirTituloExcel(sheetClientes, 'CATÁLOGO DE CLIENTES', fechaEmision);
    _escribirCabeceraExcel(sheetClientes, 3, ['ID', 'NIT', 'Nombre del Cliente', 'Dirección', 'Teléfono']);
    for (final c in clientes) {
      sheetClientes.appendRow([
        IntCellValue(c.id ?? 0),
        TextCellValue(c.nit),
        TextCellValue(c.nombre),
        TextCellValue(c.direccion ?? '-'),
        TextCellValue(c.telefono ?? '-'),
      ]);
    }

    // ── Hoja 3: Revistas ──
    final sheetRevistas = excel['Revistas'];
    _escribirTituloExcel(sheetRevistas, 'CATÁLOGO DE REVISTAS', fechaEmision);
    _escribirCabeceraExcel(sheetRevistas, 3, ['ID', 'Nombre de la Revista']);
    for (final r in revistas) {
      sheetRevistas.appendRow([
        IntCellValue(r.id ?? 0),
        TextCellValue(r.nombre),
      ]);
    }

    // ── Hoja 4: Empleados ──
    final sheetEmpleados = excel['Empleados'];
    _escribirTituloExcel(sheetEmpleados, 'PERSONAL DE ENTREGA / MENSAJEROS', fechaEmision);
    _escribirCabeceraExcel(sheetEmpleados, 3, ['ID', 'Nombre Completo']);
    for (final emp in empleados) {
      sheetEmpleados.appendRow([
        IntCellValue(emp.id ?? 0),
        TextCellValue(emp.nombre),
      ]);
    }

    // ── Hoja 5: Suscripciones ──
    final sheetSuscripciones = excel['Suscripciones'];
    _escribirTituloExcel(sheetSuscripciones, 'REGISTRO DE SUSCRIPCIONES', fechaEmision);
    _escribirCabeceraExcel(sheetSuscripciones, 3, ['ID', 'No. Suscripción', 'Cliente', 'Revista', 'Fecha Inicio', 'Fecha Fin']);
    for (final s in suscripciones) {
      sheetSuscripciones.appendRow([
        IntCellValue(s.id ?? 0),
        TextCellValue(s.numeroSuscripcion),
        TextCellValue(s.clienteNombre ?? '-'),
        TextCellValue(s.revistaNombre ?? '-'),
        TextCellValue(_formatearFecha(s.fechaInicio)),
        TextCellValue(_formatearFecha(s.fechaFin)),
      ]);
    }

    // ── Hoja 6: Entregas ──
    final sheetEntregas = excel['Entregas'];
    _escribirTituloExcel(sheetEntregas, 'CONTROL Y REGISTRO DE ENTREGAS', fechaEmision);
    _escribirCabeceraExcel(sheetEntregas, 3, [
      'ID',
      'No. Envío',
      'Suscripción',
      'Cliente',
      'Revista',
      'Empleado Asignado',
      'Fecha Programada',
      'Fecha Entrega',
      'Estado',
      'Observaciones'
    ]);
    for (final e in entregas) {
      final estado = e.esRealizada
          ? 'Realizada'
          : (e.esAtrasada ? 'Atrasada' : 'Pendiente');
      sheetEntregas.appendRow([
        IntCellValue(e.id ?? 0),
        TextCellValue(e.numeroEnvio),
        TextCellValue(e.suscripcionNumero ?? '-'),
        TextCellValue(e.clienteNombre ?? '-'),
        TextCellValue(e.revistaNombre ?? '-'),
        TextCellValue(e.empleadoNombre ?? '-'),
        TextCellValue(_formatearFecha(e.fechaProgramada)),
        TextCellValue(_formatearFecha(e.fechaEntrega)),
        TextCellValue(estado),
        TextCellValue(e.observaciones ?? '-'),
      ]);
    }

    return excel.save() ?? [];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. REPORTES ESPECÍFICOS EN PDF
  // ═══════════════════════════════════════════════════════════════════════════

  /// Genera un reporte PDF enfocado exclusivamente en la entidad seleccionada.
  Future<Uint8List> generarPdfEspecifico(String tipo) async {
    final pdf = pw.Document();
    final fechaEmision = _formatoFechaHora.format(DateTime.now());
    final azulPrimario = PdfColor.fromInt(0xFF1565C0);

    switch (tipo.toLowerCase()) {
      case 'clientes':
        final clientes = await _clienteRepo.obtenerTodos();
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.all(32),
            header: (_) => _construirEncabezadoPdf(
              titulo: 'REPORTE ESPECÍFICO DE CLIENTES',
              subtitulo: 'Padrón Oficial de Clientes Registrados',
              fechaEmision: fechaEmision,
              colorPrimario: azulPrimario,
            ),
            footer: (ctx) => _construirPiePaginaPdf(ctx),
            build: (_) => [
              pw.SizedBox(height: 12),
              pw.Text('Total de clientes registrados: ${clientes.length}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerDecoration: pw.BoxDecoration(color: azulPrimario),
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headers: ['No.', 'NIT', 'Nombre Completo', 'Dirección de Entrega', 'Teléfono'],
                data: List.generate(clientes.length, (i) {
                  final c = clientes[i];
                  return ['${i + 1}', c.nit, c.nombre, c.direccion ?? '-', c.telefono ?? '-'];
                }),
              ),
            ],
          ),
        );
        break;

      case 'revistas':
        final revistas = await _revistaRepo.obtenerTodas();
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.all(32),
            header: (_) => _construirEncabezadoPdf(
              titulo: 'REPORTE ESPECÍFICO DE REVISTAS',
              subtitulo: 'Catálogo de Publicaciones Vigentes',
              fechaEmision: fechaEmision,
              colorPrimario: azulPrimario,
            ),
            footer: (ctx) => _construirPiePaginaPdf(ctx),
            build: (_) => [
              pw.SizedBox(height: 12),
              pw.Text('Total de títulos disponibles: ${revistas.length}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerDecoration: pw.BoxDecoration(color: azulPrimario),
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headers: ['Código ID', 'Nombre del Título / Revista'],
                data: revistas.map((r) => ['#${r.id}', r.nombre]).toList(),
              ),
            ],
          ),
        );
        break;

      case 'empleados':
        final empleados = await _empleadoRepo.obtenerTodos();
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.all(32),
            header: (_) => _construirEncabezadoPdf(
              titulo: 'REPORTE ESPECÍFICO DE EMPLEADOS',
              subtitulo: 'Personal Encargado de Entregas y Reparto',
              fechaEmision: fechaEmision,
              colorPrimario: azulPrimario,
            ),
            footer: (ctx) => _construirPiePaginaPdf(ctx),
            build: (_) => [
              pw.SizedBox(height: 12),
              pw.Text('Total de empleados registrados: ${empleados.length}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerDecoration: pw.BoxDecoration(color: azulPrimario),
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headers: ['ID Empleado', 'Nombre Completo del Repartidor'],
                data: empleados.map((e) => ['EMP-${(e.id ?? 0).toString().padLeft(3, '0')}', e.nombre]).toList(),
              ),
            ],
          ),
        );
        break;

      case 'suscripciones':
        final suscripciones = await _suscripcionRepo.obtenerTodas();
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.all(32),
            header: (_) => _construirEncabezadoPdf(
              titulo: 'REPORTE ESPECÍFICO DE SUSCRIPCIONES',
              subtitulo: 'Registro de Contratos por Revista y Cliente',
              fechaEmision: fechaEmision,
              colorPrimario: azulPrimario,
            ),
            footer: (ctx) => _construirPiePaginaPdf(ctx),
            build: (_) => [
              pw.SizedBox(height: 12),
              pw.Text('Total de suscripciones activas: ${suscripciones.length}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerDecoration: pw.BoxDecoration(color: azulPrimario),
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headers: ['No. Suscripción', 'Cliente', 'Revista Asignada', 'Fecha Inicio', 'Fecha Finalización'],
                data: suscripciones.map((s) => [
                  s.numeroSuscripcion,
                  s.clienteNombre ?? '-',
                  s.revistaNombre ?? '-',
                  _formatearFecha(s.fechaInicio),
                  _formatearFecha(s.fechaFin),
                ]).toList(),
              ),
            ],
          ),
        );
        break;

      case 'entregas':
      default:
        final entregas = await _entregaRepo.obtenerTodas();
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.letter,
            orientation: pw.PageOrientation.landscape,
            margin: const pw.EdgeInsets.all(28),
            header: (_) => _construirEncabezadoPdf(
              titulo: 'REPORTE ESPECÍFICO DE ENTREGAS',
              subtitulo: 'Bitácora Detallada de Despacho y Entrega',
              fechaEmision: fechaEmision,
              colorPrimario: azulPrimario,
            ),
            footer: (ctx) => _construirPiePaginaPdf(ctx),
            build: (_) => [
              pw.SizedBox(height: 12),
              pw.Text('Total de envíos registrados: ${entregas.length}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerDecoration: pw.BoxDecoration(color: azulPrimario),
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                headers: [
                  'No. Envío',
                  'Suscripción',
                  'Cliente',
                  'Revista',
                  'Empleado Repartidor',
                  'F. Programada',
                  'F. Entrega',
                  'Estado',
                  'Observaciones'
                ],
                data: entregas.map((e) {
                  final estado = e.esRealizada
                      ? 'Realizada'
                      : (e.esAtrasada ? 'Atrasada' : 'Pendiente');
                  return [
                    e.numeroEnvio,
                    e.suscripcionNumero ?? '-',
                    e.clienteNombre ?? '-',
                    e.revistaNombre ?? '-',
                    e.empleadoNombre ?? '-',
                    _formatearFecha(e.fechaProgramada),
                    _formatearFecha(e.fechaEntrega),
                    estado,
                    e.observaciones ?? '-',
                  ];
                }).toList(),
              ),
            ],
          ),
        );
        break;
    }

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. REPORTES ESPECÍFICOS EN EXCEL (.xlsx)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Genera un archivo Excel (.xlsx) con una sola hoja detallada de la entidad seleccionada.
  Future<List<int>> generarExcelEspecifico(String tipo) async {
    final excel = Excel.createExcel();
    final fechaEmision = _formatoFechaHora.format(DateTime.now());

    switch (tipo.toLowerCase()) {
      case 'clientes':
        final clientes = await _clienteRepo.obtenerTodos();
        excel.rename('Sheet1', 'Clientes');
        final sheet = excel['Clientes'];
        _escribirTituloExcel(sheet, 'REVISTAS, S.A. - CATÁLOGO DE CLIENTES', fechaEmision);
        _escribirCabeceraExcel(sheet, 3, ['ID', 'NIT', 'Nombre del Cliente', 'Dirección', 'Teléfono']);
        for (final c in clientes) {
          sheet.appendRow([
            IntCellValue(c.id ?? 0),
            TextCellValue(c.nit),
            TextCellValue(c.nombre),
            TextCellValue(c.direccion ?? '-'),
            TextCellValue(c.telefono ?? '-'),
          ]);
        }
        break;

      case 'revistas':
        final revistas = await _revistaRepo.obtenerTodas();
        excel.rename('Sheet1', 'Revistas');
        final sheet = excel['Revistas'];
        _escribirTituloExcel(sheet, 'REVISTAS, S.A. - CATÁLOGO DE REVISTAS', fechaEmision);
        _escribirCabeceraExcel(sheet, 3, ['ID', 'Nombre de la Revista']);
        for (final r in revistas) {
          sheet.appendRow([
            IntCellValue(r.id ?? 0),
            TextCellValue(r.nombre),
          ]);
        }
        break;

      case 'empleados':
        final empleados = await _empleadoRepo.obtenerTodos();
        excel.rename('Sheet1', 'Empleados');
        final sheet = excel['Empleados'];
        _escribirTituloExcel(sheet, 'REVISTAS, S.A. - PERSONAL DE ENTREGA', fechaEmision);
        _escribirCabeceraExcel(sheet, 3, ['ID', 'Nombre Completo del Empleado']);
        for (final emp in empleados) {
          sheet.appendRow([
            IntCellValue(emp.id ?? 0),
            TextCellValue(emp.nombre),
          ]);
        }
        break;

      case 'suscripciones':
        final suscripciones = await _suscripcionRepo.obtenerTodas();
        excel.rename('Sheet1', 'Suscripciones');
        final sheet = excel['Suscripciones'];
        _escribirTituloExcel(sheet, 'REVISTAS, S.A. - REGISTRO DE SUSCRIPCIONES', fechaEmision);
        _escribirCabeceraExcel(sheet, 3, ['ID', 'No. Suscripción', 'Cliente', 'Revista', 'Fecha Inicio', 'Fecha Fin']);
        for (final s in suscripciones) {
          sheet.appendRow([
            IntCellValue(s.id ?? 0),
            TextCellValue(s.numeroSuscripcion),
            TextCellValue(s.clienteNombre ?? '-'),
            TextCellValue(s.revistaNombre ?? '-'),
            TextCellValue(_formatearFecha(s.fechaInicio)),
            TextCellValue(_formatearFecha(s.fechaFin)),
          ]);
        }
        break;

      case 'entregas':
      default:
        final entregas = await _entregaRepo.obtenerTodas();
        excel.rename('Sheet1', 'Entregas');
        final sheet = excel['Entregas'];
        _escribirTituloExcel(sheet, 'REVISTAS, S.A. - CONTROL DE ENTREGAS', fechaEmision);
        _escribirCabeceraExcel(sheet, 3, [
          'ID',
          'No. Envío',
          'No. Suscripción',
          'Cliente',
          'Revista',
          'Empleado Asignado',
          'Fecha Programada',
          'Fecha Entrega',
          'Estado',
          'Observaciones'
        ]);
        for (final e in entregas) {
          final estado = e.esRealizada
              ? 'Realizada'
              : (e.esAtrasada ? 'Atrasada' : 'Pendiente');
          sheet.appendRow([
            IntCellValue(e.id ?? 0),
            TextCellValue(e.numeroEnvio),
            TextCellValue(e.suscripcionNumero ?? '-'),
            TextCellValue(e.clienteNombre ?? '-'),
            TextCellValue(e.revistaNombre ?? '-'),
            TextCellValue(e.empleadoNombre ?? '-'),
            TextCellValue(_formatearFecha(e.fechaProgramada)),
            TextCellValue(_formatearFecha(e.fechaEntrega)),
            TextCellValue(estado),
            TextCellValue(e.observaciones ?? '-'),
          ]);
        }
        break;
    }

    return excel.save() ?? [];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. ACCIONES DE DESCARGA, VISUALIZACIÓN Y COMPARTIR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Abre la vista previa oficial e interactiva de PDF (con soporte nativo para
  /// imprimir, guardar como archivo en el teléfono y compartir).
  Future<void> previsualizarPdf({
    required Uint8List bytes,
    required String nombreArchivo,
  }) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: nombreArchivo,
    );
  }

  /// Guarda el archivo en el almacenamiento del dispositivo y lo abre o comparte.
  Future<String> guardarArchivoEnDispositivo({
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final rutaCompleta = '${dir.path}/$nombreArchivo';
    final archivo = File(rutaCompleta);
    await archivo.writeAsBytes(bytes, flush: true);
    return rutaCompleta;
  }

  /// Comparte el archivo directamente usando la hoja nativa del sistema (WhatsApp, Drive, Gmail, etc.)
  Future<void> compartirArchivo({
    required String rutaArchivo,
    required String texto,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(rutaArchivo)],
        text: texto,
      ),
    );
  }

  /// Abre el archivo con la aplicación predeterminada del sistema (Excel, WPS, visor PDF, etc.)
  Future<OpenResult> abrirArchivo(String rutaArchivo) async {
    return await OpenFilex.open(rutaArchivo);
  }

  // ─── Métodos Auxiliares de Estilo ──────────────────────────────────────────

  pw.Widget _construirEncabezadoPdf({
    required String titulo,
    required String subtitulo,
    required String fechaEmision,
    required PdfColor colorPrimario,
  }) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'REVISTAS, S.A.',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: colorPrimario,
                ),
              ),
              pw.Text(
                titulo,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                subtitulo,
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Emisión: $fechaEmision', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Sistema Computarizado v1.0', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _construirPiePaginaPdf(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Revistas, S.A. - Documento Informativo Oficial',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _celdaCabeceraPdf(String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  pw.TableRow _filaKpiPdf(String metrica, String valor, String estado, {PdfColor? colorTexto}) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(metrica, style: const pw.TextStyle(fontSize: 8.5)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: colorTexto ?? PdfColors.black,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            estado,
            style: pw.TextStyle(fontSize: 8, color: colorTexto ?? PdfColors.grey700),
          ),
        ),
      ],
    );
  }

  void _escribirTituloExcel(Sheet sheet, String titulo, String fechaEmision) {
    final cellTitulo = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    cellTitulo.value = TextCellValue(titulo);
    cellTitulo.cellStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.blue,
    );

    final cellFecha = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    cellFecha.value = TextCellValue('Fecha de Emisión: $fechaEmision | Sistema Revistas, S.A.');
  }

  void _escribirCabeceraExcel(Sheet sheet, int rowIndex, List<String> encabezados) {
    for (int col = 0; col < encabezados.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
      cell.value = TextCellValue(encabezados[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
      );
    }
  }
}
