import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/entrega.dart';
import '../../models/suscripcion.dart';
import '../../models/empleado.dart';
import '../../repositories/entrega_repository.dart';
import '../../repositories/suscripcion_repository.dart';
import '../../repositories/empleado_repository.dart';

class EntregasScreen extends StatefulWidget {
  final String filtroInicial; // 'todas' | 'pendientes' | 'realizadas' | 'atrasadas'
  final bool abrirFormulario;

  const EntregasScreen({
    super.key,
    this.filtroInicial = 'todas',
    this.abrirFormulario = false,
  });

  @override
  State<EntregasScreen> createState() => _EntregasScreenState();
}

class _EntregasScreenState extends State<EntregasScreen>
    with SingleTickerProviderStateMixin {
  final _repo = EntregaRepository();
  final _suscripcionRepo = SuscripcionRepository();
  final _empleadoRepo = EmpleadoRepository();

  late TabController _tabCtrl;
  List<Entrega> _todas = [];
  List<Entrega> _pendientes = [];
  List<Entrega> _realizadas = [];
  List<Entrega> _atrasadas = [];
  bool _cargando = true;

  final _tabs = const [
    Tab(text: 'Todas'),
    Tab(text: 'Pendientes'),
    Tab(text: 'Atrasadas'),
    Tab(text: 'Realizadas'),
  ];

  @override
  void initState() {
    super.initState();
    final tabIndex = switch (widget.filtroInicial) {
      'pendientes' => 1,
      'atrasadas' => 2,
      'realizadas' => 3,
      _ => 0,
    };
    _tabCtrl = TabController(length: 4, vsync: this, initialIndex: tabIndex);
    _cargar();
    if (widget.abrirFormulario) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarFormulario());
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final todas = await _repo.obtenerTodas();
      if (mounted) {
        setState(() {
          _todas = todas;
          _pendientes = todas.where((e) => !e.esRealizada && !e.esAtrasada).toList();
          _atrasadas = todas.where((e) => e.esAtrasada).toList();
          _realizadas = todas.where((e) => e.esRealizada).toList();
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _formatFecha(String? fecha) {
    if (fecha == null) return '—';
    try {
      return DateFormat('dd/MM/yyyy', 'es').format(DateTime.parse(fecha));
    } catch (_) {
      return fecha;
    }
  }

  Future<void> _mostrarFormulario({Entrega? entrega}) async {
    final suscripciones = await _suscripcionRepo.obtenerTodas();
    final empleados = await _empleadoRepo.obtenerTodos();

    if (suscripciones.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe crear al menos una suscripción antes de registrar entregas.')),
        );
      }
      return;
    }
    if (empleados.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe registrar al menos un empleado antes de crear entregas.')),
        );
      }
      return;
    }

    final numCtrl = TextEditingController(text: entrega?.numeroEnvio ?? '');
    final obsCtrl = TextEditingController(text: entrega?.observaciones ?? '');
    Suscripcion? suscripcionSel = entrega != null
        ? suscripciones.firstWhere(
            (s) => s.id == entrega.suscripcionId,
            orElse: () => suscripciones.first,
          )
        : null;
    Empleado? empleadoSel = entrega != null
        ? empleados.firstWhere(
            (e) => e.id == entrega.empleadoId,
            orElse: () => empleados.first,
          )
        : null;
    DateTime? fechaProgramada =
        entrega != null ? DateTime.tryParse(entrega.fechaProgramada) : null;
    final formKey = GlobalKey<FormState>();
    final formato = DateFormat('yyyy-MM-dd');

    if (!mounted) return;
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDlg) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.local_shipping, color: Theme.of(ctx).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(entrega == null ? 'Nueva Entrega' : 'Editar Entrega')),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: numCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Número de Envío *',
                        prefixIcon: Icon(Icons.tag),
                        hintText: 'Ej: E-0005',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Suscripcion>(
                      initialValue: suscripcionSel,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Suscripción *',
                        prefixIcon: Icon(Icons.subscriptions),
                      ),
                      items: suscripciones
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  '${s.numeroSuscripcion} — ${s.clienteNombre ?? "?"} (${s.revistaNombre ?? "?"})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setStateDlg(() => suscripcionSel = v),
                      validator: (v) => v == null ? 'Seleccione una suscripción' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Empleado>(
                      initialValue: empleadoSel,
                      decoration: const InputDecoration(
                        labelText: 'Empleado responsable *',
                        prefixIcon: Icon(Icons.badge),
                      ),
                      items: empleados
                          .map((e) => DropdownMenuItem(value: e, child: Text(e.nombre)))
                          .toList(),
                      onChanged: (v) => setStateDlg(() => empleadoSel = v),
                      validator: (v) => v == null ? 'Seleccione un empleado' : null,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(fechaProgramada == null
                          ? 'Fecha programada *'
                          : 'Programada: ${DateFormat('dd/MM/yyyy').format(fechaProgramada!)}'),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: fechaProgramada ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) setStateDlg(() => fechaProgramada = picked);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: obsCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones',
                        prefixIcon: Icon(Icons.notes),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  if (fechaProgramada == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Seleccione la fecha programada.')),
                    );
                    return;
                  }
                  try {
                    if (entrega == null) {
                      await _repo.insertar(Entrega(
                        numeroEnvio: numCtrl.text.trim(),
                        suscripcionId: suscripcionSel!.id!,
                        empleadoId: empleadoSel!.id!,
                        fechaProgramada: formato.format(fechaProgramada!),
                        observaciones: obsCtrl.text.trim().isEmpty ? null : obsCtrl.text.trim(),
                      ));
                    } else {
                      await _repo.actualizar(entrega.copyWith(
                        numeroEnvio: numCtrl.text.trim(),
                        suscripcionId: suscripcionSel!.id!,
                        empleadoId: empleadoSel!.id!,
                        fechaProgramada: formato.format(fechaProgramada!),
                        observaciones: obsCtrl.text.trim().isEmpty ? null : obsCtrl.text.trim(),
                      ));
                    }
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );

    if (resultado == true) {
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(entrega == null ? 'Entrega registrada.' : 'Entrega actualizada.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Flujo principal: marcar una entrega como realizada.
  Future<void> _marcarEntregada(Entrega entrega) async {
    final obsCtrl = TextEditingController(text: entrega.observaciones ?? '');
    DateTime fechaEntrega = DateTime.now();
    final formato = DateFormat('yyyy-MM-dd');

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDlg) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Marcar como Entregada'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Suscripción: ${entrega.suscripcionNumero ?? "?"}'),
              Text('Cliente: ${entrega.clienteNombre ?? "?"}'),
              Text('Revista: ${entrega.revistaNombre ?? "?"}'),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available, color: Colors.green),
                title: Text('Fecha de entrega: ${DateFormat('dd/MM/yyyy').format(fechaEntrega)}'),
                trailing: const Icon(Icons.edit_calendar),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: fechaEntrega,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) setStateDlg(() => fechaEntrega = picked);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: obsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observaciones de la entrega',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Confirmar Entrega'),
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      try {
        await _repo.marcarComoEntregada(
          id: entrega.id!,
          fechaEntrega: formato.format(fechaEntrega),
          observaciones: obsCtrl.text.trim().isEmpty ? null : obsCtrl.text.trim(),
        );
        await _cargar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Entrega marcada como realizada.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _confirmarEliminar(Entrega entrega) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Entrega'),
        content: Text('¿Eliminar el envío ${entrega.numeroEnvio}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repo.eliminar(entrega.id!);
      await _cargar();
    }
  }

  Widget _buildLista(List<Entrega> lista) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (lista.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text('No hay entregas en esta categoría.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: lista.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _EntregaCard(
        entrega: lista[i],
        formatFecha: _formatFecha,
        onMarcarEntregada: !lista[i].esRealizada ? () => _marcarEntregada(lista[i]) : null,
        onEditar: () => _mostrarFormulario(entrega: lista[i]),
        onEliminar: () => _confirmarEliminar(lista[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entregas'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Entrega'),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildLista(_todas),
          _buildLista(_pendientes),
          _buildLista(_atrasadas),
          _buildLista(_realizadas),
        ],
      ),
    );
  }
}

// ─── Tarjeta de Entrega ───────────────────────────────────────────────────────

class _EntregaCard extends StatelessWidget {
  final Entrega entrega;
  final String Function(String?) formatFecha;
  final VoidCallback? onMarcarEntregada;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _EntregaCard({
    required this.entrega,
    required this.formatFecha,
    required this.onMarcarEntregada,
    required this.onEditar,
    required this.onEliminar,
  });

  Color get _statusColor {
    if (entrega.esRealizada) return Colors.green.shade700;
    if (entrega.esAtrasada) return Colors.red.shade700;
    return Colors.orange.shade700;
  }

  String get _statusLabel {
    if (entrega.esRealizada) return 'REALIZADA';
    if (entrega.esAtrasada) return 'ATRASADA';
    return 'PENDIENTE';
  }

  IconData get _statusIcon {
    if (entrega.esRealizada) return Icons.check_circle;
    if (entrega.esAtrasada) return Icons.warning_amber_rounded;
    return Icons.schedule;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Barra de estado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: _statusColor.withValues(alpha: 0.12),
            child: Row(
              children: [
                Icon(_statusIcon, size: 16, color: _statusColor),
                const SizedBox(width: 6),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  'Envío: ${entrega.numeroEnvio}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entrega.clienteNombre ?? '—',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            entrega.revistaNombre ?? '—',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          Text(
                            'Suscripción: ${entrega.suscripcionNumero ?? "—"}',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'editar') onEditar();
                        if (v == 'eliminar') onEliminar();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'editar', child: ListTile(leading: Icon(Icons.edit), title: Text('Editar'))),
                        PopupMenuItem(
                          value: 'eliminar',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(entrega.empleadoNombre ?? '—', style: const TextStyle(fontSize: 13)),
                    const Spacer(),
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Prog: ${formatFecha(entrega.fechaProgramada)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                if (entrega.esRealizada) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Entregada: ${formatFecha(entrega.fechaEntrega)}',
                        style: TextStyle(fontSize: 13, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ],
                if (entrega.observaciones != null && entrega.observaciones!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Obs: ${entrega.observaciones}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                ],
                if (onMarcarEntregada != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onMarcarEntregada,
                      icon: const Icon(Icons.check),
                      label: const Text('Marcar como Entregada'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
