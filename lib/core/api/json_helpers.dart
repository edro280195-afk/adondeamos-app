import 'package:flutter/foundation.dart';

String safeStr(dynamic value) => value.toString();

String? safeStrOrNull(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  debugPrint('⚠️ JSON type mismatch: esperaba String?, recibió ${value.runtimeType} = $value');
  return value.toString();
}

double? safeDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  debugPrint('⚠️ JSON type mismatch: esperaba double?, recibió ${value.runtimeType} = $value');
  return null;
}
