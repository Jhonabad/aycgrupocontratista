import 'package:flutter/material.dart';
import '../../servicesapi/api_listar_proyectos.dart';

class ObraInfo extends StatefulWidget {
  final int idUsuario;

  const ObraInfo({super.key, required this.idUsuario});

  @override
  State<ObraInfo> createState() => _ObraInfoState();
}

class _ObraInfoState extends State<ObraInfo> {
  bool cargando = true;
  bool tieneObra = false;

  Map<String, dynamic>? obraAsignada;
  List<Map<String, dynamic>> obrasDisponibles = [];

  final ListProyectService _proyectoService = ListProyectService();

  @override
  void initState() {
    super.initState();
    _cargarProyectos();
  }

  Future<void> _cargarProyectos() async {
    setState(() => cargando = true);

    try {
      final proyectos = await _proyectoService.obtenerProyectos();

      // 🔹 Filtrar solo los proyectos donde el usuario participa
      final proyectosUsuario = proyectos.where((proyecto) {
        final encargados = List<Map<String, dynamic>>.from(proyecto['encargados'] ?? []);
        final personal = List<Map<String, dynamic>>.from(proyecto['personal'] ?? []);

        final esEncargado = encargados.any((e) => e['id_usuario'] == widget.idUsuario);
        final esPersonal = personal.any((p) => p['id_usuario'] == widget.idUsuario);

        return esEncargado || esPersonal;
      }).map((proyecto) {
        final encargados = List<Map<String, dynamic>>.from(proyecto['encargados'] ?? []);
        final esEncargado = encargados.any((e) => e['id_usuario'] == widget.idUsuario);

        return {
          ...proyecto,
          'rol_usuario': esEncargado ? 'Encargado' : 'Personal',
        };
      }).toList();

      setState(() {
        obrasDisponibles = proyectosUsuario;
        cargando = false;
      });
    } catch (e) {
      print("❌ Error al cargar proyectos: $e");
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Información del Proyecto"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: cargando
            ? const Center(child: CircularProgressIndicator())
            : tieneObra
            ? _buildDetalleObra()
            : _buildListaObras(),
      ),
    );
  }

  /// 🔹 Vista con la información detallada del proyecto seleccionado
  Widget _buildDetalleObra() {
    final obra = obraAsignada!;
    final rol = obra["rol_usuario"];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            obra["nombre_proyecto"] ?? "Proyecto sin nombre",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _infoTile("📍 Ubicación", obra["ubicacion"] ?? "—"),
          _infoTile("🏗️ Tipo de obra", obra["tipo_obra"] ?? "—"),
          _infoTile("📅 Fecha inicio", obra["fecha_inicio"] ?? "—"),
          _infoTile("📆 Fecha fin", obra["fecha_fin"] ?? "—"),
          _infoTile("⚙️ Estado", obra["estado_proyecto"] ?? "—"),
          _infoTile("🧩 Rol", rol),

          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  tieneObra = false;
                  obraAsignada = null;
                });
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text("Volver"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Lista de proyectos disponibles con ambos botones
  Widget _buildListaObras() {
    if (obrasDisponibles.isEmpty) {
      return const Center(child: Text("No tienes proyectos asignados."));
    }

    return ListView.builder(
      itemCount: obrasDisponibles.length,
      itemBuilder: (context, index) {
        final obra = obrasDisponibles[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.apartment, color: Colors.blueAccent),
                  title: Text(
                    obra["nombre_proyecto"] ?? "Sin nombre",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Rol: ${obra["rol_usuario"] ?? "—"}"),
                      if (obra["ubicacion"] != null)
                        Text("Ubicación: ${obra["ubicacion"]}"),
                      if (obra["estado_proyecto"] != null)
                        Text("Estado: ${obra["estado_proyecto"]}"),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text("Ver Detalle"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          obraAsignada = obra;
                          tieneObra = true;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text("Seleccionar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context, obra);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🔹 Info Tile
  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}
