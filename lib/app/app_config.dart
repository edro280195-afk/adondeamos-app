class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5172',
  );

  /// URL de producción. Cámbiala cuando tengas el dominio real en Render.
  static const String prodUrl = 'https://adondeamos-api.onrender.com';
}
