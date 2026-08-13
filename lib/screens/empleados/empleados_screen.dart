import 'package:flutter/material.dart';
import '../../models/empleado.dart';
import '../../repositories/empleado_repository.dart';
import '../../widgets/formulario_dialogo.dart';

class EmpleadosScreen extends StatefulWidget {
  const EmpleadosScreen({super.key});

  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen> {
  final _repo = EmpleadoRepository();
  List<Empleado> _empleados = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final lista = await _repo.obtenerTodos();
      if (mounted) setState(() { _empleados = lista; _cargando = false; });
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _mostrarFormulario({Empleado? empleado}) async {
    final nombreCtrl = TextEditingController(text: empleado?.nombre ?? '');
    final formKey = GlobalKey<FormState>();

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FormularioDialogo(
        titulo: empleado == null ? 'Nuevo Empleado' : 'Editar Empleado',
        icono: Icons.badge,
        formKey: formKey,
        onGuardar: () async {
          if (!formKey.currentState!.validate()) return false;
          try {
            if (empleado == null) {
              await _repo.insertar(Empleado(nombre: nombreCtrl.text.trim()));
            } else {
              await _repo.actualizar(empleado.copyWith(nombre: nombreCtrl.text.trim()));
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
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre completo *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
            ),
          ),
        ],
      ),
    );

    if (resultado == true) {
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(empleado == null ? 'Empleado registrado.' : 'Empleado actualizado.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(Empleado empleado) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Empleado'),
        content: Text('¿Eliminar a "${empleado.nombre}"?'),
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
        await _repo.eliminar(empleado.id!);
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
      appBar: AppBar(title: const Text('Empleados')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormulario,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Empleado'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _empleados.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.badge, size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No hay empleados registrados.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _empleados.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final e = _empleados[i];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.brown.shade100,
                          child: Icon(Icons.person, color: Colors.brown.shade700),
                        ),
                        title: Text(e.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'editar') _mostrarFormulario(empleado: e);
                            if (v == 'eliminar') _confirmarEliminar(e);
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
