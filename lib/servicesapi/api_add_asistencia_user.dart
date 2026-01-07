import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiRegistrarAsistencia {
  static const Map<String, String> headers = {
    'apikey':
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s',
    'Authorization':
    'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s',
    'Content-Type': 'application/json',
  };

  // ===============================================================
  // REGISTRAR ASISTENCIA (entrada o salida)
  // ===============================================================
  static Future<Map<String, dynamic>> registrarAsistencia({
    required int idUsuario,
    required int idProyecto,
    required String fecha,
    required String hora,
    String? foto,       // OPCIONAL
    String? ubicacion,  // OBLIGATORIO EN TU APP
  }) async {
    final url = Uri.parse(
      'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_registrar_asistencia_admin',
    );

    final body = {
      'p_id_usuario': idUsuario,
      'p_id_proyecto': idProyecto,
      'p_fecha_asistencia': fecha,
      'p_hora': hora,
      'p_foto_asistencia': foto,     // si es null, Supabase lo acepta
      'p_ubicacion': ubicacion,
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print("📡 Registrar asistencia → ${response.statusCode}");
      print("📩 ${response.body}");

      final data = jsonDecode(response.body);

      return {
        "success": response.statusCode == 200,
        "accion": data["accion"],
        "mensaje": data["mensaje"],
        "registro": data["registro"],
        "estado_asistencia": data["estado_asistencia"]
      };
    } catch (e) {
      return {
        "success": false,
        "error": e.toString(),
      };
    }
  }
}
