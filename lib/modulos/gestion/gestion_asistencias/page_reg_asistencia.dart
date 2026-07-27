import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../servicesapi/api_add_asistencias.dart';
import '../../../servicesapi/api_info_user.dart';

class PageRegistrarAsistenciaAdmin extends StatefulWidget {
  const PageRegistrarAsistenciaAdmin({super.key});

  @override
  State<PageRegistrarAsistenciaAdmin> createState() =>
      _PageRegistrarAsistenciaAdminState();
}

class _PageRegistrarAsistenciaAdminState
    extends State<PageRegistrarAsistenciaAdmin> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();

  List<Map<String, dynamic>> _personal = [];
  Map<String, dynamic>? _personalSeleccionado;

  List<Map<String, dynamic>> _obras = [];
  Map<String, dynamic>? _obraSeleccionada;

  LatLng? _ubicacionSeleccionada;
  GoogleMapController? mapController;
  bool _obteniendoUbicacion = true;
  bool _isSubmitting = false;
  bool _esEntrada = true; // 👈 volvemos a usar esta variable

  final LatLng _posicionPorDefecto = const LatLng(-12.0464, -77.0428);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fechaController.text =
    "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    _horaController.text =
    "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    _cargarUsuarios();
    _obtenerPosicionActual();
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _horaController.dispose();
    mapController = null;
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    try {
      final usuariosApi = AuthServicesList();
      final data = await usuariosApi.obtenerTodosUsuarios();
      _personal = data.map<Map<String, dynamic>>((u) {
        return {
          "id_usuario": u["id_usuario"],
          "nombre_usuario": u["nombre_usuario"],
        };
      }).toList();
      setState(() {});
    } catch (e) {
      debugPrint("Error cargando usuarios: $e");
    }
  }

  Future<void> _cargarObras(int idUsuario) async {
    try {
      final proyectos =
          await AsistenciaAdminApiUser.obtenerProyectosPorUsuarioAdmin(idUsuario);
      _obras = proyectos.map<Map<String, dynamic>>((p) {
        return {
          "id_proyecto": p["id_proyecto"],
          "nombre_proyecto": p["nombre_proyecto"],
        };
      }).toList();
      setState(() {});
    } catch (e) {
      debugPrint("Error cargando proyectos: $e");
    }
  }

  Future<void> _obtenerPosicionActual() async {
    setState(() => _obteniendoUbicacion = true);
    try {
      final servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activa la ubicación del dispositivo')),
          );
        }
        _ubicacionSeleccionada = _posicionPorDefecto;
        _obteniendoUbicacion = false;
        setState(() {});
        return;
      }
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        _ubicacionSeleccionada = _posicionPorDefecto;
        _obteniendoUbicacion = false;
        setState(() {});
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      _ubicacionSeleccionada = LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      _ubicacionSeleccionada = _posicionPorDefecto;
    }
    _obteniendoUbicacion = false;
    setState(() {});
  }

  Future<void> _centrarUbicacion() async {
    if (_ubicacionSeleccionada == null) {
      await _obtenerPosicionActual();
    }
    if (_ubicacionSeleccionada != null && mapController != null) {
      mapController!
          .animateCamera(CameraUpdate.newLatLngZoom(_ubicacionSeleccionada!, 16));
    }
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_personalSeleccionado == null ||
        _obraSeleccionada == null ||
        _ubicacionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Seleccione el empleado, proyecto y ubicación")));
      return;
    }

    final idUsuario = _personalSeleccionado!["id_usuario"];
    final idProyecto = _obraSeleccionada!["id_proyecto"];

    setState(() => _isSubmitting = true);

    try {
      final resultado = await AsistenciaAdminApiUser.registrarAsistenciaUsuario(
        idUsuario: idUsuario,
        idProyecto: idProyecto,
        latitud: _ubicacionSeleccionada!.latitude,
        longitud: _ubicacionSeleccionada!.longitude,
        fotoUrl: null,
      );

      final mensaje = resultado["mensaje"] ?? "";
      final success = resultado["success"] == true;

      if (mensaje.contains("asistencia abierta") ||
          mensaje.contains("sin salida")) {
        setState(() {
          _esEntrada = false; // Cambia el botón dinámicamente
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "El usuario tiene una asistencia abierta. Presiona para registrar salida."),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje.isNotEmpty
              ? mensaje
              : (_esEntrada
              ? "Entrada registrada correctamente"
              : "Salida registrada correctamente")),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );

      if (success) {
        // Si fue entrada, luego deberá registrar salida
        if (_esEntrada) {
          setState(() => _esEntrada = false);
        } else {
          if (mounted) Navigator.pop(context, true);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al registrar asistencia: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar asistencia")),
      body: _obteniendoUbicacion || _ubicacionSeleccionada == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<Map<String, dynamic>>(
                decoration: _inputDecor("Empleado", Icons.person),
                value: _personalSeleccionado,
                items: _personal
                    .map((e) => DropdownMenuItem(
                    value: e,
                    child:
                    Text(e["nombre_usuario"] ?? "Sin nombre")))
                    .toList(),
                onChanged: (value) async {
                  _personalSeleccionado = value;
                  _obraSeleccionada = null;
                  await _cargarObras(value!["id_usuario"]);
                  setState(() {});
                },
                validator: (v) =>
                v == null ? "Seleccione empleado" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Map<String, dynamic>>(
                decoration: _inputDecor("Proyecto", Icons.work),
                value: _obraSeleccionada,
                isExpanded: true,
                items: _obras.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(
                      e["nombre_proyecto"] ?? "Sin nombre",
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) async {
                  _obraSeleccionada = value;
                  setState(() {});
                },
                validator: (v) =>
                v == null ? "Seleccione proyecto" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fechaController,
                decoration: _inputDecor("Fecha", Icons.calendar_today),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _horaController,
                decoration:
                _inputDecor("Hora (HH:MM)", Icons.access_time),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 240,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _ubicacionSeleccionada!,
                      zoom: 16,
                    ),
                    onMapCreated: (c) => mapController = c,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    markers: {
                      Marker(
                        markerId: const MarkerId('ubi'),
                        position: _ubicacionSeleccionada!,
                        draggable: true,
                        onDragEnd: (pos) =>
                            setState(() => _ubicacionSeleccionada = pos),
                      )
                    },
                    onTap: (pos) =>
                        setState(() => _ubicacionSeleccionada = pos),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _registrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _esEntrada
                        ? Colors.green
                        : Colors.orangeAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                      color: Colors.white)
                      : Text(
                    _esEntrada
                        ? "REGISTRAR ENTRADA"
                        : "REGISTRAR SALIDA",
                    style: const TextStyle(
                        fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
