import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_config.dart';

class RegistroService {
  Map<String, String> get headers => SupabaseConfig.headers;

  /// 📦 Registra un nuevo usuario en Supabase
  Future<Map<String, dynamic>> registrarUsuario({
    required String nombreUsuario,
    required String correo,
    required String telefono,
    required String puestoLaboral,
    required String password,
    required DateTime fechaContrato,
    required int idRol,
  }) async {
    final url = Uri.parse(
      'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_registrar_usuario',
    );

    try {
      // 🔹 Cuerpo con los parámetros exactos de la función SQL
      final body = jsonEncode({
        'p_nombre_usuario': nombreUsuario,
        'p_correo': correo,
        'p_telefono': telefono,
        'p_puesto_laboral': puestoLaboral,
        'p_contraseña': password,
        'p_fecha_contrato': fechaContrato.toIso8601String(),
        'p_id_rol': idRol,
      });

      print('📤 Enviando datos a Supabase: $body');

      final response = await http.post(url, headers: headers, body: body);

      print('📡 Código de estado: ${response.statusCode}');
      print('📩 Respuesta Supabase: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        } else {
          return {
            'status': 'error',
            'message': 'Formato de respuesta inesperado',
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Error al registrar usuario',
          'codigo': response.statusCode,
          'detalles': response.body,
        };
      }
    } catch (e) {
      print('⚠️ Error de conexión o ejecución: $e');
      return {
        'status': 'error',
        'message': 'Error de conexión con Supabase',
        'detalles': e.toString(),
      };
    }
  }
}