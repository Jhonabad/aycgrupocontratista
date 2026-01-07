import 'dart:convert';
import 'package:http/http.dart' as http;

class EditUserService {
  final Map<String, String> headers = {
    'apikey':
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s',
    'Authorization':
    'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s',
    'Content-Type': 'application/json',
  };

  /// 🔹 Actualizar usuario
  Future<Map<String, dynamic>> actualizarUsuario({
    required int usuarioId,
    required String nombreUsuario,
    required String correo,
    required String telefono,
    required String puestoLaboral,
    required bool estado_usuario,
  }) async {
    final url = Uri.parse(
      'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_editar_usuario',
    );

    final body = jsonEncode({
      'p_id_usuario': usuarioId,
      'p_nombre_usuario': nombreUsuario,
      'p_correo': correo,
      'p_telefono': telefono,
      'p_puesto_laboral': puestoLaboral,
      'p_estado_usuario': estado_usuario,
    });

    final response = await http.post(url, headers: headers, body: body);

    print('📡 Código de estado: ${response.statusCode}');
    print('📩 Respuesta Supabase: ${response.body}');

    // Manejo de errores básico
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar usuario: ${response.body}');
    }

    return jsonDecode(response.body);
  }


  /// 🔹 Eliminar usuario
  Future<Map<String, dynamic>> eliminarUsuario(int usuarioId) async {
    final url = Uri.parse('https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_eliminar_usuario');

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'p_id_usuario': usuarioId}),
    );

    print('📡 Código de estado: ${response.statusCode}');
    print('📩 Respuesta Supabase: ${response.body}');

    return jsonDecode(response.body);
  }
}
