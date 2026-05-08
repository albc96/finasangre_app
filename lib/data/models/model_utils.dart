Map<String, dynamic> normalizeKeys(Map<String, dynamic> json) {
  return json.map((key, value) => MapEntry(key.toLowerCase(), value));
}

int intValue(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String stringValue(dynamic value, [String fallback = '']) {
  final text = value?.toString();
  return text == null || text == 'null' ? fallback : text;
}

bool boolValue(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  final text = value?.toString().toUpperCase();
  if (text == 'SI' || text == 'S' || text == 'TRUE' || text == '1') {
    return true;
  }
  if (text == 'NO' || text == 'N' || text == 'FALSE' || text == '0') {
    return false;
  }
  return fallback;
}

DateTime? dateValue(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty || text == 'null') return null;
  return DateTime.tryParse(text);
}
