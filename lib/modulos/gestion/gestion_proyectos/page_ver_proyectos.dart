import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../../servicesapi/api_listar_proyectos.dart';

class PageVerProyectos extends StatefulWidget {
  const PageVerProyectos({super.key});

  @override
  State<PageVerProyectos> createState() => _PageVerProyectosState();
}

class _PageVerProyectosState extends State<PageVerProyectos> {
  final ListProyectService _proyectService = ListProyectService();

  List<dynamic> _proyectos = [];
  List<dynamic> _proyectosFiltrados = [];
  bool _cargando = true;
  int? _proyectoSeleccionadoId;

  @override
  void initState() {
    super.initState();
    _cargarProyectos();
  }

  Future<void> _cargarProyectos() async {
    try {
      final data = await _proyectService.obtenerProyectos();
      setState(() {
        _proyectos = data;
        _proyectosFiltrados = data; // 👈 Muestra todos al inicio
        _cargando = false;
      });
      print('✅ Proyectos cargados correctamente (${_proyectos.length})');
    } catch (e) {
      print('❌ Error al cargar proyectos: $e');
      setState(() => _cargando = false);
    }
  }

  void _filtrarProyectoSeleccionado(int? idSeleccionado) {
    setState(() {
      _proyectoSeleccionadoId = idSeleccionado;
      if (idSeleccionado == null) {
        // Mostrar todos los proyectos
        _proyectosFiltrados = _proyectos;
      } else {
        // Mostrar solo el seleccionado
        _proyectosFiltrados = _proyectos
            .where((proy) => proy['id_proyecto'] == idSeleccionado)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES')],
      locale: const Locale('es', 'ES'),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Lista de Proyectos',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: Colors.grey[100],
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // 🔽 Desplegable de selección de proyectos
              DropdownButtonFormField<int>(
                value: _proyectoSeleccionadoId,
                isExpanded: true,
                hint: const Text('Seleccionar proyecto'),
                items: _proyectos.map((proy) {
                  return DropdownMenuItem<int>(
                    value: proy['id_proyecto'],
                    child: Text(proy['nombre_proyecto'] ?? 'Sin nombre'),
                  );
                }).toList(),
                onChanged: _filtrarProyectoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Proyecto',
                  prefixIcon: const Icon(Icons.work_outline),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _proyectoSeleccionadoId != null
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () =>
                        _filtrarProyectoSeleccionado(null),
                  )
                      : null,
                ),
              ),

              const SizedBox(height: 10),
              // 📋 Lista de proyectos
              Expanded(
                child: _proyectosFiltrados.isEmpty
                    ? const Center(
                  child: Text(
                    'No hay proyectos registrados',
                    style:
                    TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: _cargarProyectos,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _proyectosFiltrados.length,
                    itemBuilder: (context, index) {
                      final proy = _proyectosFiltrados[index];
                      final estado =
                          proy['estado_proyecto'] ?? '—';

                      final encargadosList =
                      (proy['encargados'] ?? []) as List;
                      final personalList =
                      (proy['personal'] ?? []) as List;

                      final encargadosTexto = encargadosList.isEmpty
                          ? 'Sin encargados'
                          : encargadosList
                          .map((e) =>
                      e['nombre_usuario'] ?? 'Sin nombre')
                          .join(', ');

                      final personalTexto = personalList.isEmpty
                          ? 'Sin personal'
                          : personalList
                          .map((e) =>
                      e['nombre_usuario'] ?? 'Sin nombre')
                          .join(', ');

                      return Card(
                        elevation: 3,
                        margin:
                        const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding:
                          const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              (proy['nombre_proyecto'] ?? '?')[0]
                                  .toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white),
                            ),
                          ),
                          title: Text(
                            proy['nombre_proyecto'] ?? 'Sin nombre',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                  "📍 ${proy['ubicacion'] ?? '—'}"),
                              Text(
                                  "👷 Encargados: $encargadosTexto"),
                              Text(
                                  "🧑‍🔧 Personal: $personalTexto"),
                              Text(
                                  "📅 ${proy['fecha_inicio'] ?? '—'} → ${proy['fecha_fin'] ?? '—'}"),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: estado == 'En curso'
                                      ? Colors.orange[100]
                                      : estado == 'Finalizado'
                                      ? Colors.green[100]
                                      : Colors.grey[300],
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                child: Text(
                                  estado,
                                  style: TextStyle(
                                    color: estado == 'Finalizado'
                                        ? Colors.green[700]
                                        : estado == 'En curso'
                                        ? Colors.orange[700]
                                        : Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () =>
                              _mostrarDetallesProyecto(proy),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetallesProyecto(Map<String, dynamic> proyecto) {
    final encargadosList = (proyecto['encargados'] ?? []) as List;
    final personalList = (proyecto['personal'] ?? []) as List;

    final encargadosTexto = encargadosList.isEmpty
        ? 'Sin encargados'
        : encargadosList
        .map((e) => e['nombre_usuario'] ?? 'Sin nombre')
        .join(', ');

    final personalTexto = personalList.isEmpty
        ? 'Sin personal'
        : personalList
        .map((e) => e['nombre_usuario'] ?? 'Sin nombre')
        .join(', ');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(proyecto['nombre_proyecto'] ?? 'Detalles del Proyecto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📍 Ubicación: ${proyecto['ubicacion'] ?? '—'}"),
            Text("👷 Encargados: $encargadosTexto"),
            Text("🧑‍🔧 Personal: $personalTexto"),
            Text("📅 Inicio: ${proyecto['fecha_inicio'] ?? '—'}"),
            Text("📅 Fin: ${proyecto['fecha_fin'] ?? '—'}"),
            Text("📊 Estado: ${proyecto['estado_proyecto'] ?? '—'}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
