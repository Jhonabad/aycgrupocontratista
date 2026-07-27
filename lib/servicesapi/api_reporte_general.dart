import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_config.dart';

class ReporteGeneralApi {
  static Map<String, String> get headers => SupabaseConfig.headers;

  /// 🔹 Obtener datos del reporte general desde Supabase
  static Future<List<Map<String, dynamic>>> obtenerReporteGeneral({
    required String tipo,
    required String persona,
    required String estado,
    String proyecto = 'Todos',
    String? fechaInicio,
    String? fechaFin,
  }) async {
    final url = Uri.parse(
        'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_reporte_general');

    final body = {
      "p_tipo": tipo.isEmpty ? 'Todos' : tipo,
      "p_persona": persona.isEmpty ? 'Todos' : persona,
      "p_estado": estado.isEmpty ? 'Todos' : estado,
      "p_proyecto": proyecto.isEmpty ? 'Todos' : proyecto,
      "p_fecha_inicio": fechaInicio,
      "p_fecha_fin": fechaFin,
    };

    try {
      final resp = await http.post(url, headers: headers, body: jsonEncode(body));

      print("📡 Reporte general → ${resp.statusCode}");
      print("📩 ${resp.body}");

      if (resp.statusCode != 200) {
        print("❌ Error al obtener datos del reporte general");
        return [];
      }

      final data = jsonDecode(resp.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('data')) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        return [];
      }
    } catch (e) {
      print("❌ Error obtener reporte general: $e");
      return [];
    }
  }

  /// 🔹 Exportar reporte PDF (cuando esté habilitado)
  static Future<bool> exportarReportePDF({
    required String tipo,
    required String persona,
    required String estado,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    final url = Uri.parse(
        'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_exportar_reporte_pdf');

    final body = {
      "p_tipo": tipo,
      "p_persona": persona,
      "p_estado": estado,
      "p_fecha_inicio": fechaInicio,
      "p_fecha_fin": fechaFin,
    };

    try {
      final resp = await http.post(url, headers: headers, body: jsonEncode(body));
      print("📡 Exportar PDF → ${resp.statusCode}");
      print("📩 ${resp.body}");
      return resp.statusCode == 200;
    } catch (e) {
      print("❌ Error exportando PDF: $e");
      return false;
    }
  }
}
