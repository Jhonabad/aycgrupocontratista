import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geocoding/geocoding.dart';
import '../../../servicesapi/api_actualizar_asistencia.dart';
import '../../../servicesapi/api_consul_asisten.dart';
import '../../../servicesapi/api_listar_proyectos.dart';

class PageConsultarAsistenciasAdmin extends StatefulWidget {
  const PageConsultarAsistenciasAdmin({super.key});

  @override
  State<PageConsultarAsistenciasAdmin> createState() =>
      _PageConsultarAsistenciasAdminState();
}

class _PageConsultarAsistenciasAdminState
    extends State<PageConsultarAsistenciasAdmin> {
  final TextEditingController _fechaController = TextEditingController();

  int? _personalSeleccionadoId;
  int? _proyectoSeleccionadoId;

  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> _proyectos = [];
  List<Map<String, dynamic>> _asistencias = [];

  final _asistenciasApi = AuthServicesAsistencia();
  final _proyecLisr = ListProyectService();

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      setState(() => _cargando = true);
      _proyectos = List<Map<String, dynamic>>.from(
        await _proyecLisr.obtenerProyectos(),
      );
      _usuarios = [];
      _asistencias = await _asistenciasApi.obtenerAsistencias();

      setState(() => _cargando = false);
    } catch (e) {
      print("❌ Error inicial: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar datos: $e")),
        );
      }
      setState(() => _cargando = false);
    }
  }

  Future<void> _cargarUsuariosPorProyecto(int idProyecto) async {
    try {
      final usuarios = await AsistenciaAdminApi.obtenerUsuariosPorProyecto(idProyecto);

      setState(() {
        _usuarios = List<Map<String, dynamic>>.from(usuarios);
        _personalSeleccionadoId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Usuarios cargados correctamente (${usuarios.length})"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("❌ Error cargando usuarios del proyecto: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al cargar usuarios del proyecto"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 20, left: 16, right: 16),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }


  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
    );

    if (picked != null) {
      _fechaController.text =
      "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      await _filtrarAsistencias();
    }
  }

  Future<void> _filtrarAsistencias() async {
    try {
      setState(() => _cargando = true);

      final fecha = _fechaController.text.isNotEmpty
          ? _fechaController.text.split('/').reversed.join('-')
          : null;

      final asistencias = await _asistenciasApi.obtenerAsistencias(
        idUsuario: _personalSeleccionadoId,
        fecha: fecha,
        idProyecto: _proyectoSeleccionadoId,
      );

      setState(() {
        _asistencias = asistencias;
        _cargando = false;
      });
    } catch (e) {
      print("❌ Error al filtrar: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al filtrar asistencias: $e")),
        );
      }
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Consultar Asistencias',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Proyecto
              DropdownButtonFormField<int>(
                value: _proyectoSeleccionadoId,
                isExpanded: true,
                items: _proyectos.map((proy) {
                  return DropdownMenuItem<int>(
                    value: proy['id_proyecto'],
                    child: Text(
                      proy['nombre_proyecto'] ?? 'Sin nombre',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) async {
                  _proyectoSeleccionadoId = value;
                  if (value != null) {
                    await _cargarUsuariosPorProyecto(value);
                  }
                  await _filtrarAsistencias();
                },
                decoration: InputDecoration(
                  labelText: 'Proyecto',
                  prefixIcon: const Icon(Icons.work),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _personalSeleccionadoId,
                isExpanded: true,
                items: _usuarios.map((usuario) {
                  return DropdownMenuItem<int>(
                    value: usuario['id_usuario'],
                    child: Text(usuario['nombre_usuario'] ?? 'Sin nombre'),
                  );
                }).toList(),
                onChanged: (value) async {
                  _personalSeleccionadoId = value;
                  setState(() {});
                  await _filtrarAsistencias();
                },
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 🔹 Fecha
              TextFormField(
                controller: _fechaController,
                readOnly: true,
                onTap: () => _seleccionarFecha(context),
                decoration: InputDecoration(
                  labelText: 'Fecha',
                  prefixIcon: const Icon(Icons.calendar_today),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Lista de asistencias
              Expanded(
                child: _asistencias.isEmpty
                    ? const Center(
                  child: Text(
                    'No se encontraron asistencias',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  itemCount: _asistencias.length,
                  itemBuilder: (context, index) {
                    final asistencia = _asistencias[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(
                          Icons.assignment_turned_in,
                          color: Colors.blueAccent,
                        ),
                        title: Text(
                          asistencia['nombre_usuario'] ?? 'Desconocido',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("🏗 Proyecto: ${asistencia['nombre_proyecto'] ?? '-'}"),
                            Text("📅 Fecha: ${asistencia['fecha_asistencia'] ?? '-'}"),
                            Text("🕗 Entrada: ${asistencia['fecha_entrada'] ?? '-'}"),
                            Text("🕔 Salida: ${asistencia['fecha_salida'] ?? '-'}"),
                            Text("⏳ Horas trabajadas: ${_calcularHoras(asistencia)}"),

                            // 🔹 Convertir coordenadas de entrada
                            FutureBuilder<String>(
                              future: convertirCoordenadas(
                                  asistencia['ubicacion_entrada']),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Text("📍 Entrada: Cargando...");
                                }
                                return Text(
                                    "📍 Entrada: ${snapshot.data ?? 'No disponible'}");
                              },
                            ),

                            // 🔹 Convertir coordenadas de salida
                            FutureBuilder<String>(
                              future: convertirCoordenadas(
                                  asistencia['ubicacion_salida']),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Text("📍 Salida: Cargando...");
                                }
                                return Text(
                                    "📍 Salida: ${snapshot.data ?? 'No disponible'}");
                              },
                            ),

                            Text("📝 Estado: ${asistencia['estado_asistencia'] ?? '-'}"),
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

  String _buscarNombreUsuario(int? idUsuario) {
    if (idUsuario == null) return 'Sin usuario';
    final user = _usuarios.firstWhere(
          (u) => u['id_usuario'] == idUsuario,
      orElse: () => {'nombre_usuario': 'Desconocido'},
    );
    return user['nombre_usuario'] ?? 'Desconocido';
  }

  Future<String> convertirCoordenadas(String? ubicacion) async {
    if (ubicacion == null || ubicacion.isEmpty) return "-";
    final partes = ubicacion.split(",");
    if (partes.length != 2) return "Coordenadas inválidas";

    final lat = double.tryParse(partes[0]) ?? 0.0;
    final lng = double.tryParse(partes[1]) ?? 0.0;

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return "-";
      final place = placemarks.first;
      final direccion = [
        place.street,
        place.locality,
        place.administrativeArea,
        place.country
      ].where((e) => (e ?? "").isNotEmpty).join(", ");
      return direccion.isEmpty ? "-" : direccion;
    } catch (e) {
      print("❌ Error convirtiendo coordenadas: $e");
      return "-";
    }
  }

  String _calcularHoras(Map<String, dynamic> asistencia) {
    final entrada = asistencia['fecha_entrada'];
    final salida = asistencia['fecha_salida'];
    if (entrada == null || salida == null) return "-";
    try {
      final e = DateTime.parse("2025-01-01 $entrada");
      final s = DateTime.parse("2025-01-01 $salida");
      final diff = s.difference(e);
      final horas = diff.inHours;
      final minutos = diff.inMinutes % 60;
      return "$horas h $minutos min";
    } catch (_) {
      return "-";
    }
  }
}
