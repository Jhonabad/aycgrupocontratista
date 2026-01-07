import 'dart:convert';
import 'package:http/http.dart' as http;

class EditServicesPermisos {
  final Map<String, String> headers = {
    'apikey':
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s',
    'Authorization':
    'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s',
    'Content-Type': 'application/json',
  };

  /// 🔹 Editar un permiso existente
  Future<Map<String, dynamic>> editarPermiso({
    required int idPermiso,
    required String tipoPermiso,
    required String fechaInicio,
    required String fechaFin,
    required String motivo,
    required String estado,
    required String mensajeAdmin,
  }) async {
    final url = Uri.parse(
      'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_editar_permiso',
    );

    final body = jsonEncode({
      'p_id_permisos': idPermiso,
      'p_tipo_permiso': tipoPermiso,
      'p_fecha_inicio': fechaInicio,
      'p_fecha_fin': fechaFin,
      'p_motivo': motivo,
      'p_estado_permiso': estado,
      'p_mensaje_admin': mensajeAdmin,
    });

    try {
      print('📡 Llamando RPC fn_editar_permiso...');
      print('📤 Body: $body');

      final response = await http.post(url, headers: headers, body: body);

      print('📩 Código: ${response.statusCode}');
      print('📩 Respuesta: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'success': true,
          'data': response.body.isNotEmpty ? jsonDecode(response.body) : null,
        };
      } else {
        return {
          'success': false,
          'error': 'Error ${response.statusCode}: ${response.body}',
        };
      }

    } catch (e) {
      print('❌ Error en editarPermiso: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> eliminarPermiso(int idPermiso) async {
    final url = Uri.parse(
        'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_eliminar_permiso'
    );

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"p_id_permisos": idPermiso}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          "ok": data["status"] == "success",
          "message": data["message"]
        };
      }

      return {
        "ok": false,
        "message": "Error HTTP ${response.statusCode}"
      };

    } catch (e) {
      return {
        "ok": false,
        "message": "Excepción: $e"
      };
    }
  }


}
