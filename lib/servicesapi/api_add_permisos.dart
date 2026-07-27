import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_config.dart';

class AddPermisoAdminService {
  Map<String, String> get headers => SupabaseConfig.headers;

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
