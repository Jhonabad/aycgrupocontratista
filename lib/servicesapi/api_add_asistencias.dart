import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AsistenciaAdminApiUser {
  static const Map<String, String> headers = {
    'apikey':
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s',
    'Authorization':
    'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjaXVpc2Zxa2JxZ2FqZ2N0bGFlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzk1OSwiZXhwIjoyMDc2MTkzOTU5fQ.lh_lGVO_CFFyZRsnrOFyjPJ7Bl5wrN8m00xQg7_yU6s',
    'Content-Type': 'application/json',
  };

  // ===============================================================
  // VALIDAR ENTRADA HOY
  // ===============================================================
  static Future<bool> validarEntradaHoy({
    required int idUsuario,
    required int idProyecto,
  }) async {
    final url = Uri.parse(
      'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_validar_entrada_hoy',
    );

    final body = {
      "p_id_usuario": idUsuario,
      "p_id_proyecto": idProyecto,
    };

    try {
      final resp =
      await http.post(url, headers: headers, body: jsonEncode(body));

      print("📡 validarEntradaHoy → ${resp.statusCode}");
      print("📩 Respuesta: ${resp.body}");

      if (resp.statusCode != 200) return false;

      final raw = resp.body.trim();

      if (raw == 'true') return true;
      if (raw == 'false') return false;

      try {
        final decoded = jsonDecode(raw);
        if (decoded is bool) return decoded;
        if (decoded is List && decoded.isNotEmpty && decoded.first is bool) {
          return decoded.first;
        }
      } catch (_) {}

      return false;
    } catch (e) {
      print("❌ Error validar entrada hoy: $e");
      return false;
    }
  }

  // ===============================================================
  // REGISTRAR ENTRADA
  // ===============================================================
  static Future<Map<String, dynamic>> registrarEntrada({
    required int idUsuario,
    required int idProyecto,
    required String ubicacion,
    String? fotoUrl,
  }) async {
    final url = Uri.parse(
      'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_registrar_entrada',
    );

    final nowLocal = DateTime.now().toLocal();
    final fechaHoraLocal = DateFormat('yyyy-MM-dd HH:mm:ss').format(nowLocal);

    final body = {
      "p_id_usuario": idUsuario,
      "p_id_proyecto": idProyecto,
      "p_foto": fotoUrl,
      "p_ubicacion": ubicacion,
      "p_fecha_hora": fechaHoraLocal,
    };

    try {
      final resp =
      await http.post(url, headers: headers, body: jsonEncode(body));

      print("📡 Registrar Entrada → ${resp.statusCode}");
      print("📅 Fecha enviada: $fechaHoraLocal");
      print("📩 ${resp.body}");

      return {
        "success": resp.statusCode == 200 || resp.statusCode == 204,
        "data": resp.body,
      };
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // ===============================================================
  // REGISTRAR SALIDA
  // ===============================================================
  static Future<Map<String, dynamic>> registrarSalida({
    required int idUsuario,
    required int idProyecto,
    required String ubicacion,
    String? fotoUrl,
  }) async {
    final url = Uri.parse(
      'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_registrar_salida',
    );

    final nowLocal = DateTime.now().toLocal();
    final fechaHoraLocal = DateFormat('yyyy-MM-dd HH:mm:ss').format(nowLocal);

    final body = {
      "p_id_usuario": idUsuario,
      "p_id_proyecto": idProyecto,
      "p_foto": fotoUrl, // ✅ URL pública
      "p_ubicacion": ubicacion,
      "p_fecha_hora": fechaHoraLocal,
    };

    try {
      final resp =
      await http.post(url, headers: headers, body: jsonEncode(body));

      print("📡 Registrar Salida → ${resp.statusCode}");
      print("📅 Fecha enviada: $fechaHoraLocal");
      print("📩 ${resp.body}");

      return {
        "success": resp.statusCode == 200 || resp.statusCode == 204,
        "data": resp.body,
      };
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // LISTAR PROYECTOS DE UN USUARIO
    Future<List<Map<String, dynamic>>> obtenerProyectosPorUsuario(
      int idUsuario) async {
    final url = Uri.parse(
      'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_listar_proyectos_por_usuario',
    );

    final body = {"p_id_usuario": idUsuario};

    try {
      final response =
      await http.post(url, headers: headers, body: jsonEncode(body));

      print("📡 Listar proyectos usuario → ${response.statusCode}");
      print("📩 ${response.body}");

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print("❌ Error obtener proyectos: $e");
      rethrow;
    }
  } Future<List<Map<String, dynamic>>> obtenerProyectosPorUsuarioAdmin(
      int idUsuario) async {
    final url = Uri.parse(
      'https://xciuisfqkbqgajgctlae.supabase.co/rest/v1/rpc/fn_listar_proyectos_por_usuario_admin',
    );

    final body = {"p_id_usuario": idUsuario};

    try {
      final response =
      await http.post(url, headers: headers, body: jsonEncode(body));

      print("📡 Listar proyectos usuario → ${response.statusCode}");
      print("📩 ${response.body}");

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print("❌ Error obtener proyectos: $e");
      rethrow;
    }
  }

  // ===============================================================
  // REGISTRO UNIFICADO (ENTRADA / SALIDA)
  // ===============================================================
  static Future<Map<String, dynamic>> registrarAsistenciaUsuario({
    required int idUsuario,
    required int idProyecto,
    required double latitud,
    required double longitud,
    String? fotoUrl,
  }) async {
    try {
      final yaRegistrado = await validarEntradaHoy(
        idUsuario: idUsuario,
        idProyecto: idProyecto,
      );

      if (!yaRegistrado) {
        final entrada = await registrarEntrada(
          idUsuario: idUsuario,
          idProyecto: idProyecto,
          ubicacion: "$latitud,$longitud",
          fotoUrl: fotoUrl,
        );

        if (entrada["data"].toString().contains("asistencia abierta")) {
          print("⚠️ Detección automática: cambiar a registro de salida");
          final salida = await registrarSalida(
            idUsuario: idUsuario,
            idProyecto: idProyecto,
            ubicacion: "$latitud,$longitud",
            fotoUrl: fotoUrl,
          );
          return {
            "success": salida["success"],
            "mensaje": salida["success"]
                ? "✅ Salida registrada correctamente (autoajuste)"
                : "❌ Error al registrar salida",
          };
        }

        return {
          "success": entrada["success"],
          "mensaje": entrada["success"]
              ? "✅ Entrada registrada correctamente"
              : "❌ Error al registrar entrada",
        };
      }

      final salida = await registrarSalida(
        idUsuario: idUsuario,
        idProyecto: idProyecto,
        ubicacion: "$latitud,$longitud",
        fotoUrl: fotoUrl,
      );

      return {
        "success": salida["success"],
        "mensaje": salida["success"]
            ? "✅ Salida registrada correctamente"
            : "❌ Error al registrar salida",
      };
    } catch (e) {
      print("❌ Error registrar asistencia usuario: $e");
      return {"success": false, "mensaje": "Error interno: $e"};
    }
  }

  // ===============================================================
  // SUBIR FOTO A SUPABASE STORAGE
  // ===============================================================
  static Future<String?> subirFotoAsistencia(
      String base64Foto, String tipo, int idUsuario) async {
    try {
      final bytes = base64Decode(base64Foto);
      final fileName =
          'asistencia_${idUsuario}_${tipo}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final url = Uri.parse(
          'https://xciuisfqkbqgajgctlae.supabase.co/storage/v1/object/asistencias_fotos/$fileName');

      final response = await http.post(
        url,
        headers: {
          'apikey': headers['apikey']!,
          'Authorization': headers['Authorization']!,
          'Content-Type': 'image/jpeg',
        },
        body: bytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return 'https://xciuisfqkbqgajgctlae.supabase.co/storage/v1/object/public/asistencias_fotos/$fileName';
      } else {
        print('❌ Error subiendo imagen: ${response.statusCode}');
        print(response.body);
        return null;
      }
    } catch (e) {
      print('❌ Error subirFotoAsistencia: $e');
      return null;
    }
  }
}
