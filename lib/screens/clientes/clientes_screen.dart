import 'package:flutter/material.dart';
import '../../models/cliente.dart';
import '../../repositories/cliente_repository.dart';
import '../../widgets/formulario_dialogo.dart';

class ClientesScreen extends StatefulWidget {
  final bool abrirFormulario;
  const ClientesScreen({super.key, this.abrirFormulario = false});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _repo = ClienteRepository();
  List<Cliente> _clientes = [];
  List<Cliente> _filtrados = [];
  bool _cargando = true;
  final _busquedaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
    if (widget.abrirFormulario) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarFormulario());
    }
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final lista = await _repo.obtenerTodos();
      if (mounted) {
        setState(() {
          _clientes = lista;
          _filtrar(_busquedaCtrl.text);
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        _mostrarError('Error al cargar clientes: $e');
      }
    }
  }

  void _filtrar(String termino) {
    if (termino.isEmpty) {
      _filtrados = List.from(_clientes);
    } else {
      final t = termino.toLowerCase();
      _filtrados = _clientes
          .where((c) =>
              c.nombre.toLowerCase().contains(t) ||
              c.nit.toLowerCase().contains(t))
          .toList();
    }
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _mostrarExito(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  Future<void> _mostrarFormulario({Cliente? cliente}) async {
    final nitCtrl = TextEditingController(text: cliente?.nit ?? '');
    final nombreCtrl = TextEditingController(text: cliente?.nombre ?? '');
    final dirCtrl = TextEditingController(text: cliente?.direccion ?? '');
    final telCtrl = TextEditingController(text: cliente?.telefono ?? '');
    final formKey = GlobalKey<FormState>();

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FormularioDialogo(
        titulo: cliente == null ? 'Nuevo Cliente' : 'Editar Cliente',
        icono: Icons.person,
        formKey: formKey,
        onGuardar: () async {
          if (!formKey.currentState!.validate()) return false;
          try {
            if (cliente == null) {
              await _repo.insertar(Cliente(
                nit: nitCtrl.text.trim(),
                nombre: nombreCtrl.text.trim(),
                direccion: dirCtrl.text.trim().isEmpty ? null : dirCtrl.text.trim(),
                telefono: telCtrl.text.trim().isEmpty ? null : telCtrl.text.trim(),
              ));
            } else {
              await _repo.actualizar(cliente.copyWith(
                nit: nitCtrl.text.trim(),
                nombre: nombreCtrl.text.trim(),
                direccion: dirCtrl.text.trim().isEmpty ? null : dirCtrl.text.trim(),
                telefono: telCtrl.text.trim().isEmpty ? null : telCtrl.text.trim(),
              ));
            }
            return true;
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('$e'), backgroundColor: Colors.red),
              );
            }
            return false;
          }
        },
        campos: [
          _campo(
            ctrl: nitCtrl,
            label: 'NIT *',
            icono: Icons.badge,
            validar: (v) => (v == null || v.trim().isEmpty) ? 'El NIT es obligatorio' : null,
          ),
          _campo(
            ctrl: nombreCtrl,
            label: 'Nombre o Razón Social *',
            icono: Icons.person,
            validar: (v) => (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
          ),
          _campo(ctrl: dirCtrl, label: 'Dirección', icono: Icons.location_on),
          _campo(ctrl: telCtrl, label: 'Teléfono', icono: Icons.phone, tipo: TextInputType.phone),
        ],
      ),
    );

    if (resultado == true) {
      await _cargar();
      _mostrarExito(cliente == null ? 'Cliente creado correctamente.' : 'Cliente actualizado.');
    }
  }

  Widget _campo({
    required TextEditingController ctrl,
    required String label,
    required IconData icono,
    String? Function(String?)? validar,
    TextInputType tipo = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: tipo,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icono),
        ),
        validator: validar,
      ),
    );
  }

  Future<void> _confirmarEliminar(Cliente cliente) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: Text(
          '¿Desea eliminar a "${cliente.nombre}"?\n\nEsta acción no puede deshacerse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
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
        await _repo.eliminar(cliente.id!);
        await _cargar();
        _mostrarExito('Cliente eliminado.');
      } catch (e) {
        _mostrarError('$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormulario,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Cliente'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _busquedaCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre o NIT...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _filtrar(v)),
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _filtrados.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('No hay clientes registrados.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filtrados.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final c = _filtrados[i];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  c.nombre.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('NIT: ${c.nit}${c.telefono != null ? '  •  Tel: ${c.telefono}' : ''}'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'editar') _mostrarFormulario(cliente: c);
                                  if (v == 'eliminar') _confirmarEliminar(c);
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
          ),
        ],
      ),
    );
  }
}
