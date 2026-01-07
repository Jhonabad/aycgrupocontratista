import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../../servicesapi/api_actualizar_proyecto.dart';
import '../../../servicesapi/api_info_user.dart';
import '../../../servicesapi/api_listar_proyectos.dart';

class PageEditarProyecto extends StatefulWidget {
  const PageEditarProyecto({super.key});

  @override
  State<PageEditarProyecto> createState() => _PageEditarProyectoState();
}

class _PageEditarProyectoState extends State<PageEditarProyecto> {
  final _formKey = GlobalKey<FormState>();
  final _service = ActualizarProyectoService();
  final _listProyectService = ListProyectService();
  final _authListService = AuthServicesList();

  List<Map<String, dynamic>> _proyectos = [];
  Map<String, dynamic>? _proyectoSeleccionado;

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
    _cargarProyectos();
    _cargarUsuariosDisponibles();
  }

  Future<void> _cargarUsuariosDisponibles() async {
    try {
      final data = await _authListService.obtenerTodosUsuarios();
      setState(() {
        _usuariosDisponibles = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      print('Error al cargar usuarios: $e');
    }
  }

  Future<void> _cargarProyectos() async {
    try {
      final data = await _listProyectService.obtenerProyectos();
      setState(() {
        _proyectos = data;
      });
    } catch (e) {
      print('Error al cargar proyectos: $e');
    }
  }

  void _cargarDatosProyecto(Map<String, dynamic> proyecto) {
    setState(() {
      _nombreController.text = (proyecto['nombre_proyecto'] ?? '').toString();
      _ubicacionController.text = (proyecto['ubicacion'] ?? '').toString();
      _tipoController.text = (proyecto['tipo_obra'] ?? '').toString();
      _fechaInicioController.text =
          (proyecto['fecha_inicio'] ?? proyecto['inicio'] ?? '').toString();
      _fechaFinController.text =
          (proyecto['fecha_fin'] ?? proyecto['fin'] ?? '').toString();
      _observacionesController.text =
          (proyecto['observaciones'] ?? '').toString();

      final encargadosRaw = proyecto['encargados'] ?? [];
      _encargadosSeleccionados = List<Map<String, dynamic>>.from(encargadosRaw);
      _personal = List<Map<String, dynamic>>.from(proyecto['personal'] ?? []);
    });
  }

  Future<void> _seleccionarFecha(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
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

  Future<void> _guardarCambios() async {
    if (_proyectoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione un proyecto para editar'),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    final idProyecto = _proyectoSeleccionado!['id_proyecto'];

    final encargadosList = _encargadosSeleccionados.map((e) {
      return {
        'id_usuario': e['id_usuario'],
        'cargo_proyecto': e['cargo_proyecto'] ?? 'Sin cargo',
      };
    }).toList();

    final personalList = _personal.map((p) {
      return {
        'id_usuario': p['id_usuario'],
        'fecha_asignacion': p['fecha_asignacion'],
        'cargo_proyecto': p['cargo_proyecto'] ?? 'Sin cargo',
      };
    }).toList();

    final response = await _service.actualizarProyecto(
      idProyecto: idProyecto,
      nombreProyecto: _nombreController.text,
      ubicacion: _ubicacionController.text,
      tipoObra: _tipoController.text,
      fechaInicio:
      DateTime.tryParse(_fechaInicioController.text) ?? DateTime.now(),
      fechaFin:
      DateTime.tryParse(_fechaFinController.text) ?? DateTime.now(),
      observaciones: _observacionesController.text,
      encargados: encargadosList,
      personal: personalList,
    );
    if (response["ok"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '✅ Proyecto actualizado correctamente',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (context.mounted) {
        Navigator.pop(context); // Regresa al menú principal
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Error: ${response['message'] ?? 'No se pudo actualizar'}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
          dismissDirection: DismissDirection.up,
        ),
      );
    }
  }

  Future<void> _eliminarProyecto() async {
    if (_proyectoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione un proyecto para eliminar'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final idProyecto = _proyectoSeleccionado!['id_proyecto'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Está seguro de que quiere eliminar el proyecto '
              '"${_proyectoSeleccionado!['nombre_proyecto']}"?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await _service.eliminarProyecto(idProyecto);

    if (response["ok"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Proyecto eliminado correctamente'),
          backgroundColor: Colors.red,
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (context.mounted) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${response["message"] ?? "No se pudo eliminar"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  void _agregarEncargado() {
    Map<String, dynamic>? seleccionado;
    String cargoProyecto = '';

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Agregar Encargado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Map<String, dynamic>>(
                isExpanded: true,
                items: _usuariosDisponibles.map((u) {
                  return DropdownMenuItem(
                    value: u,
                    child: Text(
                      u['nombre_usuario'] ?? 'Sin nombre',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) => seleccionado = value,
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Usuario',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Cargo en el proyecto',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => cargoProyecto = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (seleccionado != null) {
                  setState(() {
                    _encargadosSeleccionados.add({
                      'id_usuario': seleccionado!['id_usuario'],
                      'nombre_usuario': seleccionado!['nombre_usuario'],
                      'cargo_proyecto': cargoProyecto.isNotEmpty
                          ? cargoProyecto
                          : 'Sin cargo',
                    });
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }
  void _eliminarEncargado(int id) {
    setState(() {
      _encargadosSeleccionados.removeWhere((e) => e['id_usuario'] == id);
    });
  }
  void _agregarPersonal() {
    Map<String, dynamic>? seleccionado;
    String cargo = '';
    DateTime fecha = DateTime.now();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Agregar Personal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Map<String, dynamic>>(
                isExpanded: true,
                items: _usuariosDisponibles.map((u) {
                  return DropdownMenuItem(
                    value: u,
                    child: Text(
                      u['nombre_usuario'] ?? 'Sin nombre',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) => seleccionado = value,
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Usuario',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Cargo en el proyecto',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => cargo = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (seleccionado != null) {
                  setState(() {
                    _personal.add({
                      'id_usuario': seleccionado!['id_usuario'],
                      'nombre_usuario': seleccionado!['nombre_usuario'],
                      'fecha_asignacion':
                      fecha
                          .toIso8601String()
                          .split('T')
                          .first,
                      'cargo_proyecto': cargo,
                    });
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }
  void _eliminarPersonal(int index) {
    setState(() {
      _personal.removeAt(index);
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
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'ES'),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Editar Proyecto',
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<Map<String, dynamic>>(
                  isExpanded: true,
                  value: _proyectoSeleccionado,
                  items: _proyectos.map((proy) {
                    final nombre =
                    (proy['nombre_proyecto'] ?? 'Proyecto sin nombre')
                        .toString();
                    return DropdownMenuItem(
                      value: proy,
                      child: Text(nombre, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _proyectoSeleccionado = value;
                      if (value != null) _cargarDatosProyecto(value);
                    });
                  },
                  decoration:
                  _inputDecoration('Seleccionar Proyecto', Icons.business),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                    _nombreController, 'Nombre del proyecto', Icons.edit),
                _buildTextField(
                    _ubicacionController, 'Ubicación', Icons.location_on),
                _buildTextField(
                    _tipoController, 'Tipo de obra', Icons.category),
                _buildDateField(_fechaInicioController, 'Fecha de inicio',
                    Icons.calendar_today),
                _buildDateField(
                    _fechaFinController, 'Fecha de fin', Icons.date_range),
                _buildTextField(
                    _observacionesController, 'Observaciones', Icons.notes),
                const SizedBox(height: 20),
                _buildEncargadosSection(),
                const SizedBox(height: 20),
                _buildPersonalSection(),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _guardarCambios,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Cambios'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: _eliminarProyecto,
                  icon: const Icon(Icons.delete),
                  label: const Text('Eliminar Proyecto'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label, icon),
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
      ),
    );
  }
  Widget _buildEncargadosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Encargados del Proyecto',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        if (_encargadosSeleccionados.isEmpty)
          const Text('No hay encargados asignados',
              style: TextStyle(color: Colors.grey)),

        ..._encargadosSeleccionados.map((encargado) {
          final nombre = encargado['nombre_usuario'] ?? 'Sin nombre';
          final cargo = encargado['cargo_proyecto'] ?? 'Sin cargo';
          final id = encargado['id_usuario'];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.engineering, color: Colors.blueAccent),

              title: Text(
                nombre,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                "Cargo: $cargo",
                overflow: TextOverflow.ellipsis,
              ),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () => _editarEncargado(encargado),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _eliminarEncargado(id),
                  ),
                ],
              ),
            ),
          );
        }),

        TextButton.icon(
          onPressed: _agregarEncargado,
          icon: const Icon(Icons.add),
          label: const Text('Agregar Encargado'),
        ),
      ],
    );
  }
  void _editarEncargado(Map<String, dynamic> encargado) {
    Map<String, dynamic>? seleccionado = encargado;
    String cargoProyecto = encargado['cargo_proyecto'] ?? '';

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Editar Encargado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Map<String, dynamic>>(
                isExpanded: true,
                value: seleccionado,
                items: _usuariosDisponibles.map((u) {
                  return DropdownMenuItem(
                    value: u,
                    child: Text(
                      u['nombre_usuario'] ?? 'Sin nombre',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) => seleccionado = value,
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Usuario',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                initialValue: cargoProyecto,
                decoration: const InputDecoration(
                  labelText: 'Cargo dentro del proyecto',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => cargoProyecto = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (seleccionado != null) {
                  setState(() {
                    final index = _encargadosSeleccionados.indexOf(encargado);

                    _encargadosSeleccionados[index] = {
                      'id_usuario': seleccionado!['id_usuario'],
                      'nombre_usuario': seleccionado!['nombre_usuario'],
                      'cargo_proyecto': cargoProyecto.isNotEmpty
                          ? cargoProyecto
                          : 'Sin cargo',
                    };
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
  Widget _buildPersonalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal Asignado',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        if (_personal.isEmpty)
          const Text('No hay personal asignado',
              style: TextStyle(color: Colors.grey)),

        ..._personal.asMap().entries.map((entry) {
          final i = entry.key;
          final persona = entry.value;

          final nombre = persona['nombre_usuario'] ?? 'Sin nombre';
          final cargo = persona['cargo_proyecto'] ?? 'Sin cargo';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.green),

              title: Text(
                nombre,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Cargo: $cargo',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () => _editarPersonal(i, persona),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _eliminarPersonal(i),
                  ),
                ],
              ),
            ),
          );
        }),

        TextButton.icon(
          onPressed: _agregarPersonal,
          icon: const Icon(Icons.add),
          label: const Text('Agregar Personal'),
        ),
      ],
    );
  }
  void _editarPersonal(int index, Map<String, dynamic> persona) {
    Map<String, dynamic>? seleccionado = _usuariosDisponibles.firstWhere(
          (u) => u['id_usuario'] == persona['id_usuario'],
      orElse: () => {},
    );
    String cargoProyecto = persona['cargo_proyecto'] ?? '';

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Editar Personal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Map<String, dynamic>>(
                isExpanded: true,
                value: seleccionado,
                items: _usuariosDisponibles.map((u) {
                  return DropdownMenuItem(
                    value: u,
                    child: Text(
                      u['nombre_usuario'] ?? 'Sin nombre',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) => seleccionado = value,
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Usuario',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                initialValue: cargoProyecto,
                decoration: const InputDecoration(
                  labelText: 'Cargo dentro del proyecto',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => cargoProyecto = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (seleccionado != null) {
                  setState(() {
                    _personal[index] = {
                      'id_usuario': seleccionado!['id_usuario'],
                      'nombre_usuario': seleccionado!['nombre_usuario'],
                      'fecha_asignacion': persona['fecha_asignacion'],
                      'cargo_proyecto': cargoProyecto.isNotEmpty ? cargoProyecto : 'Sin cargo',
                    };
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}
