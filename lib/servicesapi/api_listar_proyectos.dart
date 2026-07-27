import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_config.dart';

class ListProyectService {
  Map<String, String> get headers => SupabaseConfig.headers;

  /// 📦 Obtiene todos los proyectos con su personal asignado
  Future<List<Map<String, dynamic>>> obtenerProyectos() async {
    final url = Uri.parse(
      'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_obtener_proyectos',
    );

    try {
      final response = await http.post(url, headers: headers);

      print('📡 Status (obtener proyectos): ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is! List) {
          throw Exception('⚠️ Formato de respuesta inesperado, se esperaba una lista.');
        }

        return data.map<Map<String, dynamic>>((item) {
          dynamic encargados = [];
          dynamic personal = [];

          try {
            encargados = (item['encargados'] is List)
                ? item['encargados']
                : jsonDecode(item['encargados'].toString());
          } catch (_) {
            encargados = [];
          }

          try {
            personal = (item['personal'] is List)
                ? item['personal']
                : jsonDecode(item['personal'].toString());
          } catch (_) {
            personal = [];
          }

          return {
            'id_proyecto': item['id_proyecto'],
            'nombre_proyecto': item['nombre_proyecto'] ?? '',
            'ubicacion': item['ubicacion'] ?? '',
            'tipo_obra': item['tipo_obra'] ?? '',
            'observaciones': item['observaciones'] ?? '',
            'fecha_inicio': item['fecha_inicio'] ?? '',
            'fecha_fin': item['fecha_fin'] ?? '',
            'estado_proyecto': item['estado_proyecto'] ?? '',
            'encargados': encargados,
            'personal': personal,
          };
        }).toList();
      } else {
        print('❌ Error HTTP ${response.statusCode}: ${response.body}');
        throw Exception('Error al obtener proyectos: ${response.body}');
      }
    } catch (e) {
      print('🚨 Error en obtenerProyectos: $e');
      rethrow;
    }
  }
}
