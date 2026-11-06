import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/reporte_service.dart';
import '../../database/database_helper.dart';

/// Pantalla dedicada para la generación, descarga y compartición
/// de reportes en PDF y Excel (.xlsx) del sistema Revistas, S.A.
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final ReporteService _reporteService = ReporteService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Entidad seleccionada en el desplegable de reportes específicos
  String _entidadSeleccionada = 'clientes';

  bool _generandoGeneralPdf = false;
  bool _generandoGeneralExcel = false;
  bool _generandoEspecificoPdf = false;
  bool _generandoEspecificoExcel = false;
  bool _reiniciandoDatos = false;

  final Map<String, Map<String, dynamic>> _entidadesConfig = {
    'clientes': {
      'titulo': 'Clientes',
      'subtitulo': 'Catálogo oficial con NIT, dirección y teléfonos',
      'icono': Icons.people,
      'color': Colors.blue,
    },
    'revistas': {
      'titulo': 'Revistas',
      'subtitulo': 'Catálogo completo de publicaciones registradas',
      'icono': Icons.menu_book,
      'color': Colors.teal,
    },
    'empleados': {
      'titulo': 'Empleados',
      'subtitulo': 'Personal repartidor y mensajeros del sistema',
      'icono': Icons.badge,
      'color': Colors.brown,
    },
    'suscripciones': {
      'titulo': 'Suscripciones',
      'subtitulo': 'Contratos vigentes entre clientes y revistas',
      'icono': Icons.subscriptions,
      'color': Colors.purple,
    },
    'entregas': {
      'titulo': 'Entregas',
      'subtitulo': 'Bitácora de envíos (pendientes, atrasadas y realizadas)',
      'icono': Icons.local_shipping,
      'color': Colors.orange,
    },
  };

  // ─── Generación de Reportes Generales ─────────────────────────────────────

  Future<void> _generarReporteGeneralPdf() async {
    setState(() => _generandoGeneralPdf = true);
    try {
      final pdfBytes = await _reporteService.generarPdfReporteGeneral();
      final fechaStr = DateTime.now().toIso8601String().substring(0, 10);
      final nombreArchivo = 'Reporte_General_RevistasSA_$fechaStr.pdf';

      final ruta = await _reporteService.guardarArchivoEnDispositivo(
        bytes: pdfBytes,
        nombreArchivo: nombreArchivo,
      );

      if (!mounted) return;
      _mostrarDialogoExitoPdf(
        titulo: 'Reporte General en PDF',
        rutaArchivo: ruta,
        nombreArchivo: nombreArchivo,
        bytes: pdfBytes,
      );
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al generar PDF General: $e');
      }
    } finally {
      if (mounted) setState(() => _generandoGeneralPdf = false);
    }
  }

  Future<void> _generarReporteGeneralExcel() async {
    setState(() => _generandoGeneralExcel = true);
    try {
      final excelBytes = await _reporteService.generarExcelReporteGeneral();
      final fechaStr = DateTime.now().toIso8601String().substring(0, 10);
      final nombreArchivo = 'Reporte_General_RevistasSA_$fechaStr.xlsx';

      final ruta = await _reporteService.guardarArchivoEnDispositivo(
        bytes: excelBytes,
        nombreArchivo: nombreArchivo,
      );

      if (!mounted) return;
      _mostrarDialogoExitoExcel(
        titulo: 'Reporte General en Excel',
        rutaArchivo: ruta,
        nombreArchivo: nombreArchivo,
      );
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al generar Excel General: $e');
      }
    } finally {
      if (mounted) setState(() => _generandoGeneralExcel = false);
    }
  }

  // ─── Generación de Reportes Específicos ───────────────────────────────────

  Future<void> _generarReporteEspecificoPdf() async {
    setState(() => _generandoEspecificoPdf = true);
    try {
      final pdfBytes = await _reporteService.generarPdfEspecifico(_entidadSeleccionada);
      final fechaStr = DateTime.now().toIso8601String().substring(0, 10);
      final nombreArchivo = 'Reporte_${_entidadSeleccionada.toUpperCase()}_$fechaStr.pdf';

      final ruta = await _reporteService.guardarArchivoEnDispositivo(
        bytes: pdfBytes,
        nombreArchivo: nombreArchivo,
      );

      if (!mounted) return;
      _mostrarDialogoExitoPdf(
        titulo: 'Reporte de ${_entidadesConfig[_entidadSeleccionada]?['titulo']} en PDF',
        rutaArchivo: ruta,
        nombreArchivo: nombreArchivo,
        bytes: pdfBytes,
      );
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al generar PDF específico: $e');
      }
    } finally {
      if (mounted) setState(() => _generandoEspecificoPdf = false);
    }
  }

  Future<void> _generarReporteEspecificoExcel() async {
    setState(() => _generandoEspecificoExcel = true);
    try {
      final excelBytes = await _reporteService.generarExcelEspecifico(_entidadSeleccionada);
      final fechaStr = DateTime.now().toIso8601String().substring(0, 10);
      final nombreArchivo = 'Reporte_${_entidadSeleccionada.toUpperCase()}_$fechaStr.xlsx';

      final ruta = await _reporteService.guardarArchivoEnDispositivo(
        bytes: excelBytes,
        nombreArchivo: nombreArchivo,
      );

      if (!mounted) return;
      _mostrarDialogoExitoExcel(
        titulo: 'Reporte de ${_entidadesConfig[_entidadSeleccionada]?['titulo']} en Excel',
        rutaArchivo: ruta,
        nombreArchivo: nombreArchivo,
      );
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al generar Excel específico: $e');
      }
    } finally {
      if (mounted) setState(() => _generandoEspecificoExcel = false);
    }
  }

  // ─── Recarga de Datos de Demostración ─────────────────────────────────────

  Future<void> _confirmarRecargaDatos() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('Cargar Datos de Prueba')),
          ],
        ),
        content: const Text(
          'Esta acción restablecerá la base de datos con un conjunto amplio de demostración:\n\n'
          '• 8 Clientes\n'
          '• 7 Revistas\n'
          '• 5 Empleados repartidores\n'
          '• 14 Suscripciones activas\n'
          '• 20 Entregas (8 Realizadas, 6 Pendientes y 6 Atrasadas)\n\n'
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, Cargar Datos', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _reiniciandoDatos = true);
    try {
      await _dbHelper.reiniciarConDatosDemostracion();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('¡Datos de prueba cargados con éxito!')),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al cargar datos de prueba: $e');
      }
    } finally {
      if (mounted) setState(() => _reiniciandoDatos = false);
    }
  }

  // ─── Diálogos y Notificaciones ───────────────────────────────────────────

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade800,
        content: Text(mensaje),
      ),
    );
  }

  void _mostrarDialogoExitoExcel({
    required String titulo,
    required String rutaArchivo,
    required String nombreArchivo,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Expanded(child: Text('Archivo Excel Generado')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Archivo: $nombreArchivo',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Guardado en:\n$rutaArchivo',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Compartir'),
            onPressed: () {
              Navigator.pop(ctx);
              _reporteService.compartirArchivo(
                rutaArchivo: rutaArchivo,
                texto: 'Reporte generado en Excel: $nombreArchivo',
              );
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir Excel'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
            onPressed: () {
              Navigator.pop(ctx);
              _reporteService.abrirArchivo(rutaArchivo);
            },
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoExitoPdf({
    required String titulo,
    required String rutaArchivo,
    required String nombreArchivo,
    required Uint8List bytes,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Expanded(child: Text('Documento PDF Generado')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Archivo: $nombreArchivo',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Guardado en:\n$rutaArchivo',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Imprimir'),
            onPressed: () {
              Navigator.pop(ctx);
              _reporteService.previsualizarPdf(
                bytes: bytes,
                nombreArchivo: nombreArchivo,
              );
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Compartir'),
            onPressed: () {
              Navigator.pop(ctx);
              _reporteService.compartirArchivo(
                rutaArchivo: rutaArchivo,
                texto: 'Reporte PDF generado: $nombreArchivo',
              );
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Abrir PDF'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              Navigator.pop(ctx);
              _reporteService.abrirArchivo(rutaArchivo);
            },
          ),
        ],
      ),
    );
  }

  // ─── Construcción de Interfaz ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Módulo de Reportes'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        actions: [
          IconButton(
            tooltip: 'Cargar Datos de Demostración',
            icon: _reiniciandoDatos
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            onPressed: _reiniciandoDatos ? null : _confirmarRecargaDatos,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de bienvenida
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, const Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.analytics, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Centro de Reportes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Exporta información consolidada o por catálogo en formatos PDF y Excel (.xlsx).',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ══════════════════════════════════════════════════════════════════
            // SECCIÓN 1: REPORTE GENERAL
            // ══════════════════════════════════════════════════════════════════
            _construirTituloSeccion(
              icono: Icons.summarize,
              titulo: 'Reporte General Consolidado',
              color: cs.primary,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informe Completo del Sistema',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Genera una visión 360° de la empresa: resumen estadístico de operaciones, suscripciones vigentes y la bitácora completa de entregas con sus estados.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 14),

                    // Badges de contenido incluido
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildBadge('Métricas KPI', Icons.pie_chart),
                        _buildBadge('Suscripciones', Icons.subscriptions),
                        _buildBadge('Entregas', Icons.local_shipping),
                        _buildBadge('Clientes', Icons.people),
                        _buildBadge('Revistas', Icons.menu_book),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Botones de acción Reporte General
                    Row(
                      children: [
                        // Botón PDF
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: _generandoGeneralPdf
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.picture_as_pdf),
                            label: const Text(
                              'Reporte en PDF',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: _generandoGeneralPdf || _generandoGeneralExcel
                                ? null
                                : _generarReporteGeneralPdf,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Botón Excel
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: _generandoGeneralExcel
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.table_chart),
                            label: const Text(
                              'Reporte en Excel',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: _generandoGeneralPdf || _generandoGeneralExcel
                                ? null
                                : _generarReporteGeneralExcel,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ══════════════════════════════════════════════════════════════════
            // SECCIÓN 2: REPORTES ESPECÍFICOS (DESPLEGABLE)
            // ══════════════════════════════════════════════════════════════════
            _construirTituloSeccion(
              icono: Icons.filter_alt,
              titulo: 'Reportes Específicos por Módulo',
              color: Colors.teal.shade700,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecciona el Módulo a Exportar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Elige una categoría específica desde el menú desplegable para generar su informe dedicado en PDF o Excel.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),

                    // Desplegable de selección de entidad
                    DropdownButtonFormField<String>(
                      initialValue: _entidadSeleccionada,
                      decoration: InputDecoration(
                        labelText: 'Categoría de Reporte',
                        prefixIcon: Icon(
                          _entidadesConfig[_entidadSeleccionada]?['icono'] ?? Icons.folder,
                          color: _entidadesConfig[_entidadSeleccionada]?['color'] ?? cs.primary,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _entidadesConfig.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Row(
                            children: [
                              Icon(entry.value['icono'] as IconData, size: 20, color: entry.value['color'] as Color),
                              const SizedBox(width: 10),
                              Text(
                                entry.value['titulo'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (nuevo) {
                        if (nuevo != null) {
                          setState(() => _entidadSeleccionada = nuevo);
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    // Descripción del módulo seleccionado
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: _entidadesConfig[_entidadSeleccionada]?['color'] as Color?,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _entidadesConfig[_entidadSeleccionada]?['subtitulo'] ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Botones de exportación específica
                    Row(
                      children: [
                        // PDF Específico
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade800,
                              side: BorderSide(color: Colors.red.shade700, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: _generandoEspecificoPdf
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.red.shade800, strokeWidth: 2),
                                  )
                                : const Icon(Icons.picture_as_pdf),
                            label: const Text('Descargar PDF'),
                            onPressed: _generandoEspecificoPdf || _generandoEspecificoExcel
                                ? null
                                : _generarReporteEspecificoPdf,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Excel Específico
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green.shade800,
                              side: BorderSide(color: Colors.green.shade800, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: _generandoEspecificoExcel
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.green.shade800, strokeWidth: 2),
                                  )
                                : const Icon(Icons.table_chart),
                            label: const Text('Descargar Excel'),
                            onPressed: _generandoEspecificoPdf || _generandoEspecificoExcel
                                ? null
                                : _generarReporteEspecificoExcel,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ══════════════════════════════════════════════════════════════════
            // SECCIÓN 3: GESTIÓN DE DATOS DE DEMOSTRACIÓN Y PRUEBAS
            // ══════════════════════════════════════════════════════════════════
            _construirTituloSeccion(
              icono: Icons.storage,
              titulo: 'Datos de Demostración y Pruebas',
              color: Colors.indigo.shade700,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.withValues(alpha: 0.12),
                  child: Icon(Icons.refresh, color: Colors.indigo.shade700),
                ),
                title: const Text(
                  'Cargar Datos de Demostración',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Llena la base de datos con 8 clientes, 7 revistas, 5 repartidores, 14 suscripciones y 20 entregas de prueba.',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(90, 36),
                  ),
                  onPressed: _reiniciandoDatos ? null : _confirmarRecargaDatos,
                  child: _reiniciandoDatos
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Cargar'),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String texto, IconData icono) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTituloSeccion({
    required IconData icono,
    required String titulo,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icono, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: color.withValues(alpha: 0.3))),
      ],
    );
  }
}
