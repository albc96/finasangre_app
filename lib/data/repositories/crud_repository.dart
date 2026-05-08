import 'dart:async';
import '../services/ords_client.dart';
import '../services/offline_cache_service.dart';

typedef FromJson<T> = T Function(Map<String, dynamic> json);
typedef ToJson<T> = Map<String, dynamic> Function(T item);

class CrudRepository<T> {
  CrudRepository({
    required this.client,
    required this.endpoint,
    required this.fromJson,
    required this.toJson,
    required this.idOf,
    required this.idKey,
    this.offlineCache,
  });

  final OrdsClient client;
  final String endpoint;
  final FromJson<T> fromJson;
  final ToJson<T> toJson;
  final dynamic Function(T item) idOf;
  final String idKey;
  final OfflineCacheService? offlineCache;

  Future<List<T>> list() async {
    try {
      final rows = await client.getList(endpoint).timeout(const Duration(seconds: 10));
      await offlineCache?.saveCollection(endpoint, rows, idKey);
      return rows.map(fromJson).toList();
    } on TimeoutException catch (_) {
      final cached = await offlineCache?.readCollection(endpoint);
      if (cached != null && cached.isNotEmpty) {
        return cached.map(fromJson).toList();
      }
      throw Exception(
          'Error de conexión o servidor no responde. Por favor, revisa tu internet e intenta nuevamente.');
    } catch (e) {
      final cached = await offlineCache?.readCollection(endpoint);
      if (cached != null && cached.isNotEmpty) {
        return cached.map(fromJson).toList();
      }
      rethrow;
    }
  }

  Future<T> get(dynamic id) async =>
      fromJson((await client.getById(endpoint, idKey, id)) ??
          (throw OrdsException('No se encontro el registro solicitado.')));

  Future<void> create(T item) async {
    final payload = Map<String, dynamic>.from(toJson(item))..remove(idKey);
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

  Future<void> update(T item) async =>
      client.put(endpoint, idOf(item), toJson(item)).catchError((error) async {
        await offlineCache?.addPendingMutation(
          endpoint: endpoint,
          method: 'PUT',
          remoteId: idOf(item),
          payload: toJson(item),
        );
        throw error;
      });

  Future<void> delete(dynamic id) async =>
      client.delete(endpoint, id).timeout(const Duration(seconds: 10)).catchError((error) async {
        await offlineCache?.addPendingMutation(
          endpoint: endpoint,
          method: 'DELETE',
          remoteId: id,
          payload: {'id': id},
        );
        throw error;
      });
}
