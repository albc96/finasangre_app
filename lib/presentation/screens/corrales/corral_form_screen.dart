import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/corral_model.dart';
import '../../providers/corral_provider.dart';

class CorralFormScreen extends StatefulWidget {
  const CorralFormScreen({super.key, this.corral});
  final CorralModel? corral;

  @override
  State<CorralFormScreen> createState() => _CorralFormScreenState();
}

class _CorralFormScreenState extends State<CorralFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController numero;
  late final TextEditingController nombre;
  late final TextEditingController ubicacion;
  late final TextEditingController capacidad;

  @override
  void initState() {
    super.initState();
    final c = widget.corral;
    numero = TextEditingController(text: c?.numeroCorral ?? '');
    nombre = TextEditingController(text: c?.nombreCorral ?? '');
    ubicacion = TextEditingController(text: c?.ubicacion ?? '');
    capacidad = TextEditingController(text: c?.capacidad.toString() ?? '');
  }

  @override
  void dispose() {
    numero.dispose();
    nombre.dispose();
    ubicacion.dispose();
    capacidad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Corral')),
        body: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TextFormField(
                controller: numero,
                decoration: const InputDecoration(labelText: 'Numero'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
            TextFormField(
                controller: nombre,
                decoration: const InputDecoration(labelText: 'Nombre')),
            TextFormField(
                controller: ubicacion,
                decoration: const InputDecoration(labelText: 'Ubicacion')),
            TextFormField(
                controller: capacidad,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacidad'),
                validator: (v) =>
                    int.tryParse(v ?? '') == null ? 'Numero invalido' : null),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final item = CorralModel(
                  idCorral: widget.corral?.idCorral ?? 0,
                  numeroCorral: numero.text,
                  nombreCorral: nombre.text,
                  ubicacion: ubicacion.text,
                  capacidad: int.parse(capacidad.text),
                  activo: 'SI',
                );
                final provider = context.read<CorralProvider>();
                final ok = widget.corral == null
                    ? await provider.crear(item)
                    : await provider.actualizar(item);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? (widget.corral == null
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
