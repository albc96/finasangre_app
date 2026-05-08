import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/herrador_model.dart';
import '../../providers/herrador_provider.dart';

class HerradorFormScreen extends StatefulWidget {
  const HerradorFormScreen({super.key, this.herrador});
  final HerradorModel? herrador;

  @override
  State<HerradorFormScreen> createState() => _HerradorFormScreenState();
}

class _HerradorFormScreenState extends State<HerradorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController idUsuario;
  late final TextEditingController codigo;
  late final TextEditingController nombre;
  late final TextEditingController telefono;
  late final TextEditingController email;

  @override
  void initState() {
    super.initState();
    final h = widget.herrador;
    idUsuario = TextEditingController(text: h?.idUsuario.toString() ?? '0');
    codigo = TextEditingController(text: h?.codigoHerrador ?? '');
    nombre = TextEditingController(text: h?.nombreCompleto ?? '');
    telefono = TextEditingController(text: h?.telefono ?? '');
    email = TextEditingController(text: h?.email ?? '');
  }

  @override
  void dispose() {
    idUsuario.dispose();
    codigo.dispose();
    nombre.dispose();
    telefono.dispose();
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Herrador')),
        body: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TextFormField(
                controller: idUsuario,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ID Usuario')),
            TextFormField(
                controller: codigo,
                decoration: const InputDecoration(labelText: 'Codigo')),
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
                final item = HerradorModel(
                  idHerrador: widget.herrador?.idHerrador ?? 0,
                  idUsuario: int.tryParse(idUsuario.text) ?? 0,
                  codigoHerrador: codigo.text,
                  nombreCompleto: nombre.text,
                  telefono: telefono.text,
                  email: email.text,
                  activo: 'SI',
                );
                final provider = context.read<HerradorProvider>();
                final ok = widget.herrador == null
                    ? await provider.crear(item)
                    : await provider.actualizar(item);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? (widget.herrador == null
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
