import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

Future<Directory?> safeDocumentsDirectory() async {
  if (kIsWeb) return null;
  return getApplicationDocumentsDirectory();
}
