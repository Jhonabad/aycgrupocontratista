import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geocoding/geocoding.dart';

import '../../../servicesapi/api_actualizar_asistencia.dart';

final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();

class PageEditarAsistencias extends StatefulWidget {
  const PageEditarAsistencias({super.key});

  @override
  State<PageEditarAsistencias> createState() => _PageEditarAsistenciasState();
}

class _PageEditarAsistenciasState extends State<PageEditarAsistencias> {
  final TextEditingController _fechaController = TextEditingController();

  int? _personalSeleccionadoId;
  int? _proyectoSeleccionadoId;

  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> _proyectos = [];
  List<Map<String, dynamic>> _asistencias = [];

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      setState(() => _cargando = true);
      _usuarios = await AsistenciaAdminApi.obtenerUsuarios();
      _proyectos = [];
      _asistencias = [];
      setState(() => _cargando = false);
    } catch (e) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text("Error al cargar datos: $e")),
        );
      }
      setState(() => _cargando = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: const Locale("es", "ES"),
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      _fechaController.text =
      "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      await _filtrarAsistencias();
    }
  }

  Future<void> _filtrarAsistencias() async {
    if (_personalSeleccionadoId == null ||
        _proyectoSeleccionadoId == null ||
        _fechaController.text.isEmpty) {
      setState(() => _asistencias = []);
      return;
    }

    try {
      setState(() => _cargando = true);

      final fecha = _fechaController.text.split("/").reversed.join("-");

      _asistencias = await AsistenciaAdminApi.obtenerAsistenciasFiltradas(
        idUsuario: _personalSeleccionadoId!,
        idProyecto: _proyectoSeleccionadoId!,
        fecha: fecha,
      );

      setState(() => _cargando = false);
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text("Error filtrando asistencias: $e")),
      );
      setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _fechaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES')],
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Editar Asistencias",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: Colors.white,
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: _personalSeleccionadoId,
                isExpanded: true,
                items: _usuarios.map((usuario) {
                  return DropdownMenuItem<int>(
                    value: usuario['id_usuario'],
                    child: Text(usuario['nombre_usuario']),
                  );
                }).toList(),
                onChanged: (v) async {
                  _personalSeleccionadoId = v;
                  if (v != null) {
                    _proyectos = await AsistenciaAdminApi
                        .obtenerProyectosPorUsuario(v);
                  } else {
                    _proyectos = [];
                  }
                  setState(() {
                    _proyectoSeleccionadoId = null;
                  });
                  await _filtrarAsistencias();
                },
                decoration: _formDecor("Usuario", Icons.person),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _proyectoSeleccionadoId,
                isExpanded: true,
                items: _proyectos.map((p) {
                  return DropdownMenuItem<int>(
                    value: p['id_proyecto'],
                    child: Text(
                      p['nombre_proyecto'],
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (v) async {
                  _proyectoSeleccionadoId = v;
                  await _filtrarAsistencias();
                },
                decoration: _formDecor("Proyecto", Icons.work),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fechaController,
                readOnly: true,
                onTap: _seleccionarFecha,
                decoration: _formDecor("Fecha", Icons.calendar_today),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _asistencias.isEmpty
                    ? const Center(child: Text("No hay asistencias"))
                    : ListView.builder(
                  itemCount: _asistencias.length,
                  itemBuilder: (_, i) {
                    final a = _asistencias[i];
                    return Card(
                      margin:
                      const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.assignment_turned_in,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _buscarNombreUsuario(
                                        a['id_usuario']),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ),
                                Text(
                                    a['fecha_asistencia'] ?? "-"),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                                "🏗 Proyecto: ${a['nombre_proyecto'] ?? '-'}"),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                      "🕗 Entrada: ${a['fecha_entrada']}"),
                                ),
                                Expanded(
                                  child: Text(
                                      "🕔 Salida: ${a['fecha_salida']}"),
                                ),
                                Expanded(
                                  child: Text(
                                      "⏳ ${_calcularHoras(a)}"),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            FutureBuilder<String>(
                              future: convertirCoordenadas(
                                  a['ubicacion']),
                              builder: (_, snap) {
                                if (snap.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Text(
                                      "📍 Ubicación: Cargando...");
                                }
                                return Text(
                                    "📍 Ubicación: ${snap.data}");
                              },
                            ),
                            const SizedBox(height: 6),
                            Text(
                                "📝 Estado: ${a['estado_asistencia'] ?? '-'}"),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.edit),
                                label: const Text(
                                    "Editar asistencia"),
                                onPressed: () async {
                                  final actualizado =
                                  await _openEditarSheet(a);
                                  if (actualizado == true) {
                                    _scaffoldMessengerKey
                                        .currentState
                                        ?.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "✅ Asistencia actualizada correctamente"),
                                        backgroundColor:
                                        Colors.green,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                icon: const Icon(Icons.delete),
                                label: const Text(
                                    "Eliminar asistencia"),
                                onPressed: () =>
                                    _confirmEliminar(a),
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
      ),
    );
  }

  InputDecoration _formDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  String _buscarNombreUsuario(int? id) {
    final u = _usuarios.firstWhere(
          (e) => e['id_usuario'] == id,
      orElse: () => {'nombre_usuario': '-'},
    );
    return u['nombre_usuario'];
  }

  Future<String> convertirCoordenadas(String? ubicacion) async {
    if (ubicacion == null || ubicacion.isEmpty) return "-";
    final partes = ubicacion.split(",");
    if (partes.length != 2) return "-";
    final lat = double.tryParse(partes[0]) ?? 0.0;
    final lng = double.tryParse(partes[1]) ?? 0.0;
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return "-";
      final p = placemarks.first;
      return [
        p.street,
        p.locality,
        p.administrativeArea,
        p.country
      ].where((e) => e != null && e!.isNotEmpty).join(", ");
    } catch (_) {
      return "-";
    }
  }

  String _calcularHoras(Map a) {
    try {
      final e = a['fecha_entrada']?.toString();
      final s = a['fecha_salida']?.toString();
      if (e == null || s == null) return "-";
      final eParts = e.split(":");
      final sParts = s.split(":");
      final entrada =
      DateTime(2025, 1, 1, int.parse(eParts[0]), int.parse(eParts[1]));
      final salida =
      DateTime(2025, 1, 1, int.parse(sParts[0]), int.parse(sParts[1]));
      final diff = salida.difference(entrada);
      if (diff.isNegative) return "-";
      return "${diff.inHours} h ${diff.inMinutes % 60} min";
    } catch (_) {
      return "-";
    }
  }

  Future<bool?> _openEditarSheet(Map asistencia) async {
    final int id = asistencia['id_asistencia'];
    final entradaC = TextEditingController(text: asistencia['fecha_entrada']);
    final salidaC = TextEditingController(text: asistencia['fecha_salida']);

    final result = await showModalBottomSheet<bool>(
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Editar asistencia",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: entradaC,
                  readOnly: true,
                  onTap: () async {
                    final pick = await showTimePicker(
                      context: ctx,
                      initialTime: _parseTime(entradaC.text) ??
                          const TimeOfDay(hour: 8, minute: 0),
                    );
                    if (pick != null) {
                      entradaC.text =
                      "${pick.hour.toString().padLeft(2, '0')}:${pick.minute.toString().padLeft(2, '0')}";
                    }
                  },
                  decoration: const InputDecoration(labelText: "Hora Entrada"),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: salidaC,
                  readOnly: true,
                  onTap: () async {
                    final pick = await showTimePicker(
                      context: ctx,
                      initialTime: _parseTime(salidaC.text) ??
                          const TimeOfDay(hour: 17, minute: 0),
                    );
                    if (pick != null) {
                      salidaC.text =
                      "${pick.hour.toString().padLeft(2, '0')}:${pick.minute.toString().padLeft(2, '0')}";
                    }
                  },
                  decoration: const InputDecoration(labelText: "Hora Salida"),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: const Text("Guardar cambios"),
                    onPressed: () async {
                      if (entradaC.text.isEmpty || salidaC.text.isEmpty) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          const SnackBar(
                              content:
                              Text("❌ Complete ambos campos de hora")),
                        );
                        return;
                      }

                      final confirmar = await showDialog<bool>(
                        context: ctx,
                        builder: (dCtx) => AlertDialog(
                          title: const Text("Confirmar actualización"),
                          content: const Text(
                              "¿Deseas guardar los cambios en esta asistencia?"),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(dCtx, false),
                                child: const Text("Cancelar")),
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(dCtx, true),
                                child: const Text("Guardar")),
                          ],
                        ),
                      );

                      if (confirmar != true) return;

                      final ok = await AsistenciaAdminApi.editarAsistencia(
                        idAsistencia: id,
                        entrada: entradaC.text,
                        salida: salidaC.text,
                      );

                      if (ok) {
                        Navigator.pop(ctx);
                        setState(() {
                          final idx = _asistencias.indexWhere(
                                  (a) => a['id_asistencia'] == id);
                          if (idx != -1) {
                            _asistencias[idx]['fecha_entrada'] = entradaC.text;
                            _asistencias[idx]['fecha_salida'] = salidaC.text;
                          }
                        });
                        Future.delayed(const Duration(milliseconds: 300), () {
                          _scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                              content: Text("✅ Asistencia actualizada correctamente"),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        });
                      } else {
                        Navigator.pop(ctx);
                        Future.delayed(const Duration(milliseconds: 300), () {
                          _scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                              content: Text("❌ Error al actualizar asistencia"),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        });
                      }

                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return result;
  }

  TimeOfDay? _parseTime(String? t) {
    if (t == null || !t.contains(":")) return null;
    final p = t.split(":");
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  Future<void> _confirmEliminar(Map asistencia) async {
    final id = asistencia['id_asistencia'];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar asistencia"),
        content: const Text("¿Deseas eliminar esta asistencia?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancelar")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Eliminar")),
        ],
      ),
    );

    if (ok == true) {
      final borrado = await AsistenciaAdminApi.eliminarAsistencia(id);
      if (borrado && mounted) {
        setState(() {
          _asistencias.removeWhere((a) => a['id_asistencia'] == id);
        });
        Future.microtask(() {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text("✅ Asistencia eliminada correctamente"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        });
      } else {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text("❌ Error al eliminar asistencia"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
