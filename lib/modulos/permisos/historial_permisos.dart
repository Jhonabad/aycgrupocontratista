import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../servicesapi/api_permisos.dart';

class PageHistorialPermisos extends StatefulWidget {
  final int idUsuario;
  const PageHistorialPermisos({super.key, required this.idUsuario});

  @override
  State<PageHistorialPermisos> createState() => _PageHistorialPermisosState();
}

class _PageHistorialPermisosState extends State<PageHistorialPermisos> {
  final AuthServicesPermisos _permisoService = AuthServicesPermisos();
  final supabase = Supabase.instance.client;
  StreamSubscription? _streamSubscription;

  List<Map<String, dynamic>> _permisos = [];
  List<Map<String, dynamic>> _permisosFiltrados = [];

  String _estadoSeleccionado = 'Todos';
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPermisos();
    _escucharCambiosEnPermisos(); // 👈 activa escucha en tiempo real
  }

  Future<void> _cargarPermisos() async {
    setState(() => _cargando = true);
    final data = await _permisoService.listarPermisosUsuario(widget.idUsuario);
    setState(() {
      _permisos = data;
      _permisosFiltrados = data;
      _cargando = false;
    });
  }
  int? _ultimoNotificado;

  void _escucharCambiosEnPermisos() {
    _streamSubscription = supabase
        .from('permisos')
        .stream(primaryKey: ['id_permisos'])
        .eq('id_usuario', widget.idUsuario)
        .listen((data) {
      if (data.isNotEmpty) {
        data.sort((a, b) => DateTime.parse(b['fecha_solicitud'])
            .compareTo(DateTime.parse(a['fecha_solicitud'])));
        final ultimo = data.first;

        if (_ultimoNotificado != ultimo['id_permisos']) {
          final mensaje = ultimo['mensaje_admin'];
          final estado = ultimo['estado_permiso'];

          if (mensaje != null && mensaje.toString().isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("📢 Tu permiso fue $estado: $mensaje"),
                  backgroundColor:
                  estado == 'Aprobado' ? Colors.green : Colors.redAccent,
                  duration: const Duration(seconds: 5),
                ),
              );
            });
          }

          _ultimoNotificado = ultimo['id_permisos'];
          _cargarPermisos();
        }
      }
    });
  }

  void _filtrarPermisos() {
    if (_estadoSeleccionado == 'Todos') {
      _permisosFiltrados = _permisos;
    } else {
      _permisosFiltrados = _permisos
          .where((p) => p['estado_permiso'] == _estadoSeleccionado)
          .toList();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Permisos'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _estadoSeleccionado,
              items: const [
                DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                DropdownMenuItem(value: 'Aprobado', child: Text('Aprobado')),
                DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
                DropdownMenuItem(value: 'Rechazado', child: Text('Rechazado')),
              ],
              onChanged: (value) {
                _estadoSeleccionado = value!;
                _filtrarPermisos();
              },
              decoration: InputDecoration(
                labelText: 'Filtrar por estado',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: _permisosFiltrados.isEmpty
                  ? const Center(
                  child: Text('No tienes permisos registrados'))
                  : ListView.builder(
                itemCount: _permisosFiltrados.length,
                itemBuilder: (context, index) {
                  final p = _permisosFiltrados[index];
                  final estado = p['estado_permiso'];
                  Color colorEstado = Colors.orange;
                  if (estado == 'Aprobado') colorEstado = Colors.green;
                  if (estado == 'Rechazado') colorEstado = Colors.redAccent;

                  String inicio = '-';
                  String fin = '-';
                  try {
                    final fechas = p['fechas_solicitadas']?.toString() ?? '';
                    final partes = fechas.split(',');
                    if (partes.length >= 2) {
                      inicio = dateFormat.format(DateTime.parse(
                          partes[0].replaceAll('[', '').trim()));
                      fin = dateFormat.format(DateTime.parse(
                          partes[1].replaceAll(')', '').trim()));
                    }
                  } catch (_) {}

                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(Icons.receipt, color: colorEstado),
                      title: Text(p['tipo_permiso'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text("📅 $inicio → $fin"),
                          Text(
                              "🗓️ Solicitud: ${dateFormat.format(DateTime.parse(p['fecha_solicitud']))}"),
                          Text("📋 Estado: $estado",
                              style:
                              TextStyle(color: colorEstado)),
                          if (p["mensaje_admin"] != null &&
                              p["mensaje_admin"]
                                  .toString()
                                  .isNotEmpty)
                            Text("📝 Admin: ${p["mensaje_admin"]}",
                                style: const TextStyle(
                                    color: Colors.blueGrey)),
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
}
