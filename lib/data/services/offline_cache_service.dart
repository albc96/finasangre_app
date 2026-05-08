import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/config/app_config.dart';
import '../models/aura_model.dart';
import 'ords_client.dart';
import 'storage_paths.dart';

class OfflineCacheService {
  static const webStorageMessage =
      'Almacenamiento local no disponible en Web. Usando modo navegador.';

  Database? _db;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError(webStorageMessage);
    }
    if (_db != null) return _db!;
    final dir = await safeDocumentsDirectory();
    if (dir == null) throw UnsupportedError(webStorageMessage);
    final path = p.join(dir.path, 'finasangre_offline.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          create table cache_records (
            local_id integer primary key autoincrement,
            collection text not null,
            record_id text not null,
            payload text not null,
            remote_id text,
            pendiente_sync text not null default 'NO',
            accion_pendiente text,
            fecha_local text not null,
            updated_at text not null,
            unique (collection, record_id)
          )
        ''');
        await db.execute('''
          create table pending_mutations (
            id integer primary key autoincrement,
            local_id integer,
            endpoint text not null,
            method text not null,
            payload text not null,
            remote_id text,
            pendiente_sync text not null default 'SI',
            accion_pendiente text not null,
            fecha_local text not null,
            created_at text not null,
            synced integer not null default 0
          )
        ''');
        await db.execute('''
          create table aura_history (
            local_id integer primary key autoincrement,
            remote_id text,
            id_usuario integer not null,
            tipo text not null,
            mensaje text not null,
            respuesta text not null,
            contexto text not null,
            id_referencia integer,
            fecha_creacion text not null,
            pendiente_sync text not null default 'NO',
            accion_pendiente text
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _addColumn(db, 'cache_records', 'local_id integer');
          await _addColumn(db, 'cache_records', 'remote_id text');
          await _addColumn(
              db, 'cache_records', "pendiente_sync text not null default 'NO'");
          await _addColumn(db, 'cache_records', 'accion_pendiente text');
          await _addColumn(
              db, 'cache_records', "fecha_local text default '1970-01-01'");
          await _addColumn(db, 'pending_mutations', 'local_id integer');
          await _addColumn(db, 'pending_mutations', 'remote_id text');
          await _addColumn(db, 'pending_mutations',
              "pendiente_sync text not null default 'SI'");
          await _addColumn(db, 'pending_mutations',
              "accion_pendiente text not null default 'CREATE'");
          await _addColumn(db, 'pending_mutations',
              "fecha_local text default '1970-01-01'");
          await db.execute('''
            create table if not exists aura_history (
              local_id integer primary key autoincrement,
              remote_id text,
              id_usuario integer not null,
              tipo text not null,
              mensaje text not null,
              respuesta text not null,
              contexto text not null,
              id_referencia integer,
              fecha_creacion text not null,
              pendiente_sync text not null default 'NO',
              accion_pendiente text
            )
          ''');
        }
      },
    );
    return _db!;
  }

  static Future<void> _addColumn(
    Database db,
    String table,
    String columnSql,
  ) async {
    final name = columnSql.split(' ').first;
    try {
      await db.execute('alter table $table add column $columnSql');
    } catch (_) {
      if (name == 'local_id') return;
    }
  }

  Future<void> saveCollection(
    String collection,
    List<Map<String, dynamic>> rows,
    String idKey,
  ) async {
    if (kIsWeb) {
      await _saveCollectionWeb(collection, rows, idKey);
      return;
    }
    final db = await database;
    final batch = db.batch();
    for (final row in rows) {
      final id = '${row[idKey] ?? row['id'] ?? row.hashCode}';
      batch.insert(
        'cache_records',
        {
          'collection': collection,
          'record_id': id,
          'payload': jsonEncode(row),
          'remote_id': id,
          'pendiente_sync': 'NO',
          'accion_pendiente': null,
          'fecha_local': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> readCollection(String collection) async {
    if (kIsWeb) {
      return _readCollectionWeb(collection);
    }
    final db = await database;
    final rows = await db.query(
      'cache_records',
      where: 'collection = ?',
      whereArgs: [collection],
      orderBy: 'updated_at desc',
    );
    return rows
        .map((row) => jsonDecode(row['payload'] as String))
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> addPendingMutation({
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    dynamic remoteId,
  }) async {
    if (kIsWeb) {
      await _addPendingMutationWeb(
        endpoint: endpoint,
        method: method,
        payload: payload,
        remoteId: remoteId,
      );
      return;
    }
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.insert('pending_mutations', {
      'endpoint': endpoint,
      'method': method,
      'payload': jsonEncode(payload),
      'remote_id': remoteId?.toString(),
      'pendiente_sync': 'SI',
      'accion_pendiente': method,
      'fecha_local': now,
      'created_at': now,
      'synced': 0,
    });
  }

  Future<int> pendingCount() async {
    if (kIsWeb) {
      final pending = await _pendingMutationsWeb();
      return pending.where((item) => item['synced'] != true).length;
    }
    final db = await database;
    final result = await db.rawQuery(
      'select count(*) as total from pending_mutations where synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> syncPending(OrdsClient client) async {
    if (kIsWeb) {
      return _syncPendingWeb(client);
    }
    final db = await database;
    final rows = await db.query(
      'pending_mutations',
      where: 'synced = 0',
      orderBy: 'created_at',
    );
    var synced = 0;
    for (final row in rows) {
      final id = row['id'] as int;
      final endpoint = row['endpoint'] as String;
      final method = row['method'] as String;
      final payload = Map<String, dynamic>.from(
        jsonDecode(row['payload'] as String) as Map,
      );
      try {
        if (method == 'POST') {
          await client.post(endpoint, payload);
        } else if (method == 'PUT') {
          await client.put(endpoint, row['remote_id'], payload);
        } else if (method == 'DELETE') {
          await client.delete(endpoint, row['remote_id']);
        }
        await db.update(
          'pending_mutations',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
        synced++;
      } catch (_) {
        break;
      }
    }
    return synced;
  }

  Future<void> saveAura(AuraModel item, {bool pending = false}) async {
    if (kIsWeb) {
      await _saveAuraWeb(item, pending: pending);
      if (pending) {
        await addPendingMutation(
          endpoint: OrdsEndpoints.aura,
          method: 'POST',
          payload: item.toJson()..remove('id_aura'),
        );
      }
      return;
    }
    final db = await database;
    await db.insert('aura_history', {
      'remote_id': item.idAura > 0 ? '${item.idAura}' : null,
      'id_usuario': item.idUsuario,
      'tipo': item.tipo,
      'mensaje': item.mensaje,
      'respuesta': item.respuesta,
      'contexto': item.contexto,
      'id_referencia': item.idReferencia,
      'fecha_creacion': (item.fecha ?? DateTime.now()).toIso8601String(),
      'pendiente_sync': pending ? 'SI' : 'NO',
      'accion_pendiente': pending ? 'CREATE' : null,
    });
    if (pending) {
      await addPendingMutation(
        endpoint: OrdsEndpoints.aura,
        method: 'POST',
        payload: item.toJson()..remove('id_aura'),
      );
    }
  }

  Future<List<AuraModel>> readAura(int idUsuario) async {
    if (kIsWeb) {
      return _readAuraWeb(idUsuario);
    }
    final db = await database;
    final rows = await db.query(
      'aura_history',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'fecha_creacion',
    );
    return rows
        .map((row) => AuraModel.fromJson({
              'id_aura': row['remote_id'] ?? row['local_id'],
              'id_usuario': row['id_usuario'],
              'tipo': row['tipo'],
              'mensaje': row['mensaje'],
              'respuesta': row['respuesta'],
              'contexto': row['contexto'],
              'id_referencia': row['id_referencia'],
              'fecha_creacion': row['fecha_creacion'],
            }))
        .toList();
  }

  Future<void> clearAura(int idUsuario) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final rows = await _auraRowsWeb();
      rows.removeWhere((row) => row['id_usuario'] == idUsuario);
      await prefs.setString(_auraKey, jsonEncode(rows));
      return;
    }
    final db = await database;
    await db.delete(
      'aura_history',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );
  }

  String _collectionKey(String collection) =>
      'finasangre_cache_${collection.replaceAll('/', '_')}';

  static const _pendingKey = 'finasangre_pending_mutations';
  static const _auraKey = 'finasangre_aura_history';

  Future<void> _saveCollectionWeb(
    String collection,
    List<Map<String, dynamic>> rows,
    String idKey,
  ) async {
    debugPrint(webStorageMessage);
    final now = DateTime.now().toIso8601String();
    final wrapped = rows.asMap().entries.map((entry) {
      final row = entry.value;
      final id = '${row[idKey] ?? row['id'] ?? entry.key}';
      return {
        'local_id': entry.key + 1,
        'remote_id': id,
        'pendiente_sync': 'NO',
        'accion_pendiente': null,
        'fecha_local': now,
        'updated_at': now,
        'payload': row,
      };
    }).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_collectionKey(collection), jsonEncode(wrapped));
  }

  Future<List<Map<String, dynamic>>> _readCollectionWeb(
    String collection,
  ) async {
    debugPrint(webStorageMessage);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_collectionKey(collection));
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded.whereType<Map>().map((row) {
      final payload = row['payload'];
      if (payload is Map) return Map<String, dynamic>.from(payload);
      return <String, dynamic>{};
    }).where((row) => row.isNotEmpty).toList();
  }

  Future<List<Map<String, dynamic>>> _pendingMutationsWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> _writePendingMutationsWeb(
    List<Map<String, dynamic>> rows,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingKey, jsonEncode(rows));
  }

  Future<void> _addPendingMutationWeb({
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    dynamic remoteId,
  }) async {
    debugPrint(webStorageMessage);
    final rows = await _pendingMutationsWeb();
    final now = DateTime.now().toIso8601String();
    rows.add({
      'local_id': rows.length + 1,
      'endpoint': endpoint,
      'method': method,
      'payload': payload,
      'remote_id': remoteId?.toString(),
      'pendiente_sync': 'SI',
      'accion_pendiente': method,
      'fecha_local': now,
      'created_at': now,
      'synced': false,
    });
    await _writePendingMutationsWeb(rows);
  }

  Future<int> _syncPendingWeb(OrdsClient client) async {
    final rows = await _pendingMutationsWeb();
    var synced = 0;
    for (final row in rows.where((item) => item['synced'] != true)) {
      final endpoint = row['endpoint'] as String;
      final method = row['method'] as String;
      final payload = Map<String, dynamic>.from(row['payload'] as Map);
      try {
        if (method == 'POST') {
          await client.post(endpoint, payload);
        } else if (method == 'PUT') {
          await client.put(endpoint, row['remote_id'], payload);
        } else if (method == 'DELETE') {
          await client.delete(endpoint, row['remote_id']);
        }
        row['synced'] = true;
        row['pendiente_sync'] = 'NO';
        synced++;
      } catch (_) {
        break;
      }
    }
    await _writePendingMutationsWeb(rows);
    return synced;
  }

  Future<List<Map<String, dynamic>>> _auraRowsWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_auraKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> _saveAuraWeb(AuraModel item, {bool pending = false}) async {
    debugPrint(webStorageMessage);
    final prefs = await SharedPreferences.getInstance();
    final rows = await _auraRowsWeb();
    rows.add({
      'local_id': rows.length + 1,
      'remote_id': item.idAura > 0 ? '${item.idAura}' : null,
      'id_usuario': item.idUsuario,
      'tipo': item.tipo,
      'mensaje': item.mensaje,
      'respuesta': item.respuesta,
      'contexto': item.contexto,
      'id_referencia': item.idReferencia,
      'fecha_creacion': (item.fecha ?? DateTime.now()).toIso8601String(),
      'pendiente_sync': pending ? 'SI' : 'NO',
      'accion_pendiente': pending ? 'CREATE' : null,
    });
    await prefs.setString(_auraKey, jsonEncode(rows));
  }

  Future<List<AuraModel>> _readAuraWeb(int idUsuario) async {
    debugPrint(webStorageMessage);
    final rows = await _auraRowsWeb();
    return rows.where((row) => row['id_usuario'] == idUsuario).map((row) {
      return AuraModel.fromJson({
        'id_aura': row['remote_id'] ?? row['local_id'],
        'id_usuario': row['id_usuario'],
        'tipo': row['tipo'],
        'mensaje': row['mensaje'],
        'respuesta': row['respuesta'],
        'contexto': row['contexto'],
        'id_referencia': row['id_referencia'],
        'fecha_creacion': row['fecha_creacion'],
      });
    }).toList();
  }
}
