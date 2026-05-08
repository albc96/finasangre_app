import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/preparador_model.dart';
import '../../providers/preparador_provider.dart';

class PreparadorFormScreen extends StatefulWidget {
  const PreparadorFormScreen({super.key, this.preparador});
  final PreparadorModel? preparador;

  @override
  State<PreparadorFormScreen> createState() => _PreparadorFormScreenState();
}

class _PreparadorFormScreenState extends State<PreparadorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nombre;
  late final TextEditingController telefono;
  late final TextEditingController email;

  @override
  void initState() {
    super.initState();
    final p = widget.preparador;
    nombre = TextEditingController(text: p?.nombreCompleto ?? '');
    telefono = TextEditingController(text: p?.telefono ?? '');
    email = TextEditingController(text: p?.email ?? '');
  }

  @override
  void dispose() {
    nombre.dispose();
    telefono.dispose();
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Preparador')),
        body: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TextFormField(
                controller: nombre,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
            TextFormField(
                controller: telefono,
                decoration: const InputDecoration(labelText: 'Telefono')),
            TextFormField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final item = PreparadorModel(
                  idPreparador: widget.preparador?.idPreparador ?? 0,
                  nombreCompleto: nombre.text,
                  telefono: telefono.text,
                  email: email.text,
                  activo: 'SI',
                );
                final provider = context.read<PreparadorProvider>();
                final ok = widget.preparador == null
                    ? await provider.crear(item)
                    : await provider.actualizar(item);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? (widget.preparador == null
                            ? 'Guardado correctamente'
                            : 'Actualizado correctamente')
                        : provider.error ?? 'No se pudo guardar'),
                  ),
                );
                if (ok) Navigator.pop(context);
              },
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
            )
          ]),
        ),
      );
}
