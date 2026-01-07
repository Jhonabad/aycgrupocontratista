import 'package:flutter/material.dart';
import '../../../servicesapi/api_add_permisos.dart';
import '../../../servicesapi/api_info_user.dart';

class CrearPermisoAdminScreen extends StatefulWidget {
  const CrearPermisoAdminScreen({super.key});

  @override
  State<CrearPermisoAdminScreen> createState() =>
      _CrearPermisoAdminScreenState();
}

class _CrearPermisoAdminScreenState extends State<CrearPermisoAdminScreen> {
  final _formKey = GlobalKey<FormState>();

  final _permisoService = AddPermisoAdminService();
  final _usuariosService = AuthServicesList();

  List<Map<String, dynamic>> _usuarios = [];
  Map<String, dynamic>? _usuarioSeleccionado;

  // Controladores de campos
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();
  final TextEditingController _motivoController = TextEditingController();
  final TextEditingController _tipoPermisoController = TextEditingController();

  String? _estadoSeleccionado;
  bool _cargando = true;

  // 🔹 Cargar lista de usuarios desde Supabase
  Future<void> _cargarUsuarios() async {
    setState(() => _cargando = true);
    try {
      final usuarios = await _usuariosService.obtenerTodosUsuarios();
      setState(() {
        _usuarios = usuarios;
        _cargando = false;
      });
    } catch (e) {
      print('❌ Error al cargar usuarios: $e');
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar usuarios')),
      );
    }
  }

  // 🔹 Registrar permiso
  Future<void> _crearPermiso() async {
    if (!_formKey.currentState!.validate() || _usuarioSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    try {
      final idUsuario = _usuarioSeleccionado!['id_usuario'];
      final tipoPermiso = _tipoPermisoController.text;
      final fechaInicio = _fechaInicioController.text;
      final fechaFin = _fechaFinController.text;
      final motivo = _motivoController.text;
      final estado = _estadoSeleccionado ?? 'Pendiente';

      final respuesta = await _permisoService.registrarPermisoAdmin(
        idUsuario: idUsuario,
        tipoPermiso: tipoPermiso,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        motivo: motivo,
        estadoPermiso: estado,
      );

      if (respuesta['success']) {
        // ✅ Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Permiso creado exitosamente'),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Error: ${respuesta['error']}'),
            backgroundColor: Colors.orange[700],
          ),
        );
      }
    } catch (e) {
      print('❌ Error al crear permiso: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }


  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  // 🔹 Selector de fecha reutilizable
  Future<void> _seleccionarFecha(
      TextEditingController controller,
      ) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Permiso - Administrador'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "Registrar nuevo permiso",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 🔹 Selección de empleado
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _usuarioSeleccionado,
                items: _usuarios.map((usuario) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: usuario,
                    child: Text(usuario['nombre_usuario'] ?? 'Sin nombre'),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _usuarioSeleccionado = value),
                decoration: InputDecoration(
                  labelText: 'Seleccionar empleado',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) =>
                value == null ? 'Seleccione un empleado' : null,
              ),
              const SizedBox(height: 20),

              // 🔹 Tipo de permiso (campo libre)
              TextFormField(
                controller: _tipoPermisoController,
                decoration: InputDecoration(
                  labelText: 'Tipo de Permiso',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) =>
                value!.isEmpty ? 'Ingrese el tipo de permiso' : null,
              ),
              const SizedBox(height: 20),

              // 🔹 Fechas
              TextFormField(
                controller: _fechaInicioController,
                readOnly: true,
                onTap: () => _seleccionarFecha(_fechaInicioController),
                decoration: InputDecoration(
                  labelText: 'Fecha de inicio',
                  suffixIcon: const Icon(Icons.calendar_today),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) =>
                value!.isEmpty ? 'Seleccione fecha de inicio' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _fechaFinController,
                readOnly: true,
                onTap: () => _seleccionarFecha(_fechaFinController),
                decoration: InputDecoration(
                  labelText: 'Fecha de fin',
                  suffixIcon: const Icon(Icons.calendar_today),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) =>
                value!.isEmpty ? 'Seleccione fecha de fin' : null,
              ),
              const SizedBox(height: 20),

              // 🔹 Motivo
              TextFormField(
                controller: _motivoController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Motivo del permiso',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) =>
                value!.isEmpty ? 'Ingrese el motivo' : null,
              ),
              const SizedBox(height: 20),

              // 🔹 Estado del permiso
              DropdownButtonFormField<String>(
                value: _estadoSeleccionado,
                items: const [
                  DropdownMenuItem(
                      value: 'Pendiente', child: Text('Pendiente')),
                  DropdownMenuItem(
                      value: 'Aprobado', child: Text('Aprobado')),
                  DropdownMenuItem(
                      value: 'Rechazado', child: Text('Rechazado')),
                ],
                onChanged: (value) =>
                    setState(() => _estadoSeleccionado = value),
                decoration: InputDecoration(
                  labelText: 'Estado del permiso',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 30),

              // 🔹 Botón de guardar
              ElevatedButton(
                onPressed: _crearPermiso,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent                            ,
                  minimumSize:
                  const Size(double.infinity, 50),
                ),
                child: const Text("CREAR PERMISO",
                  style: TextStyle(
                    color:  Colors.white,
                    fontWeight: FontWeight.bold,
                  )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
