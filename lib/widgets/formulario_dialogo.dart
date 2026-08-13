import 'package:flutter/material.dart';

/// Diálogo genérico reutilizable para formularios de creación/edición.
///
/// Recibe la lista de campos del formulario y un callback [onGuardar]
/// que retorna true si la operación fue exitosa, false si falló.
class FormularioDialogo extends StatefulWidget {
  final String titulo;
  final IconData icono;
  final GlobalKey<FormState> formKey;
  final List<Widget> campos;
  final Future<bool> Function() onGuardar;

  const FormularioDialogo({
    super.key,
    required this.titulo,
    required this.icono,
    required this.formKey,
    required this.campos,
    required this.onGuardar,
  });

  @override
  State<FormularioDialogo> createState() => _FormularioDialogoState();
}

class _FormularioDialogoState extends State<FormularioDialogo> {
  bool _guardando = false;

  Future<void> _guardar() async {
    if (!widget.formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final ok = await widget.onGuardar();
    if (mounted) {
      setState(() => _guardando = false);
      if (ok) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(widget.icono, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.titulo,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: widget.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.campos,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _guardando ? null : _guardar,
          icon: _guardando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save),
          label: Text(_guardando ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}
