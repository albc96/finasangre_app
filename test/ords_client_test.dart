import 'package:finasangre_app/data/services/ords_client.dart';
import 'package:finasangre_app/data/models/herraje_model.dart';
import 'package:finasangre_app/data/repositories/herraje_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('getList sigue la paginacion de ORDS usando el link next', () async {
    final client = OrdsClient(
      baseUrl: 'https://example.test/ords/admin/',
      httpClient: MockClient((request) async {
        if (request.url.queryParameters['offset'] == '25') {
          return http.Response(
            '{"items":[{"id":2}],"hasMore":false}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          '{"items":[{"id":1}],"hasMore":true,'
          '"links":[{"rel":"next","href":"https://example.test/ords/admin/usuarios_finasangre/?offset=25"}]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final rows = await client.getList('usuarios_finasangre');

    expect(rows, [
      {'id': 1},
      {'id': 2},
    ]);
  });

  test('getById filtra desde la lista sin llamar endpoint/id', () async {
    final requested = <Uri>[];
    final client = OrdsClient(
      baseUrl: 'https://example.test/ords/admin/',
      httpClient: MockClient((request) async {
        requested.add(request.url);
        return http.Response(
          '{"items":[{"id_caballo":1,"nombre_caballo":"Tiger Cat"}],"hasMore":false}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final row = await client.getById('caballos_finasangre/', 'id_caballo', 1);

    expect(row?['nombre_caballo'], 'Tiger Cat');
    expect(requested.single.path, '/ords/admin/caballos_finasangre/');
  });

  test('no expone HTML crudo cuando ORDS devuelve una pagina de error',
      () async {
    final client = OrdsClient(
      httpClient: MockClient(
        (_) async => http.Response(
          '<!DOCTYPE html><html><body>Error gigante</body></html>',
          404,
          headers: {'content-type': 'text/html'},
        ),
      ),
    );

    expect(
      () => client.getList('caballos_finasangre/'),
      throwsA(
        isA<OrdsException>()
            .having((e) => e.message, 'message', isNot(contains('<html')))
            .having(
                (e) => e.message, 'message', contains('No se pudo conectar')),
      ),
    );
  });

  test('delete 404 muestra mensaje de handler ORDS personalizado', () async {
    final client = OrdsClient(
      httpClient: MockClient(
        (_) async => http.Response(
          '<!DOCTYPE html><html><body>Not found</body></html>',
          404,
          headers: {'content-type': 'text/html'},
        ),
      ),
    );

    expect(
      () => client.delete('caballos_finasangre/', 1),
      throwsA(
        isA<OrdsException>().having(
          (e) => e.message,
          'message',
          contains('Endpoint no configurado'),
        ),
      ),
    );
  });

  test('endpoint corto se normaliza a AutoREST real', () async {
    late http.Request captured;
    final client = OrdsClient(
      baseUrl: 'https://example.test/ords/admin/',
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response(
          '{"items":[],"hasMore":false}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await client.list('caballos');

    expect(captured.url.path, '/ords/admin/caballos_finasangre/');
  });

  test('post usa endpoint con slash final y headers JSON', () async {
    late http.Request captured;
    final client = OrdsClient(
      baseUrl: 'https://example.test/ords/admin/',
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response(
          '{"success":true}',
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await client.post('herrajes_finasangre', {'id_caballo': 1});

    expect(captured.url.path, '/ords/admin/herrajes_finasangre/');
    expect(captured.headers['Content-Type'], 'application/json');
    expect(captured.headers['Accept'], 'application/json');
  });

  test('crear herraje envia solo columnas aceptadas por AutoREST', () async {
    late http.Request captured;
    final client = OrdsClient(
      baseUrl: 'https://example.test/ords/admin/',
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response(
          '{"success":true}',
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final repository = HerrajeRepository(client);

    final fechaLocal = DateTime(2026, 4, 30, 23, 3);
    String two(int n) => n.toString().padLeft(2, '0');
    final fechaOrds = '${fechaLocal.year}-${two(fechaLocal.month)}-'
        '${two(fechaLocal.day)}T${two(fechaLocal.hour)}:'
        '${two(fechaLocal.minute)}:00Z';

    await repository.crear(
      HerrajeModel(
        idHerraje: 99,
        idCaballo: 1,
        idHerrador: 2,
        idCorral: 3,
        tipoHerraje: 'COMPLETO',
        fechaHerraje: fechaLocal,
        dia: 30,
        mes: 4,
        anio: 2026,
        hora: '23:03',
        observaciones: 'ok',
        fotoAntesUrl: 'antes.jpg',
        fotoDespuesUrl: 'despues.jpg',
      ),
    );

    expect(captured.url.path, '/ords/admin/herrajes_finasangre/');
    expect(captured.body, isNot(contains('id_herraje')));
    expect(captured.body, isNot(contains('dia')));
    expect(captured.body, isNot(contains('mes')));
    expect(captured.body, isNot(contains('anio')));
    expect(captured.body, isNot(contains('hora')));
    expect(captured.body, isNot(contains('foto_antes_url')));
    expect(captured.body, isNot(contains('foto_despues_url')));
    expect(captured.body, contains('"fecha_herraje":"$fechaOrds"'));
    expect(captured.body, isNot(contains('.000"')));
  });
}
