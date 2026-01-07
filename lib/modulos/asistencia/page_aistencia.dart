import 'package:flutter/material.dart';
import '../../../servicesapi/api_actualizar_asistencia.dart';

class AsistenciaInfo extends StatefulWidget {
  final int idUsuario;

  const AsistenciaInfo({
    super.key,
    required this.idUsuario,
  });

  @override
  State<AsistenciaInfo> createState() => _AsistenciaInfoState();
}

class _AsistenciaInfoState extends State<AsistenciaInfo> {
  List<Map<String, dynamic>> _asistencias = [];
  bool _cargando = false;

  int? _idProyectoSeleccionado;
  List<Map<String, dynamic>> _proyectos = []; // proyectos del usuario
final api_proyect = AsistenciaAdminApi();
  @override
  void initState() {
    super.initState();
    _cargarProyectos();
  }

  // 🚀 Primero cargamos los proyectos del usuario
  Future<void> _cargarProyectos() async {
    try {
      setState(() => _cargando = true);

      // Llama a tu API de proyectos
      _proyectos = await AsistenciaAdminApi.obtenerProyectosPorUsuario(widget.idUsuario);

      setState(() => _cargando = false);
    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error cargando proyectos: $e")),
      );
    }
  }

  // 🚀 Carga asistencias solo DESPUÉS de seleccionar un proyecto
  Future<void> _cargarAsistencias() async {
    if (_idProyectoSeleccionado == null) return;

    try {
      setState(() => _cargando = true);

      final data = await AsistenciaAdminApi.obtenerHistorialAsistencias(
        idUsuario: widget.idUsuario,
        idProyecto: _idProyectoSeleccionado!,
      );

      setState(() {
        _asistencias = data;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error cargando asistencias: $e")),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Asistencias"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // =======================
            // RESUMEN HORAS TRABAJADAS
            // =======================
            if (_asistencias.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Horas trabajadas",
                      style: TextStyle(fontSize: 16, color: Colors.blue[900]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _horasTotales,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),

            // =======================
            // SELECTOR DE PROYECTO
            // =======================
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            labelText: "Seleccionar Proyecto",
            border: OutlineInputBorder(),
          ),
          value: _idProyectoSeleccionado,
          isExpanded: true, // 🔥 Esto es CLAVE para evitar overflow
          items: _proyectos.map((p) {
            return DropdownMenuItem<int>(
              value: p['id_proyecto'] as int,
              child: Row(
                children: [
                  const Icon(Icons.work_outline, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),

                  // 🚫 NO Expanded — que rompe el dropdown
                  // 🔥 En su lugar usamos ConstrainedBox
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: Text(
                      p['nombre_proyecto'],
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _idProyectoSeleccionado = value;
            });
            _cargarAsistencias();
          },
        ),

            const SizedBox(height: 16),

            // Encabezado tabla
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('Entrada', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('Salida', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // LISTA DE ASISTENCIAS
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _asistencias.isEmpty
                  ? const Center(child: Text("Seleccione un proyecto para ver su historial"))
                  : ListView.builder(
                itemCount: _asistencias.length,
                itemBuilder: (context, index) {
                  final item = _asistencias[index];

                  final fecha = item["fecha_asistencia"]?.toString() ?? "-";
                  final entrada = _formatoHora(item["fecha_entrada"]);
                  final salida = _formatoHora(item["fecha_salida"]);
                  final estado = item["estado_asistencia"]?.toString() ?? "-";

                  Color estadoColor;

                  switch (estado.toLowerCase()) {
                    case "presente":
                    case "a tiempo":
                      estadoColor = Colors.green;
                      break;
                    case "tarde":
                      estadoColor = Colors.orange;
                      break;
                    case "ausente":
                      estadoColor = Colors.red;
                      break;
                    default:
                      estadoColor = Colors.blueGrey;
                  }

                  return Card(
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(flex: 2, child: Text(fecha)),
                          Expanded(flex: 1, child: Text(entrada)),
                          Expanded(flex: 1, child: Text(salida)),
                          Expanded(
                            flex: 1,
                            child: Text(
                              estado,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: estadoColor,
                              ),
                              overflow: TextOverflow.clip,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  String get _horasTotales {
    Duration total = Duration.zero;

    for (var a in _asistencias) {
      if (a["fecha_entrada"] != null && a["fecha_salida"] != null) {
        try {
          final entrada = DateTime.parse("2024-01-01 ${a["fecha_entrada"]}");
          final salida = DateTime.parse("2024-01-01 ${a["fecha_salida"]}");
          total += salida.difference(entrada);
        } catch (_) {}
      }
    }

    final horas = total.inHours.toString().padLeft(2, '0');
    final minutos = (total.inMinutes % 60).toString().padLeft(2, '0');
    return "$horas:$minutos hrs";
  }
  String _formatoHora(String? hora) {
    if (hora == null || hora.isEmpty) return "-";
    try {
      final parsed = DateTime.parse("2000-01-01 $hora");
      return "${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return hora;
    }
  }
}
