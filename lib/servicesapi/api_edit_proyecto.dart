import 'dart:convert';
import 'package:http/http.dart' as http;

class ActualizarProyectoService {
  final String baseUrl =
      'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_actualizar_proyecto';

  final String apiKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s';

  Future<Map<String, dynamic>> actualizarProyecto({
    required int idProyecto,
    required String nombreProyecto,
    required String ubicacion,
    required String tipoObra,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String observaciones,
//    required List<dynamic> encargados,
    required List<dynamic> personal,
  }) async {
    final url = Uri.parse(baseUrl);

    final body = jsonEncode({
      'p_id_proyecto': idProyecto,
      'p_nombre_proyecto': nombreProyecto,
      'p_ubicacion': ubicacion,
      'p_tipo_obra': tipoObra,
      'p_fecha_inicio': fechaInicio.toIso8601String().split('T').first,
      'p_fecha_fin': fechaFin.toIso8601String().split('T').first,
      'p_observaciones': observaciones,
  //    'p_encargados':
    //  encargados.map((id) => {'id_usuario': id}).toList(), // IDs
      'p_personal': personal
          .map((p) => {
        'id_usuario': p['id_usuario'],
        'cargo_proyecto': p['cargo_proyecto'] ?? '',
        'fecha_asignacion': p['fecha_asignacion'] ?? '',
      })
          .toList(),
    });

    final response = await http.post(
      url,
      headers: {
        'apikey': apiKey,
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    print("📤 Enviando actualización de proyecto: $body");
    print("📩 Respuesta actualización: ${response.body}");

    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {
          'status': 'error',
          'message': 'Respuesta inválida del servidor: ${response.body}',
        };
      }
    } else {
      return {
        'status': 'error',
        'message': 'Error HTTP ${response.statusCode}: ${response.body}',
      };
    }
  }
}
