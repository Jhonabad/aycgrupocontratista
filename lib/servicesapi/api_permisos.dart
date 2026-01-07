import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthServicesPermisos {
  final Map<String, String> headers = {
    'apikey':
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s',
    'Authorization':
    'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s',
    'Content-Type': 'application/json',
  };

  /// 🔹 Obtener todos los permisos desde Supabase (RPC)
  Future<List<Map<String, dynamic>>> obtenerTodosPermisos() async {
    final url = Uri.parse(
      'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_listar_permisos',
    );

    try {
      print('📡 Consultando Supabase RPC: $url');
      final response = await http.post(url, headers: headers);

      print('📩 Código de respuesta: ${response.statusCode}');
      print('📩 Cuerpo: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'Error al obtener permisos: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(response.body);
      if (data == null) throw Exception('Respuesta vacía del servidor.');

      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Formato de respuesta inesperado: ${data.runtimeType}');
      }
    } catch (e) {
      print('❌ Error en obtenerTodosPermisos: $e');
      rethrow;
    }
  }

  /// 🔹 Actualizar estado del permiso (Aprobado / Rechazado)
  Future<Map<String, dynamic>> actualizarEstadoPermiso(
      int idPermiso, String nuevoEstado, String mensajeAdmin) async {
    final url = Uri.parse(
        'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_actualizar_estado_permiso'
    );

    final body = jsonEncode({
      "p_id_permisos": idPermiso,
      "p_estado": nuevoEstado,
      "p_mensaje_admin": mensajeAdmin
    });

    final response = await http.post(url, headers: headers, body: body);
    print('📡 Enviando a la API: $body');
    print('📩 Código respuesta: ${response.statusCode}');
    print('📩 Respuesta Supabase: ${response.body}');

    final data = jsonDecode(response.body);

    return data;
  }
  Future<List<Map<String, dynamic>>> listarPermisosUsuario(int idUsuario) async {
    final url = Uri.parse('https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_listar_permisos_usuario');

    final body = jsonEncode({"p_id_usuario": idUsuario});

    final resp = await http.post(url, headers: headers, body: body);

    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      print("❌ Error ${resp.statusCode}: ${resp.body}");
      return [];
    }
  }
}
