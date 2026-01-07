import 'dart:convert';
import 'package:http/http.dart' as http;

class CrearProyectoService {
  final String baseUrl = 'https://xciuisfqkbqgajgctlae.supabase.co';

  final Map<String, String> headers = {
    'apikey':
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s',
    'Authorization':
    'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s',
    'Content-Type': 'application/json',
  };

  /// 🔹 Registrar un nuevo proyecto con encargados y personal
  Future<Map<String, dynamic>> registrarProyecto({
    required String nombreProyecto,
    required String ubicacion,
    required String tipoObra,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String observaciones,
    required List<Map<String, dynamic>> encargados,
    required List<Map<String, dynamic>> personal,
  }) async {
    final url = Uri.parse('$baseUrl/rest/v1/rpc/fn_registrar_proyecto');

    // CONSTRUCCIÓN EXACTA DEL BODY PARA SUPABASE
    final Map<String, dynamic> body = {
      "p_nombre_proyecto": nombreProyecto,
      "p_ubicacion": ubicacion,
      "p_tipo_obra": tipoObra,
      "p_fecha_inicio": fechaInicio.toIso8601String().split('T').first,
      "p_fecha_fin": fechaFin.toIso8601String().split('T').first,
      "p_observaciones": observaciones,
      "p_encargados": encargados,
      "p_personal": personal
    };

    try {
      print("🚀 Enviando solicitud a Supabase: $url");
      print("📦 Body enviado: ${jsonEncode(body)}");

      final response =
      await http.post(url, headers: headers, body: jsonEncode(body));

      print("📡 Status: ${response.statusCode}");
      print("📩 Respuesta Supabase: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          "ok": data['status'] == 'success',
          "message": data['message'],
          "id_proyecto": data['id_proyecto'],
        };
      } else {
        return {
          "ok": false,
          "message":
          "Error HTTP ${response.statusCode}: ${response.body.isNotEmpty ? response.body : 'sin respuesta'}"
        };
      }
    } catch (e) {
      print("❌ Error al registrar proyecto: $e");
      return {
        "ok": false,
        "message": "Excepción en registrarProyecto: $e",
      };
    }
  }
}
