import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../data/repositories/crud_repository.dart';

class CrudProvider<T> extends ChangeNotifier {
  CrudProvider(this.repository);

  final CrudRepository<T> repository;
  bool loading = false;
  String? error;
  List<T> items = [];

  bool get isEmpty => !loading && error == null && items.isEmpty;

  Future<void> cargar() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await repository.list().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      error = 'Tiempo de espera agotado. Revisa tu conexión.';
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> crear(T item) async {
    return mutate(() async => repository.create(item));
  }

  Future<bool> actualizar(T item) async {
    return mutate(() async => repository.update(item));
  }

  Future<bool> eliminar(dynamic id) async {
    return mutate(() async => repository.delete(id));
  }

  Future<bool> mutate(Future<void> Function() action) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await action().timeout(const Duration(seconds: 15));
      items = await repository.list().timeout(const Duration(seconds: 15));
      loading = false;
      notifyListeners();
      return true;
    } on TimeoutException {
      error = 'Tiempo de espera agotado. Revisa tu conexión.';
      loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }
}
