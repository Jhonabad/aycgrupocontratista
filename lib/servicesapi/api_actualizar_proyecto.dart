import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_config.dart';

class ActualizarProyectoService {
  Map<String, String> get headers => SupabaseConfig.headers;
  Future<Map<String, dynamic>> actualizarProyecto({
    required int idProyecto,
    required String nombreProyecto,
    required String ubicacion,
    required String tipoObra,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String observaciones,
    required List<Map<String, dynamic>> encargados,
    required List<Map<String, dynamic>> personal,
  }) async {
    final url = Uri.parse(
        'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_actualizar_proyecto');

    final body = jsonEncode({
      "p_id_proyecto": idProyecto,
      "p_nombre_proyecto": nombreProyecto,
      "p_ubicacion": ubicacion,
      "p_tipo_obra": tipoObra,
      "p_fecha_inicio": fechaInicio.toIso8601String().split('T').first,
      "p_fecha_fin": fechaFin.toIso8601String().split('T').first,
      "p_observaciones": observaciones,
      "p_encargados": encargados,
      "p_personal": personal,
    });

    try {
      print("🚀 Enviando datos al endpoint: $url");
      print("📦 Body: $body");

      final response = await http.post(url, headers: headers, body: body);

      print("📡 Status (actualizar proyecto): ${response.statusCode}");
      print("📩 Respuesta (actualizar proyecto): ${response.body}");

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          if (data['status'] == 'success') {
            return {
              "ok": true,
              "message": data['message'] ?? 'Proyecto actualizado correctamente.',
            };
          } else {
            return {
              "ok": false,
              "message": data['message'] ?? 'Error al actualizar proyecto.'
            };
          }
        }

        return {
          "ok": true,
          "message": "Proyecto actualizado correctamente.",
          "data": data
        };
      } else {
        return {
          "ok": false,
          "message":
          "Error HTTP ${response.statusCode}: ${response.body.isNotEmpty ? response.body : 'sin respuesta'}"
        };
      }
    } catch (e) {
      print("❌ Error en actualizarProyecto: $e");
      return {
        "ok": false,
        "message": "Excepción al actualizar proyecto: $e",
      };
    }
  }
  Future<Map<String, dynamic>> eliminarProyecto(int idProyecto) async {
    final url = Uri.parse(
        'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_eliminar_proyecto');

    final body = jsonEncode({"p_id_proyecto": idProyecto});

    try {
      print("🗑️ Enviando solicitud de eliminación...");
      print("📦 Body: $body");

      final response = await http.post(url, headers: headers, body: body);

      print("📡 Status (eliminar proyecto): ${response.statusCode}");
      print("📩 Respuesta (eliminar proyecto): ${response.body}");

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        return {
          "ok": data["status"] == "success",
          "message": data["message"] ?? "Operación realizada",
        };
      }

      return {
        "ok": false,
        "message":
        "Error HTTP ${response.statusCode}: ${response.body.isNotEmpty ? response.body : 'Sin respuesta'}"
      };
    } catch (e) {
      print("❌ Error en eliminarProyecto: $e");
      return {"ok": false, "message": "Excepción en eliminarProyecto: $e"};
    }
  }

}
