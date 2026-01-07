import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthServicesAsistencia {
  final Map<String, String> headers = {
    'apikey':
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s',
    'Authorization':
    'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s',
    'Content-Type': 'application/json',
  };

  /// 🔹 Obtener asistencias desde Supabase
  Future<List<Map<String, dynamic>>> obtenerAsistencias({
    int? idUsuario,
    int? idProyecto,
    String? fecha,
  }) async {
    final uri = Uri.parse(
      'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_listar_asistencias',
    );

    final body = {
      "p_id_usuario": idUsuario,
      "p_id_proyecto": idProyecto,
      "p_fecha": fecha,
    }..removeWhere((key, value) => value == null);

    try {
      print('📡 Enviando filtros → $body');

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      print('📩 Código: ${response.statusCode}');
      print('📦 Respuesta: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Error al obtener asistencias: ${response.statusCode} - ${response.body}',
        );
      }

      final data = jsonDecode(response.body);

      if (data is! List) {
        throw Exception("Formato inesperado de respuesta: ${data.runtimeType}");
      }

      // 🔁 Normalizamos los datos para evitar errores por claves faltantes
      return data.map<Map<String, dynamic>>((item) {
        return {
          "id_asistencia": item["id_asistencia"],
          "id_usuario": item["id_usuario"],
          "id_proyecto": item["id_proyecto"],
          "nombre_usuario": item["nombre_usuario"],
          "nombre_proyecto": item["nombre_proyecto"],
          "fecha_asistencia": item["fecha_asistencia"],
          "fecha_entrada": item["fecha_entrada"],
          "fecha_salida": item["fecha_salida"],
          "estado_asistencia": item["estado_asistencia"],
          "foto_entrada": item["foto_entrada"],
          "foto_salida": item["foto_salida"],
          "ubicacion_entrada": item["ubicacion_entrada"],
          "ubicacion_salida": item["ubicacion_salida"],
        };
      }).toList();
    } catch (e) {
      print('❌ Error en obtenerAsistencias: $e');
      rethrow;
    }
  }
}

