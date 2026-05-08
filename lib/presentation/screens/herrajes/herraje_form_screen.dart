import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/herraje_model.dart';
import '../../providers/caballo_provider.dart';
import '../../providers/corral_provider.dart';
import '../../providers/herraje_provider.dart';
import '../../providers/herrador_provider.dart';

class HerrajeFormScreen extends StatefulWidget {
  const HerrajeFormScreen({super.key, this.herraje});
  final HerrajeModel? herraje;

  @override
  State<HerrajeFormScreen> createState() => _HerrajeFormScreenState();
}

class _HerrajeFormScreenState extends State<HerrajeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int? caballo;
  int? herrador;
  int? corral;
  String tipo = 'COMPLETO';
  late DateTime fecha;
  late TimeOfDay hora;
  late final TextEditingController observaciones;

  @override
  void initState() {
    super.initState();
    final h = widget.herraje;
    caballo = h?.idCaballo;
    herrador = h?.idHerrador;
    corral = h?.idCorral;
    tipo = h?.tipoHerraje ?? 'COMPLETO';
    final initialDate = h?.fechaHerraje ?? DateTime.now();
    fecha = DateTime(initialDate.year, initialDate.month, initialDate.day);
    hora = TimeOfDay(
      hour: initialDate.hour,
      minute: initialDate.minute,
    );
    if ((h?.hora ?? '').contains(':')) {
      final parts = h!.hora.split(':');
      hora = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? hora.hour,
        minute: int.tryParse(parts[1]) ?? hora.minute,
      );
    }
    observaciones = TextEditingController(text: h?.observaciones ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CaballoProvider>().cargar();
      context.read<HerradorProvider>().cargar();
      context.read<CorralProvider>().cargar();
    });
  }

  @override
  void dispose() {
    observaciones.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final fechaHora = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );
    final item = HerrajeModel(
      idHerraje: widget.herraje?.idHerraje ?? 0,
      idCaballo: caballo!,
      idHerrador: herrador!,
      idCorral: corral!,
      tipoHerraje: tipo,
      fechaHerraje: fechaHora,
      dia: fechaHora.day,
      mes: fechaHora.month,
      anio: fechaHora.year,
      hora:
          '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}',
      observaciones: observaciones.text.trim(),
    );
    final provider = context.read<HerrajeProvider>();
    final ok = widget.herraje == null
        ? await provider.crear(item)
        : await provider.actualizar(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (widget.herraje == null
                ? 'Herraje guardado correctamente'
                : 'Actualizado correctamente')
            : provider.error ?? 'No se pudo guardar'),
      ),
    );
    if (ok) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    setState(() => fecha = selected);
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: hora,
    );
    if (selected == null || !mounted) return;
    setState(() => hora = selected);
  }

  @override
  Widget build(BuildContext context) {
    final caballos = context.watch<CaballoProvider>().items;
    final herradores = context.watch<HerradorProvider>().items;
    final corrales = context.watch<CorralProvider>().items;
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar herraje')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          DropdownButtonFormField<int>(
            initialValue: caballo,
            decoration: const InputDecoration(labelText: 'Caballo'),
            items: caballos
                .map((c) => DropdownMenuItem(
                    value: c.idCaballo, child: Text(c.nombreCaballo)))
                .toList(),
            onChanged: (v) {
              final selected =
                  caballos.where((c) => c.idCaballo == v).firstOrNull;
              setState(() {
                caballo = v;
                if (selected != null) corral = selected.idCorral;
              });
            },
            validator: (v) => v == null ? 'Selecciona caballo' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: herrador,
            decoration: const InputDecoration(labelText: 'Herrador'),
            items: herradores
                .map((h) => DropdownMenuItem(
                    value: h.idHerrador, child: Text(h.nombreCompleto)))
                .toList(),
            onChanged: (v) => setState(() => herrador = v),
            validator: (v) => v == null ? 'Selecciona herrador' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: corral,
            decoration: const InputDecoration(labelText: 'Corral'),
            items: corrales
                .map((c) => DropdownMenuItem(
                    value: c.idCorral,
                    child: Text([c.nombreCorral, c.numeroCorral]
                        .where((v) => v.trim().isNotEmpty)
                        .join(' '))))
                .toList(),
            onChanged: (v) => setState(() => corral = v),
            validator: (v) => v == null ? 'Selecciona corral' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: tipo,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: const ['COMPLETO', 'MANOS', 'PATAS']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => tipo = v ?? 'COMPLETO'),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: [
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
              ),
            ),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.schedule),
              label: Text(
                '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}',
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextFormField(
            controller: observaciones,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Observaciones'),
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
