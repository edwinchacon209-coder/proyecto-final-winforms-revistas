import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/suscripcion.dart';
import '../../models/cliente.dart';
import '../../models/revista.dart';
import '../../repositories/suscripcion_repository.dart';
import '../../repositories/cliente_repository.dart';
import '../../repositories/revista_repository.dart';

class SuscripcionesScreen extends StatefulWidget {
  const SuscripcionesScreen({super.key});

  @override
  State<SuscripcionesScreen> createState() => _SuscripcionesScreenState();
}

class _SuscripcionesScreenState extends State<SuscripcionesScreen> {
  final _repo = SuscripcionRepository();
  final _clienteRepo = ClienteRepository();
  final _revistaRepo = RevistaRepository();
  List<Suscripcion> _suscripciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final lista = await _repo.obtenerTodas();
      if (mounted) setState(() { _suscripciones = lista; _cargando = false; });
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _formatFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy', 'es').format(dt);
    } catch (_) {
      return fecha;
    }
  }

  Future<void> _mostrarFormulario({Suscripcion? suscripcion}) async {
    final clientes = await _clienteRepo.obtenerTodos();
    final revistas = await _revistaRepo.obtenerTodas();

    if (clientes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe registrar al menos un cliente antes de crear suscripciones.')),
        );
      }
      return;
    }
    if (revistas.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe registrar al menos una revista antes de crear suscripciones.')),
      );
      return;
    }

    final numCtrl = TextEditingController(text: suscripcion?.numeroSuscripcion ?? '');
    Cliente? clienteSeleccionado = suscripcion != null
        ? clientes.firstWhere((c) => c.id == suscripcion.clienteId, orElse: () => clientes.first)
        : null;
    Revista? revistaSeleccionada = suscripcion != null
        ? revistas.firstWhere((r) => r.id == suscripcion.revistaId, orElse: () => revistas.first)
        : null;
    DateTime? fechaInicio = suscripcion != null ? DateTime.tryParse(suscripcion.fechaInicio) : null;
    DateTime? fechaFin = suscripcion != null ? DateTime.tryParse(suscripcion.fechaFin) : null;
    final formKey = GlobalKey<FormState>();

    if (!mounted) return;
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDlg) {
          Future<void> seleccionarFecha(bool esInicio) async {
            final inicial = esInicio ? (fechaInicio ?? DateTime.now()) : (fechaFin ?? DateTime.now());
            final picked = await showDatePicker(
              context: ctx,
              initialDate: inicial,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
              locale: const Locale('es', 'GT'),
            );
            if (picked != null) {
              setStateDlg(() {
                if (esInicio) {
                  fechaInicio = picked;
                } else {
                  fechaFin = picked;
                }
              });
            }
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.subscriptions, color: Theme.of(ctx).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(suscripcion == null ? 'Nueva Suscripción' : 'Editar Suscripción')),
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
                        labelText: 'Número de Suscripción *',
                        prefixIcon: Icon(Icons.tag),
                        hintText: 'Ej: S-0005',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Cliente>(
                      initialValue: clienteSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Cliente *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre))).toList(),
                      onChanged: (v) => setStateDlg(() => clienteSeleccionado = v),
                      validator: (v) => v == null ? 'Seleccione un cliente' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Revista>(
                      initialValue: revistaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Revista *',
                        prefixIcon: Icon(Icons.menu_book),
                      ),
                      items: revistas.map((r) => DropdownMenuItem(value: r, child: Text(r.nombre))).toList(),
                      onChanged: (v) => setStateDlg(() => revistaSeleccionada = v),
                      validator: (v) => v == null ? 'Seleccione una revista' : null,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(fechaInicio == null ? 'Fecha de inicio *' : 'Inicio: ${DateFormat('dd/MM/yyyy').format(fechaInicio!)}'),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () => seleccionarFecha(true),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event),
                      title: Text(fechaFin == null ? 'Fecha de fin *' : 'Fin: ${DateFormat('dd/MM/yyyy').format(fechaFin!)}'),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () => seleccionarFecha(false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade400),
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
                  if (fechaInicio == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Seleccione la fecha de inicio.')),
                    );
                    return;
                  }
                  if (fechaFin == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Seleccione la fecha de fin.')),
                    );
                    return;
                  }
                  if (fechaFin!.isBefore(fechaInicio!)) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('La fecha de fin debe ser posterior a la de inicio.')),
                    );
                    return;
                  }
                  try {
                    final formato = DateFormat('yyyy-MM-dd');
                    if (suscripcion == null) {
                      await _repo.insertar(Suscripcion(
                        numeroSuscripcion: numCtrl.text.trim(),
                        clienteId: clienteSeleccionado!.id!,
                        revistaId: revistaSeleccionada!.id!,
                        fechaInicio: formato.format(fechaInicio!),
                        fechaFin: formato.format(fechaFin!),
                      ));
                    } else {
                      await _repo.actualizar(suscripcion.copyWith(
                        numeroSuscripcion: numCtrl.text.trim(),
                        clienteId: clienteSeleccionado!.id!,
                        revistaId: revistaSeleccionada!.id!,
                        fechaInicio: formato.format(fechaInicio!),
                        fechaFin: formato.format(fechaFin!),
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
            content: Text(suscripcion == null ? 'Suscripción creada.' : 'Suscripción actualizada.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(Suscripcion s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Suscripción'),
        content: Text('¿Eliminar la suscripción ${s.numeroSuscripcion}?'),
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
      try {
        await _repo.eliminar(s.id!);
        await _cargar();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suscripciones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Suscripción'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _suscripciones.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.subscriptions, size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No hay suscripciones registradas.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _suscripciones.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final s = _suscripciones[i];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade100,
                          child: Text(
                            s.numeroSuscripcion.replaceAll(RegExp(r'[^0-9]'), '').padLeft(2, '0'),
                            style: TextStyle(
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(
                          '${s.numeroSuscripcion} — ${s.revistaNombre ?? "?"}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Cliente: ${s.clienteNombre ?? "?"}\n'
                          '${_formatFecha(s.fechaInicio)} → ${_formatFecha(s.fechaFin)}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'editar') _mostrarFormulario(suscripcion: s);
                            if (v == 'eliminar') _confirmarEliminar(s);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'editar', child: ListTile(leading: Icon(Icons.edit), title: Text('Editar'))),
                            PopupMenuItem(value: 'eliminar', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Eliminar', style: TextStyle(color: Colors.red)))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
