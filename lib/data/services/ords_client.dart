import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';

class OrdsException implements Exception {
  OrdsException(this.message);
  final String message;

  @override
  String toString() => message;
}

class OrdsClient {
  static const unsupportedDirectMutationMessage = 'Endpoint no configurado';
  static const _timeout = Duration(seconds: 15);
  static const _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  static const _acceptJsonHeaders = {'Accept': 'application/json'};

  static const _autoRestEndpoints = {
    'caballos': 'caballos_finasangre',
    'caballos_finasangre': 'caballos_finasangre',
    'corrales': 'corrales_finasangre',
    'corrales_finasangre': 'corrales_finasangre',
    'preparadores': 'preparadores_finasangre',
    'preparadores_finasangre': 'preparadores_finasangre',
    'herradores': 'herradores_finasangre',
    'herradores_finasangre': 'herradores_finasangre',
    'herrajes': 'herrajes_finasangre',
    'herrajes_finasangre': 'herrajes_finasangre',
    'usuarios': 'usuarios_finasangre',
    'usuarios_finasangre': 'usuarios_finasangre',
    'suscripciones': 'suscripciones_finasangre',
    'suscripciones_finasangre': 'suscripciones_finasangre',
    'reportes_mensuales': 'reportes_mensuales_finasangre',
    'reportes_mensuales_finasangre': 'reportes_mensuales_finasangre',
    'aura': 'aura_finasangre',
    'aura_finasangre': 'aura_finasangre',
    'auditoria': 'auditoria_finasangre',
    'auditoria_finasangre': 'auditoria_finasangre',
  };

  static const _customMutationEndpoints = {
    'caballos': 'caballos',
    'caballos_finasangre': 'caballos',
    'corrales': 'corrales',
    'corrales_finasangre': 'corrales',
    'preparadores': 'preparadores',
    'preparadores_finasangre': 'preparadores',
    'herradores': 'herradores',
    'herradores_finasangre': 'herradores',
    'herrajes': 'herrajes',
    'herrajes_finasangre': 'herrajes',
    'usuarios': 'usuarios',
    'usuarios_finasangre': 'usuarios',
  };

  OrdsClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        _baseUrl = _ensureTrailingSlash(baseUrl ?? AppConfig.ordsBaseUrl);

  final http.Client _http;
  final String _baseUrl;

  Future<List<Map<String, dynamic>>> list(String endpoint) async {
    final rows = <Map<String, dynamic>>[];
    Uri? next = _autoRestUri(endpoint);

    while (next != null) {
      final response = await _send(
        label: 'GET $next',
        request: () => _http.get(next!, headers: _acceptJsonHeaders),
      );
      final body = _decode(response, endpoint);
      final items = body['items'];
      if (items is List) {
        rows.addAll(
          items.whereType<Map>().map((item) => Map<String, dynamic>.from(item)),
        );
      } else if (body.isNotEmpty) {
        rows.add(body);
      }
      next = _nextUri(body);
    }

    return rows;
  }

  Future<Map<String, dynamic>> create(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final uri = _postUsesCustom(endpoint)
        ? _customUri(endpoint)
        : _autoRestUri(endpoint);
    final response = await _send(
      label: 'POST $uri',
      payload: data,
      request: () =>
          _http.post(uri, headers: _jsonHeaders, body: jsonEncode(data)),
    );
    return _decode(response, endpoint);
  }

  Future<Map<String, dynamic>> update(
    String endpoint,
    dynamic id,
    Map<String, dynamic> data,
  ) async {
    final uri = _customUri(endpoint, id: id, requireMapped: true);
    final response = await _send(
      label: 'PUT $uri',
      payload: data,
      request: () =>
          _http.put(uri, headers: _jsonHeaders, body: jsonEncode(data)),
    );
    if (response.statusCode == 404) {
      throw OrdsException(unsupportedDirectMutationMessage);
    }
    return _decode(response, '$endpoint/$id');
  }

  Future<void> delete(String endpoint, dynamic id) async {
    final uri = _customUri(endpoint, id: id, requireMapped: true);
    final response = await _send(
      label: 'DELETE $uri',
      request: () => _http.delete(uri, headers: _acceptJsonHeaders),
    );
    if (response.statusCode == 404) {
      throw OrdsException(unsupportedDirectMutationMessage);
    }
    _decode(response, '$endpoint/$id');
  }

  Future<Map<String, dynamic>> deleteWithBody(
    String endpoint,
    dynamic id,
    Map<String, dynamic> data,
  ) async {
    final uri = _customUri(endpoint, id: id, requireMapped: true);
    final response = await _send(
      label: 'DELETE $uri',
      payload: data,
      request: () async {
        final request = http.Request('DELETE', uri)
          ..headers.addAll(_jsonHeaders)
          ..body = jsonEncode(data);
        final streamed = await _http.send(request);
        return http.Response.fromStream(streamed);
      },
    );
    if (response.statusCode == 404) {
      throw OrdsException(unsupportedDirectMutationMessage);
    }
    return _decode(response, '$endpoint/$id');
  }

  Future<List<Map<String, dynamic>>> getList(String endpoint) => list(endpoint);

  Future<Map<String, dynamic>> getOne(String endpoint, dynamic id) async {
    final uri = _autoRestUri(endpoint, id: id);
    final response = await _send(
      label: 'GET $uri',
      request: () => _http.get(uri, headers: _acceptJsonHeaders),
    );
    return _decode(response, '$endpoint/$id');
  }

  Future<Map<String, dynamic>?> getById(
    String endpoint,
    String idKey,
    dynamic id,
  ) async {
    final rows = await list(endpoint);
    for (final row in rows) {
      if ('${row[idKey] ?? row['id']}' == '$id') return row;
    }
    return null;
  }

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) {
    return create(endpoint, data);
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    dynamic id,
    Map<String, dynamic> data,
  ) {
    return update(endpoint, id, data);
  }

  Uri _autoRestUri(String endpoint, {dynamic id}) {
    final clean = _cleanEndpoint(endpoint);
    final mapped = _autoRestEndpoints[clean] ?? clean;
    return _joinUri(_baseUrl, mapped, id: id, trailingSlash: true);
  }

  Uri _customUri(String endpoint, {dynamic id, bool requireMapped = false}) {
    final clean = _cleanEndpoint(endpoint);
    final mapped = _customMutationEndpoints[clean];
    if (mapped == null && requireMapped) {
      throw OrdsException(unsupportedDirectMutationMessage);
    }
    return _joinUri(
      AppConfig.ordsCustomBaseUrl,
      mapped ?? clean,
      id: id,
      trailingSlash: false,
    );
  }

  bool _postUsesCustom(String endpoint) {
    final clean = _cleanEndpoint(endpoint);
    return clean == OrdsEndpoints.generarReporte ||
        clean == OrdsEndpoints.generarReporteTodos ||
        clean == '${OrdsEndpoints.aura}/limpiar';
  }

  Future<http.Response> _send({
    required String label,
    required Future<http.Response> Function() request,
    Map<String, dynamic>? payload,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        _debugRequest(label, payload, attempt);
        final response = await request().timeout(_timeout);
        _debugResponse(response);
        return response;
      } on TimeoutException catch (_) {
        if (attempt == 0) continue;
        throw OrdsException('No se pudo conectar con ORDS');
      } on SocketException catch (_) {
        if (attempt == 0) continue;
        throw OrdsException('No se pudo conectar con ORDS');
      } on http.ClientException catch (_) {
        if (attempt == 0) continue;
        throw OrdsException('No se pudo conectar con ORDS');
      }
    }
    throw OrdsException('No se pudo conectar con ORDS');
  }

  Map<String, dynamic> _decode(http.Response response, String label) {
    final contentType = response.headers['content-type'] ?? '';
    final body = response.body.trim();
    if (_looksLikeHtml(body)) {
      debugPrint('BODY HTML ORDS: ${_summarize(body)}');
      throw OrdsException('No se pudo conectar con ORDS');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final clean = _messageFromBody(body);
      throw OrdsException(clean ?? '$label respondio ${response.statusCode}.');
    }
    if (body.isEmpty) return {};
    if (!contentType.toLowerCase().contains('json')) {
      debugPrint('BODY no JSON: ${_summarize(body)}');
      throw OrdsException('No se pudo conectar con ORDS');
    }
    final decoded = _decodeJsonBody(body, label);
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final success = map['success'];
      if (success == false || map['ok'] == false) {
        throw OrdsException(_messageFromMap(map) ?? 'Operacion rechazada.');
      }
      return map;
    }
    if (decoded is List) return {'items': decoded};
    return {'value': decoded};
  }

  bool _looksLikeHtml(String body) {
    final lower = body.toLowerCase();
    return lower.contains('<!doctype html') ||
        lower.contains('<html') ||
        lower.contains('<body') ||
        lower.contains('</html>');
  }

  dynamic _decodeJsonBody(String body, String label) {
    try {
      return jsonDecode(body);
    } on FormatException {
      debugPrint('BODY JSON invalido: ${_summarize(body)}');
      throw OrdsException('$label devolvio JSON invalido.');
    }
  }

  String? _messageFromBody(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return _messageFromMap(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return _looksLikeHtml(body) ? null : _summarize(body);
    }
    return null;
  }

  String? _messageFromMap(Map<String, dynamic> map) {
    for (final key in ['message', 'mensaje', 'error', 'detail', 'title']) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  Uri? _nextUri(Map<String, dynamic> body) {
    if (body['hasMore'] != true) return null;
    final links = body['links'];
    if (links is! List) return null;
    for (final link in links.whereType<Map>()) {
      if (link['rel'] == 'next' && link['href'] is String) {
        return Uri.parse(link['href'] as String);
      }
    }
    return null;
  }

  void _debugRequest(String label, Map<String, dynamic>? payload, int attempt) {
    debugPrint('${attempt == 0 ? '' : 'RETRY '}ORDS $label');
    if (payload != null) {
      debugPrint('PAYLOAD: ${_summarize(jsonEncode(payload))}');
    }
  }

  void _debugResponse(http.Response response) {
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${_summarize(response.body)}');
  }

  static String _cleanEndpoint(String endpoint) {
    return endpoint.replaceAll(RegExp(r'^/+|/+$'), '');
  }

  static String _ensureTrailingSlash(String value) {
    return value.endsWith('/') ? value : '$value/';
  }

  static Uri _joinUri(
    String base,
    String endpoint, {
    dynamic id,
    required bool trailingSlash,
  }) {
    final cleanBase = _ensureTrailingSlash(base);
    final cleanEndpoint = _cleanEndpoint(endpoint);
    final cleanId = id == null ? '' : '/${Uri.encodeComponent('$id')}';
    final slash = trailingSlash ? '/' : '';
    return Uri.parse('$cleanBase$cleanEndpoint$cleanId$slash');
  }

  static String _summarize(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 800) return compact;
    return '${compact.substring(0, 800)}...';
  }
}
