/// Configuración centralizada de Supabase.
class SupabaseConfig {
  /// URL base del proyecto Supabase
  static const String baseUrl = 'https://xciuisfqkbqgajgctlae.supabase.co';

  /// URL base para llamadas RPC
  static const String rpcUrl = '$baseUrl/rest/v1/rpc';

  /// URL base para REST directo
  static const String restUrl = '$baseUrl/rest/v1';

  /// URL base para Storage
  static const String storageUrl = '$baseUrl/storage/v1';


  static const String apiKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s';

  /// Headers comunes para todas las peticiones HTTP
  static const Map<String, String> headers = {
    'apikey': apiKey,
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  };
}
