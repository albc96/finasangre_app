import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/caballo_model.dart';
import '../../../data/services/photo_service.dart';
import '../../providers/caballo_provider.dart';
import '../../providers/corral_provider.dart';
import '../../providers/preparador_provider.dart';

class CaballoFormScreen extends StatefulWidget {
  const CaballoFormScreen({super.key, this.caballo});
  final CaballoModel? caballo;

  @override
  State<CaballoFormScreen> createState() => _CaballoFormScreenState();
}

class _CaballoFormScreenState extends State<CaballoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _edad;
  late final TextEditingController _sexo;
  late final TextEditingController _color;
  String _fotoUrl = '';
  int? _corral;
  int? _preparador;
  final _photoService = PhotoService();

  @override
  void initState() {
    super.initState();
    final caballo = widget.caballo;
    _nombre = TextEditingController(text: caballo?.nombreCaballo ?? '');
    _edad = TextEditingController(text: caballo?.edad.toString() ?? '');
    _sexo = TextEditingController(text: caballo?.sexo ?? '');
    _color = TextEditingController(text: caballo?.color ?? '');
    _fotoUrl = caballo?.fotoUrl ?? '';
    _corral = caballo?.idCorral;
    _preparador = caballo?.idPreparador;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CorralProvider>().cargar();
      context.read<PreparadorProvider>().cargar();
    });
  }

  @override
  void dispose() {
    _nombre.dispose();
    _edad.dispose();
    _sexo.dispose();
    _color.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final item = CaballoModel(
      idCaballo: widget.caballo?.idCaballo ?? 0,
      nombreCaballo: _nombre.text.trim(),
      edad: int.parse(_edad.text),
      fechaNacimiento: widget.caballo?.fechaNacimiento,
      idCorral: _corral!,
      idPreparador: _preparador!,
      sexo: _sexo.text.trim(),
      color: _color.text.trim(),
      fotoUrl: _fotoUrl,
    );
    final provider = context.read<CaballoProvider>();
    final ok = widget.caballo == null
        ? await provider.crear(item)
        : await provider.actualizar(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (widget.caballo == null
                ? 'Guardado correctamente'
                : 'Actualizado correctamente')
            : provider.error ?? 'No se pudo guardar'),
      ),
    );
    if (ok) Navigator.pop(context);
  }

  Future<void> _pickPhoto(bool camera) async {
    final path = camera
        ? await _photoService.takePhoto()
        : await _photoService.pickFromGallery();
    if (path == null || !mounted) return;
    setState(() => _fotoUrl = path);
  }

  @override
  Widget build(BuildContext context) {
    final corrales = context.watch<CorralProvider>().items;
    final preparadores = context.watch<PreparadorProvider>().items;
    return Scaffold(
      appBar: AppBar(
          title: Text(
              widget.caballo == null ? 'Nuevo caballo' : 'Editar caballo')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(
            controller: _nombre,
            decoration: const InputDecoration(labelText: 'Nombre'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _edad,
            decoration: const InputDecoration(labelText: 'Edad'),
            keyboardType: TextInputType.number,
            validator: (v) =>
                int.tryParse(v ?? '') == null ? 'Edad invalida' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _corral,
            decoration: const InputDecoration(labelText: 'Corral'),
            items: corrales
                .map((c) => DropdownMenuItem(
                    value: c.idCorral,
                    child: Text('${c.numeroCorral} ${c.nombreCorral}')))
                .toList(),
            onChanged: (v) => setState(() => _corral = v),
            validator: (v) => v == null ? 'Selecciona corral' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _preparador,
            decoration: const InputDecoration(labelText: 'Preparador'),
            items: preparadores
                .map((p) => DropdownMenuItem(
                    value: p.idPreparador, child: Text(p.nombreCompleto)))
                .toList(),
            onChanged: (v) => setState(() => _preparador = v),
            validator: (v) => v == null ? 'Selecciona preparador' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
              controller: _sexo,
              decoration: const InputDecoration(labelText: 'Sexo')),
          const SizedBox(height: 12),
          TextFormField(
              controller: _color,
              decoration: const InputDecoration(labelText: 'Color')),
          const SizedBox(height: 20),
          _PhotoPicker(
            title: 'Foto caballo',
            path: _fotoUrl,
            onCamera: () => _pickPhoto(true),
            onGallery: () => _pickPhoto(false),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Guardar')),
        ]),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.title,
    required this.path,
    required this.onCamera,
    required this.onGallery,
  });

  final String title;
  final String path;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = path.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (hasPhoto)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(path),
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                alignment: Alignment.center,
                color: Colors.white10,
                child: const Text('No se pudo mostrar la imagen local'),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          OutlinedButton.icon(
            onPressed: onCamera,
            icon: const Icon(Icons.photo_camera),
            label: const Text('Tomar foto'),
          ),
          OutlinedButton.icon(
            onPressed: onGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('Galeria'),
          ),
        ]),
      ],
    );
  }
}
