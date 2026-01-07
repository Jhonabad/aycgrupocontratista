import 'dart:convert';
import 'package:http/http.dart' as http;

class AddPermisoAdminService {
  final Map<String, String> headers = {
    'apikey':
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s',
    'Authorization':
    'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s',
    'Content-Type': 'application/json',
  };

  final String urlRpc =
      'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_insertar_permiso';

  Future<Map<String, dynamic>> registrarPermisoUsuario({
    required int idUsuario,
    required String tipoPermiso,
    required String fechaInicio,
    required String fechaFin,
    required String motivo,
  }) async {
    final body = jsonEncode({
      'p_id_usuario': idUsuario,
      'p_tipo_permiso': tipoPermiso,
      'p_fecha_inicio': fechaInicio,
      'p_fecha_fin': fechaFin,
      'p_motivo': motivo,
      'p_estado_permiso': "Pendiente",
    });

    return _postPermiso(body);
  }

  /// ----------------------------------------------------
  /// ⭐ ADMIN → Puede elegir estado
  /// ----------------------------------------------------
  Future<Map<String, dynamic>> registrarPermisoAdmin({
    required int idUsuario,
    required String tipoPermiso,
    required String fechaInicio,
    required String fechaFin,
    required String motivo,
    required String estadoPermiso,
  }) async {
    final body = jsonEncode({
      'p_id_usuario': idUsuario,
      'p_tipo_permiso': tipoPermiso,
      'p_fecha_inicio': fechaInicio,
      'p_fecha_fin': fechaFin,
      'p_motivo': motivo,
      'p_estado_permiso': estadoPermiso,
    });

    return _postPermiso(body);
  }

  /// ----------------------------------------------------
  /// ⭐ MÉTODO COMPARTIDO
  /// ----------------------------------------------------
  Future<Map<String, dynamic>> _postPermiso(String body) async {
    final url = Uri.parse(urlRpc);

    try {
      print('📡 POST → $url');
      print('📤 Body: $body');

      final res = await http.post(url, headers: headers, body: body);

      print('📩 Código: ${res.statusCode}');
      print('📩 Respuesta: ${res.body}');

      if (res.statusCode == 200) {
        return {'success': true, 'data': res.body};
      }

      return {
        'success': false,
        'error': 'Error ${res.statusCode}: ${res.body}',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
