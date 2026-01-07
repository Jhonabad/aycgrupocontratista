import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../../servicesapi/api_info_user.dart';
import '../../../servicesapi/api_nuevo_proyecto.dart';

class PageCrearProyecto extends StatefulWidget {
  const PageCrearProyecto({super.key});

  @override
  State<PageCrearProyecto> createState() => _PageCrearProyectoState();
}

class _PageCrearProyectoState extends State<PageCrearProyecto> {
  final _formKey = GlobalKey<FormState>();
  final _service = CrearProyectoService();
  final _authListService = AuthServicesList();

  List<Map<String, dynamic>> _usuariosDisponibles = [];
  List<Map<String, dynamic>> _encargadosSeleccionados = [];
  List<Map<String, dynamic>> _personal = [];

  final _nombreController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _tipoController = TextEditingController();
  final _fechaInicioController = TextEditingController();
  final _fechaFinController = TextEditingController();
  final _observacionesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    try {
      final data = await _authListService.obtenerTodosUsuarios();
      setState(() {
        _usuariosDisponibles = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      print("Error al cargar usuarios: $e");
    }
  }

  Future<void> _seleccionarFecha(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es', 'ES'),
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _crearProyecto() async {
    if (!_formKey.currentState!.validate()) return;

    final encargadosList = _encargadosSeleccionados.map((e) {
      return {
        'id_usuario': e['id_usuario'],
        'cargo_en_proyecto': e['cargo_proyecto'] ?? 'Sin cargo',
        'id_rol_proyecto': e['id_rol_proyecto'] ?? 1,
        'fecha_asignacion': DateTime.now().toIso8601String().split('T').first,
        'activo': true,
      };
    }).toList();


    final personalList = _personal.map((p) {
      return {
        'id_usuario': p['id_usuario'],
        'fecha_asignacion': p['fecha_asignacion'],
        'cargo_en_proyecto': p['cargo_proyecto'] ?? 'Sin cargo',
        'id_rol_proyecto': p['id_rol_proyecto'] ?? 2,
        'activo': true,
      };
    }).toList();


    final response = await _service.registrarProyecto(
      nombreProyecto: _nombreController.text,
      ubicacion: _ubicacionController.text,
      tipoObra: _tipoController.text,
      fechaInicio: DateTime.parse(_fechaInicioController.text),
      fechaFin: DateTime.parse(_fechaFinController.text),
      observaciones: _observacionesController.text,
      encargados: encargadosList,
      personal: personalList,
    );

    if (response["ok"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "✅ Proyecto creado correctamente",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (context.mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text("❌ Error: ${response['message'] ?? 'No se pudo crear'}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ---------------------- UI WIDGETS REUTILIZADOS -------------------

  InputDecoration _inputDecoration(String label, IconData icon) {
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

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label, icon),
        validator: (v) => v == null || v.isEmpty ? "Campo obligatorio" : null,
      ),
    );
  }

  Widget _buildDateField(
      TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _seleccionarFecha(controller),
        decoration: _inputDecoration(label, icon),
        validator: (v) => v == null || v.isEmpty ? "Seleccione una fecha" : null,
      ),
    );
  }

  // ---------------------- ENCARGADOS -----------------------

  Widget _buildEncargadosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Encargados del Proyecto",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        if (_encargadosSeleccionados.isEmpty)
          const Text("No hay encargados asignados",
              style: TextStyle(color: Colors.grey)),

        ..._encargadosSeleccionados.map((enc) {
          final nombre = enc['nombre_usuario'];
          final cargo = enc['cargo_proyecto'];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.engineering, color: Colors.blue),
              title: Text(nombre),
              subtitle: Text("Cargo: $cargo"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _encargadosSeleccionados.remove(enc);
                  });
                },
              ),
            ),
          );
        }),

        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Agregar Encargado"),
          onPressed: _agregarEncargado,
        ),
      ],
    );
  }

  void _agregarEncargado() {
    Map<String, dynamic>? seleccionado;
    String cargo = '';
    int idRol = 1; // Encargado

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Agregar Encargado"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Map<String, dynamic>>(
                isExpanded: true,
                items: _usuariosDisponibles
                    .map(
                      (u) => DropdownMenuItem(
                    value: u,
                    child: Text(u['nombre_usuario']),
                  ),
                )
                    .toList(),
                onChanged: (v) => seleccionado = v,
                decoration: const InputDecoration(
                  labelText: "Seleccionar Usuario",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                decoration: const InputDecoration(
                  labelText: "Cargo en el proyecto",
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => cargo = v,
              ),
            ],
          ),

          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.pop(context),
            ),

            ElevatedButton(
              child: const Text("Agregar"),
              onPressed: () {
                if (seleccionado == null) return;

                setState(() {
                  _encargadosSeleccionados.add({
                    'id_usuario': seleccionado!['id_usuario'],
                    'nombre_usuario': seleccionado!['nombre_usuario'],
                    'cargo_proyecto': cargo.isEmpty ? "Sin cargo" : cargo,
                    'id_rol_proyecto': idRol,
                    'fecha_asignacion':
                    DateTime.now().toIso8601String().split('T').first,
                    'activo': true,
                  });
                });

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
  // ---------------------- PERSONAL -----------------------
  Widget _buildPersonalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Personal Asignado",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        if (_personal.isEmpty)
          const Text("No hay personal asignado",
              style: TextStyle(color: Colors.grey)),

        ..._personal.map((p) {
          final nombre = p['nombre_usuario'];
          final cargo = p['cargo_proyecto'];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: Text(nombre),
              subtitle: Text("Cargo: $cargo"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _personal.remove(p);
                  });
                },
              ),
            ),
          );
        }),

        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Agregar Personal"),
          onPressed: _agregarPersonal,
        ),
      ],
    );
  }

  void _agregarPersonal() {
    Map<String, dynamic>? seleccionado;
    String cargo = '';
    final fecha = DateTime.now().toIso8601String().split('T').first;
    int idRol = 2;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Agregar Personal"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Map<String, dynamic>>(
                isExpanded: true,
                items: _usuariosDisponibles
                    .map(
                      (u) => DropdownMenuItem(
                    value: u,
                    child: Text(u['nombre_usuario']),
                  ),
                )
                    .toList(),
                onChanged: (v) => seleccionado = v,
                decoration: const InputDecoration(
                  labelText: "Seleccionar Usuario",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                decoration: const InputDecoration(
                  labelText: "Cargo dentro del proyecto",
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => cargo = v,
              ),
            ],
          ),

          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.pop(context),
            ),

            ElevatedButton(
              child: const Text("Agregar"),
              onPressed: () {
                if (seleccionado == null) return;

                setState(() {
                  _personal.add({
                    'id_usuario': seleccionado!['id_usuario'],
                    'nombre_usuario': seleccionado!['nombre_usuario'],
                    'fecha_asignacion': fecha,
                    'cargo_proyecto': cargo.isEmpty ? "Sin cargo" : cargo,
                    'id_rol_proyecto': idRol,
                    'activo': true,
                  });
                });

                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'ES'),
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Crear Proyecto",
              style: TextStyle(fontWeight: FontWeight.bold)),
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(_nombreController, "Nombre del proyecto",
                    Icons.business),
                _buildTextField(
                    _ubicacionController, "Ubicación", Icons.location_on),
                _buildTextField(
                    _tipoController, "Tipo de obra", Icons.category),
                _buildDateField(_fechaInicioController, "Fecha de inicio",
                    Icons.calendar_today),
                _buildDateField(
                    _fechaFinController, "Fecha de fin", Icons.date_range),
                _buildTextField(
                    _observacionesController, "Observaciones", Icons.notes),

                const SizedBox(height: 20),

                _buildEncargadosSection(),
                const SizedBox(height: 20),
                _buildPersonalSection(),
                const SizedBox(height: 30),

                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Crear Proyecto"),
                  onPressed: _crearProyecto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
