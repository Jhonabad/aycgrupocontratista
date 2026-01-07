import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthServicesList {
  final Map<String, String> headers = {
    'apikey':
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s',
    'Authorization':
    'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s',
    'Content-Type': 'application/json',
  };

  final supabase = Supabase.instance.client;

  /// 🔹 Obtener todos los usuarios (RPC Supabase)
  Future<List<Map<String, dynamic>>> obtenerTodosUsuarios() async {
    final url = Uri.parse(
      'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_obtener_usuarios',
    );

    try {
      final response = await http.post(url, headers: headers);
      if (response.statusCode != 200) {
        throw Exception(
          'Error al obtener usuarios: ${response.statusCode} - ${response.body}',
        );
      }

      final dynamic data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Formato de respuesta inesperado.');
      }
    } catch (e) {
      print('❌ Error en obtenerTodosUsuarios: $e');
      rethrow;
    }
  }

  /// 🔹 Verificar sesión activa del usuario autenticado
  Future<bool> verificarSesionActiva() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      print('🚫 No hay usuario autenticado. Debes iniciar sesión.');
      return false;
    }

    print('✅ Usuario autenticado: ${user.email} (ID: ${user.id})');
    return true;
  }

  Future<String?> subirImagenUsuarioSupabase(File imagen, int idUsuario) async {
    try {
      print('⚙️ Subiendo imagen para usuario con ID: $idUsuario');

      final nombreArchivo =
          'usuario_${idUsuario}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 🔹 Subir archivo al bucket de Supabase Storage
      final uploadResponse = await supabase.storage
          .from('fotos_usuarios')
          .upload(nombreArchivo, imagen, fileOptions: const FileOptions(upsert: true));

      if (uploadResponse.isEmpty) {
        throw Exception('Error al subir el archivo al bucket.');
      }

      // 🔹 Obtener URL pública de la imagen
      final publicUrl =
      supabase.storage.from('fotos_usuarios').getPublicUrl(nombreArchivo);

      // 🔹 Llamar a la función RPC para actualizar la URL en la tabla "usuario"
      final url = Uri.parse(
        'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_actualizar_foto_usuario',
      );

      final body = jsonEncode({
        'p_id_usuario': idUsuario,
        'p_url': publicUrl,
      });

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Error al actualizar la foto en la BD: ${response.statusCode} - ${response.body}',
        );
      }
      print('Imagen subida y actualizada correctamente: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('🚨 Error al subir imagen: $e');
      return null;
    }
  }

}
