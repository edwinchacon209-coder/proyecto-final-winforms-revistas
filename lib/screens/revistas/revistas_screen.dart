import 'package:flutter/material.dart';
import '../../models/revista.dart';
import '../../repositories/revista_repository.dart';
import '../../widgets/formulario_dialogo.dart';

class RevistasScreen extends StatefulWidget {
  const RevistasScreen({super.key});

  @override
  State<RevistasScreen> createState() => _RevistasScreenState();
}

class _RevistasScreenState extends State<RevistasScreen> {
  final _repo = RevistaRepository();
  List<Revista> _revistas = [];
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
      if (mounted) setState(() { _revistas = lista; _cargando = false; });
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Future<void> _mostrarFormulario({Revista? revista}) async {
    final nombreCtrl = TextEditingController(text: revista?.nombre ?? '');
    final formKey = GlobalKey<FormState>();

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FormularioDialogo(
        titulo: revista == null ? 'Nueva Revista' : 'Editar Revista',
        icono: Icons.menu_book,
        formKey: formKey,
        onGuardar: () async {
          if (!formKey.currentState!.validate()) return false;
          try {
            if (revista == null) {
              await _repo.insertar(Revista(nombre: nombreCtrl.text.trim()));
            } else {
              await _repo.actualizar(revista.copyWith(nombre: nombreCtrl.text.trim()));
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
                labelText: 'Nombre de la Revista *',
                prefixIcon: Icon(Icons.menu_book),
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
            content: Text(revista == null ? 'Revista creada.' : 'Revista actualizada.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(Revista revista) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Revista'),
        content: Text('¿Eliminar "${revista.nombre}"?'),
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
        await _repo.eliminar(revista.id!);
        await _cargar();
      } catch (e) {
        _mostrarError('$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revistas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Revista'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _revistas.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book, size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No hay revistas registradas.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _revistas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final r = _revistas[i];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Icon(Icons.menu_book, color: Colors.teal.shade700),
                        ),
                        title: Text(r.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'editar') _mostrarFormulario(revista: r);
                            if (v == 'eliminar') _confirmarEliminar(r);
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
