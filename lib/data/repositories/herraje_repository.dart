// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../models/herraje_model.dart';
import '../services/offline_cache_service.dart';
import '../services/ords_client.dart';
import 'crud_repository.dart';

class HerrajeRepository extends CrudRepository<HerrajeModel> {
  HerrajeRepository(OrdsClient client, {OfflineCacheService? offlineCache})
      : super(
          client: client,
          endpoint: OrdsEndpoints.herrajes,
          fromJson: HerrajeModel.fromJson,
          toJson: (item) => item.toJson(),
          idOf: (item) => item.idHerraje,
          idKey: 'id_herraje',
          offlineCache: offlineCache,
        );

  Future<List<HerrajeModel>> listar() => list();

  Future<void> crear(HerrajeModel herraje) async {
    final payload = {
      'id_caballo': herraje.idCaballo,
      'id_herrador': herraje.idHerrador,
      'id_corral': herraje.idCorral,
      'tipo_herraje': herraje.tipoHerraje,
      'fecha_herraje': _formatFechaHerraje(herraje.fechaHerraje),
      'observaciones': herraje.observaciones,
    };
    debugPrint('FECHA_HERRAJE FINAL => ${payload["fecha_herraje"]}');

    try {
      await client.post(endpoint, payload);
    } catch (_) {
      await offlineCache?.addPendingMutation(
        endpoint: endpoint,
        method: 'POST',
        payload: payload,
      );
      rethrow;
    }
  }

  Future<void> actualizar(HerrajeModel herraje) => update(herraje);

  Future<void> eliminar(int idHerraje) => delete(idHerraje);

  String? _formatFechaHerraje(DateTime? value) {
    if (value == null) return null;
    return formatFechaHerrajeForOrds(value, TimeOfDay.fromDateTime(value));
  }
}

String formatFechaHerrajeForOrds(DateTime fecha, TimeOfDay hora) {
  String two(int n) => n.toString().padLeft(2, '0');

  return '${fecha.year}-'
      '${two(fecha.month)}-'
      '${two(fecha.day)}T'
      '${two(hora.hour)}:'
      '${two(hora.minute)}:00Z';
}
