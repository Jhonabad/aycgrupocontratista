import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aycgcsac/modulos/asistencia/page_aistencia.dart';
import 'package:aycgcsac/modulos/asistencia/page_obra.dart';
import 'package:aycgcsac/modulos/permisos/permisos.dart';
import 'package:aycgcsac/modulos/gestion/page_gestion.dart';
import 'package:aycgcsac/modulos/usuario/page_user.dart';
import '../../servicesapi/api_add_asistencias.dart';

class WireframeScreen extends StatefulWidget {
  final int rol;
  final Map<String, dynamic> usuario;

  const WireframeScreen({
    super.key,
    required this.rol,
    required this.usuario,
  });

  @override
  State<WireframeScreen> createState() => _WireframeScreenState();
}

class _WireframeScreenState extends State<WireframeScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isCameraOn = false;

  File? _capturedImage;

  String _fechaHora = '';
  Timer? _timer;

  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  final LatLng _defaultPosition = const LatLng(-12.0464, -77.0428);
  Map<String, dynamic>? _proyectoSeleccionado;
  String _tipoRegistro = 'entrada';
  List<CameraDescription>? _availableCameras;
  CameraDescription? _currentCamera;
  String? _direccionActual;


  late final List<String> _titles;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _actualizarFechaHora();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _actualizarFechaHora());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 2));
      await _checkPermissions();
      await _setupCameras();
      await _determinePositionAndUpdateMap();
    });

    if (widget.rol == 1) {
      _titles = ['Asistencia', 'Permisos', 'Usuario', 'Gestión'];
    } else {
      _titles = ['Asistencia', 'Permisos', 'Usuario'];
    }
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      debugPrint("✅ Permiso de cámara concedido");
      await _setupCameras();
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de cámara denegado permanentemente.')),
        );
      }
      await openAppSettings();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de cámara denegado')),
        );
      }
    }
  }

  Future<void> _setupCameras() async {
    try {
      debugPrint("🔍 Buscando cámaras disponibles...");
      _availableCameras = await availableCameras();

      if (_availableCameras == null || _availableCameras!.isEmpty) {
        debugPrint("❌ No se encontraron cámaras disponibles");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se detectaron cámaras en el dispositivo')),
          );
        }
        return;
      }

      _currentCamera = _availableCameras!.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _availableCameras!.first,
      );

      await _initializeCamera(cameraDescription: _currentCamera!);
    } catch (e, st) {
      debugPrint("⚠️ Error al configurar cámaras: $e\n$st");
    }
  }

  void _actualizarFechaHora() {
    final now = DateTime.now();
    final formato = DateFormat('dd/MM/yyyy HH:mm');
    if (mounted) setState(() => _fechaHora = formato.format(now));
  }

  Future<void> _initializeCamera({required CameraDescription cameraDescription}) async {
    debugPrint("🎥 Inicializando cámara: ${cameraDescription.lensDirection}");

    // Disponer controller anterior si existe
    await _cameraController?.dispose();
    _cameraController = null;
    _isCameraReady = false;

    try {
      final controller = CameraController(
        cameraDescription,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = controller;
      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraReady = true;
        _isCameraOn = true;
      });

      debugPrint("✅ Cámara inicializada correctamente (${cameraDescription.lensDirection})");
    } catch (e, st) {
      debugPrint("❌ Error al inicializar cámara: $e\n$st");
    }
  }

  Future<void> _toggleCamera() async {
    if (_availableCameras == null || _availableCameras!.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo hay una cámara disponible')),
      );
      return;
    }

    try {
      setState(() => _isCameraReady = false);

      await _cameraController?.dispose();
      _cameraController = null;
      _isCameraOn = false;

      await Future.delayed(const Duration(milliseconds: 800));

      final newCamera = _currentCamera?.lensDirection == CameraLensDirection.front
          ? _availableCameras!.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _availableCameras!.first,
      )
          : _availableCameras!.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _availableCameras!.first,
      );

      _currentCamera = newCamera;

      await _initializeCamera(cameraDescription: _currentCamera!);

      if (mounted) {
        setState(() {
          _isCameraReady = true;
          _isCameraOn = true;
        });
      }

      debugPrint("🔄 Cámara cambiada a: ${_currentCamera!.lensDirection}");
    } catch (e) {
      debugPrint("❌ Error al cambiar cámara: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar cámara: $e')),
      );
    }
  }

  void _onItemTapped(int index) async {
    if (_selectedIndex == index) return;

    if (_selectedIndex == 0 && _isCameraOn) {
      await _cameraController?.dispose();
      _isCameraOn = false;
    }

    setState(() => _selectedIndex = index);

    if (index == 0) {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (_currentCamera == null) {
          await _setupCameras();
        } else {
          await _initializeCamera(cameraDescription: _currentCamera!);
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (_cameraController == null || _currentCamera == null) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      await _cameraController?.dispose();
      _cameraController = null;
      _isCameraReady = false;
      _isCameraOn = false;
    } else if (state == AppLifecycleState.resumed) {
      if (_cameraController == null && _currentCamera != null) {
        debugPrint("🔁 Reanudando cámara...");
        await _initializeCamera(cameraDescription: _currentCamera!);
      } else {
        debugPrint("📸 Cámara sigue activa, no se reinicia");
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _cameraController?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_titles[_selectedIndex],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildDashboard(),
            PermisosScreen(usuario: widget.usuario),
            PageUserScreen(usuario: widget.usuario),
            if (widget.rol == 1) const GestionScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Asistencia'),
          const BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Permisos'),
          const BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Usuario'),
          if (widget.rol == 1)
            const BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'Gestión'),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    const double cameraBoxHeight = 500.0;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Stack(
              children: [
                Container(
                  height: cameraBoxHeight,
                  width: 380,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Builder(
                      builder: (_) {
                        if (_capturedImage != null) {
                          return Image.file(_capturedImage!, fit: BoxFit.cover);
                        }

                        if (_cameraController == null ||
                            !_isCameraReady ||
                            !_cameraController!.value.isInitialized) {
                          return const Center(
                            child: Text('Cargando cámara...',
                                style: TextStyle(color: Colors.white, fontSize: 16)),
                          );
                        }

                        final size = MediaQuery.of(context).size;
                        final scale =
                            1 / (_cameraController!.value.aspectRatio * size.aspectRatio);

                        return Transform.scale(
                          scale: scale < 1 ? 1 / scale : scale,
                          alignment: Alignment.center,
                          child: CameraPreview(_cameraController!),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(top: 12, left: 12, child: _mapMini()),
                Positioned(top: 14, right: 14, child: _fechaHoraWidget()),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child:
                  _capturedImage == null ? _cameraButtons() : _previewButtons(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 35),
          _buildMainButtons(),
        ],
      ),
    );
  }

  Widget _mapMini() => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(
      height: 110,
      width: 230,
      child: GoogleMap(
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        },
        initialCameraPosition: CameraPosition(
          target: _currentPosition ?? _defaultPosition,
          zoom: 15,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        onMapCreated: (controller) => _mapController = controller,
        markers: _currentPosition == null
            ? {}
            : {
          Marker(
            markerId: const MarkerId('current'),
            position: _currentPosition!,
          )
        },
      ),
    ),
  );

  Widget _cameraButtons() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      FloatingActionButton(
        heroTag: "fotoBtn",
        backgroundColor: Colors.white,
        onPressed: _takePhoto,
        child: const Icon(Icons.camera_alt, color: Colors.black, size: 28),
      ),
      const SizedBox(width: 16),
      FloatingActionButton(
        heroTag: "rotateBtn",
        backgroundColor: Colors.white,
        onPressed: _toggleCamera,
        child: const Icon(Icons.cameraswitch, color: Colors.black, size: 28),
      ),
    ],
  );

  Widget _previewButtons() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ElevatedButton.icon(
        onPressed: () async {
          setState(() {
            _capturedImage = null;
            _isCameraOn = true;
          });
          if (_currentCamera != null) {
            await _initializeCamera(cameraDescription: _currentCamera!);
          }
        },
        icon: const Icon(Icons.refresh),
        label: const Text("Repetir"),
      ),
      const SizedBox(width: 12),
      ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Foto confirmada")),
          );
        },
        icon: const Icon(Icons.check_circle),
        label: const Text("Confirmar"),
      ),
    ],
  );

  Future<void> _takePhoto() async {
    if (!_isCameraReady || _cameraController == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cámara no disponible')));
      return;
    }

    try {
      final picture = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = File(picture.path);
        _isCameraOn = false;
      });
      debugPrint("✅ Foto tomada y guardada en: ${picture.path}");
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al tomar foto: $e')));
    }
  }

  Future<void> _determinePositionAndUpdateMap() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor activa la ubicación del dispositivo')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de ubicación denegado permanentemente')),
      );
      return;
    }

    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      List<Placemark> placemarks =
      await placemarkFromCoordinates(pos.latitude, pos.longitude);

      String direccion = '';
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        direccion =
        "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";
      }

      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        _direccionActual = direccion;
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition!, 17),
        );
      }

      debugPrint("📍 Posición actual: $_currentPosition");
      debugPrint("📍 Dirección: $_direccionActual");
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al obtener ubicación: $e')));
    }
  }

  Widget _fechaHoraWidget() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(DateFormat('dd/MM/yyyy').format(DateTime.now()),
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        Text(DateFormat('HH:mm').format(DateTime.now()),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _buildMainButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _mainButton("ASISTENCIA", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AsistenciaInfo(idUsuario: widget.usuario['id_usuario']),
                ),
              );
            }),
            const SizedBox(width: 12),
            _mainButton("PROYECTOS", () async {
              final proyecto = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ObraInfo(idUsuario: widget.usuario['id_usuario']),
                ),
              );
              if (proyecto != null) {
                setState(() => _proyectoSeleccionado = proyecto);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          "Proyecto seleccionado: ${proyecto['nombre_proyecto']}")),
                );
              }
            }),
          ],
        ),
        const SizedBox(height: 12),
        _mainButton("REGISTRO ASISTENCIA", _registrarAsistencia),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _mainButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white12,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onPressed,
      child: Text(text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _registrarAsistencia() async {
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Por favor, toma una foto.')));
      return;
    }
    if (_proyectoSeleccionado == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecciona un proyecto.')));
      return;
    }
    try {
      // 🔹 Detectar automáticamente si corresponde entrada o salida
      final yaTieneEntrada = await AsistenciaAdminApiUser.validarEntradaHoy(
        idUsuario: widget.usuario['id_usuario'],
        idProyecto: _proyectoSeleccionado!['id_proyecto'],
      );
      final tipo = yaTieneEntrada ? "salida" : "entrada";
      setState(() => _tipoRegistro = tipo);
      // 🔹 Mostrar confirmación visual
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text("Confirmar registro de ${tipo.toUpperCase()}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_capturedImage!, height: 160, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                Text(
                  "Proyecto: ${_proyectoSeleccionado!['nombre_proyecto']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _direccionActual != null && _direccionActual!.isNotEmpty
                      ? "Ubicación: $_direccionActual"
                      : "Ubicación no disponible",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),
                Text(
                  "¿Registrar ${tipo.toUpperCase()}?",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check),
                label: const Text("Confirmar"),
              ),
            ],
          );
        },
      );

      if (confirmar != true) return;

      // 🔹 Subir la foto al bucket
      final supabase = Supabase.instance.client;
      final fileName =
          'asistencia_${widget.usuario['id_usuario']}_${tipo}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final uploadResponse = await supabase.storage
          .from('asistencias_fotos')
          .upload(fileName, _capturedImage!);
      if (uploadResponse.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al subir la imagen.")),
        );
        return;
      }

      final publicUrl =
      supabase.storage.from('asistencias_fotos').getPublicUrl(fileName);

      // 🔹 Registrar asistencia (entrada o salida) con URL pública
      final result = await AsistenciaAdminApiUser.registrarAsistenciaUsuario(
        idUsuario: widget.usuario['id_usuario'],
        idProyecto: _proyectoSeleccionado!['id_proyecto'],
        latitud: _currentPosition?.latitude ?? 0,
        longitud: _currentPosition?.longitude ?? 0,
        fotoUrl: publicUrl,
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result['mensaje'])));
      setState(() {
        _capturedImage = null;
        _isCameraOn = true;
      });
      if (_currentCamera != null) {
        await _initializeCamera(cameraDescription: _currentCamera!);
      }
    } catch (e) {
      debugPrint("❌ Error al registrar asistencia: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
