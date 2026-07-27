import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'supabase_config.dart';

class AsistenciaAdminApi {
  static Map<String, String> get headers => SupabaseConfig.headers;
// 🔹 LISTAR USUARIOS POR PROYECTO
  static Future<List<Map<String, dynamic>>> obtenerUsuariosPorProyecto(int idProyecto) async {
    final url = Uri.parse(
      'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_usuarios_por_proyecto',
    );

    final body = {"p_id_proyecto": idProyecto};

    try {
      final resp = await http.post(url, headers: headers, body: jsonEncode(body));

      print("📡 Listar usuarios por proyecto → ${resp.statusCode}");
      print("📩 ${resp.body}");

      if (resp.statusCode != 200) return [];

      final data = jsonDecode(resp.body);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print("❌ Error obtener usuarios por proyecto: $e");
      return [];
    }
  }


    //LISTAR USUARIOS (trabajadores)
    static Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    final url = Uri.parse('https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_obtener_usuarios');

    try {
      final resp = await http.post(url, headers: headers);

      print("📡 Listar usuarios → ${resp.statusCode}");
      print("📩 ${resp.body}");

      if (resp.statusCode != 200) return [];

      final data = jsonDecode(resp.body);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print("❌ Error obteniendo usuarios: $e");
      return [];
    }
  }
  //  LISTAR PROYECTOS POR USUARIO
    static Future<List<Map<String, dynamic>>> obtenerProyectosPorUsuario(
      int idUsuario) async {
    final url = Uri.parse('https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_proyectos_por_usuario');

    final body = {"p_id_usuario": idUsuario};

    try {
      final resp =
      await http.post(url, headers: headers, body: jsonEncode(body));

      print("📡 Listar proyectos usuario → ${resp.statusCode}");
      print("📩 ${resp.body}");

      if (resp.statusCode != 200) return [];

      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } catch (e) {
      print("❌ Error obtener proyectos: $e");
      return [];
    }
  }
  //  FILTRAR ASISTENCIAS (usuario + proyecto + fecha)
  static Future<List<Map<String, dynamic>>> obtenerAsistenciasFiltradas({
    required int idUsuario,
    required int idProyecto,
    required String fecha,
  }) async {
    final url = Uri.parse('https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_filtar_asistencias');

    final body = {
      "p_id_usuario": idUsuario,
      "p_id_proyecto": idProyecto,
      "p_fecha": fecha,
    };

    try {
      final resp =
      await http.post(url, headers: headers, body: jsonEncode(body));

      print("📡 Filtrar asistencias → ${resp.statusCode}");
      print("📩 ${resp.body}");

      if (resp.statusCode != 200) return [];

      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } catch (e) {
      print("❌ Error obtener asistencias: $e");
      return [];
    }
  }
  //  OBTENER ASISTENCIA POR ID

  static Future<Map<String, dynamic>?> obtenerAsistenciaPorId(
      int idAsistencia) async {
    final url = Uri.parse('https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/asistencia?id_asistencia=eq.$idAsistencia');

    try {
      final resp = await http.get(url, headers: headers);

      print("📡 Obtener asistencia ID → ${resp.statusCode}");
      print("📩 ${resp.body}");

      if (resp.statusCode != 200) return null;

      final data = jsonDecode(resp.body);
      if (data is List && data.isNotEmpty) {
        return data.first;
      }

      return null;
    } catch (e) {
      print("❌ Error obtener asistencia: $e");
      return null;
    }
  }
    //  EDITAR ASISTENCIA (entrada y salida)
  // Estado se calcula automáticamente en el RPC
    static Future<bool> editarAsistencia({
    required int idAsistencia,
    required String entrada,
    required String salida,
  }) async {
    final url = Uri.parse('https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_actualizar_asistencia');

    final body = {
      "p_id_asistencia": idAsistencia,
      "p_entrada": entrada,
      "p_salida": salida,
    };

    try {
      final resp =
      await http.post(url, headers: headers, body: jsonEncode(body));

      print("📡 Editar asistencia → ${resp.statusCode}");

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        return true;
      } else {
        print("❌ Error al actualizar asistencia → ${resp.statusCode}");
        print("📩 ${resp.body}");
        return false;
      }
    } catch (e) {
      print("❌ Excepción al editar asistencia: $e");
      return false;
    }
  }
  // ELIMINAR ASISTENCIA

  static Future<bool> eliminarAsistencia(int idAsistencia) async {
    final url = Uri.parse(
        "https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/asistencia?id_asistencia=eq.$idAsistencia");
    try {
      final resp = await http.delete(url, headers: headers);

      print("🗑 Eliminar asistencia → ${resp.statusCode}");

      return resp.statusCode == 204;
    } catch (e) {
      print("❌ Error eliminar asistencia: $e");
      return false;
    }
  }
  static Future<List<Map<String, dynamic>>> obtenerHistorialAsistencias({
    required int idUsuario,
    required int idProyecto,
  }) async {
    final url = Uri.parse(
      'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_historial_asistencias',
    );

    final body = {
      'p_id_usuario': idUsuario,
      'p_id_proyecto': idProyecto,
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Error HTTP ${response.statusCode}: ${response.body}",
        );
      }

      final data = jsonDecode(response.body);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception("Error en historial: $e");
    }
  }

  }
