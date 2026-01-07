import 'package:flutter/material.dart';

import '../../../servicesapi/api_editar_user.dart';
import '../../../servicesapi/api_info_user.dart';

class PageEditUser extends StatefulWidget {
  const PageEditUser({super.key});

  @override
  State<PageEditUser> createState() => _PageEditUserState();
}

class _PageEditUserState extends State<PageEditUser> {
  final _formKey = GlobalKey<FormState>();

  // 🔹 Servicios
  final _editUserService = EditUserService();
  final _authService = AuthServicesList();

  // 🔹 Controladores
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _puestoLaboralController = TextEditingController();

  // 🔹 Variables de estado
  bool _estadoActivo = true;
  List<Map<String, dynamic>> _usuarios = [];
  Map<String, dynamic>? _usuarioSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  /// 🔹 Cargar lista de usuarios
  Future<void> _cargarUsuarios() async {
    try {
      final usuarios = await _authService.obtenerTodosUsuarios();
      setState(() {
        _usuarios = usuarios;
      });
    } catch (e) {
      print('❌ Error cargando usuarios: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cargar usuarios'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 🔹 Actualizar usuario
  Future<void> _actualizarUsuario() async {
    if (_formKey.currentState!.validate() && _usuarioSeleccionado != null) {
      final usuarioId = _usuarioSeleccionado!['id_usuario'];

      try {
        final result = await _editUserService.actualizarUsuario(
          usuarioId: usuarioId,
          nombreUsuario: _nombreController.text,
          correo: _correoController.text,
          telefono: _telefonoController.text,
          puestoLaboral: _puestoLaboralController.text,
          estado_usuario: _estadoActivo,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Usuario actualizado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      } catch (e) {
        print('❌ Error al actualizar: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el usuario'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// 🔹 Eliminar usuario
  Future<void> _eliminarUsuario() async {
    if (_usuarioSeleccionado == null) return;

    final scaffoldContext = context;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Seguro que desea eliminar a "${_usuarioSeleccionado!['nombre_usuario']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Cierra el diálogo
              try {
                final result = await _editUserService.eliminarUsuario(
                  _usuarioSeleccionado!['id_usuario'],
                );

                if (!mounted) return;

                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  SnackBar(
                    content: Text('Usuario eliminado correctamente.'),
                    backgroundColor: Colors.redAccent,
                      duration: Duration(seconds: 3)
                  ),
                );

                await Future.delayed(const Duration(seconds: 2));

                if (!mounted) return;
                Navigator.pop(scaffoldContext);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  const SnackBar(
                    content: Text('Error al eliminar el usuario'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Interfaz
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EDITAR / ELIMINAR USUARIO',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🔹 Selector de usuario
              DropdownButtonFormField<Map<String, dynamic>>(
                decoration: _dropdownDecoration('Seleccionar usuario', Icons.person_search),
                value: _usuarioSeleccionado,
                items: _usuarios.map((user) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: user,
                    child: Text(user['nombre_usuario'] ?? 'Sin nombre'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _usuarioSeleccionado = value;
                    _nombreController.text = value?['nombre_usuario'] ?? '';
                    _correoController.text = value?['correo'] ?? '';
                    _telefonoController.text = value?['telefono'] ?? '';
                    _puestoLaboralController.text = value?['puesto_laboral'] ?? '';
                    _estadoActivo = value?['estado_usuario'] ?? false;
                  });
                },
                validator: (value) => value == null ? 'Seleccione un usuario' : null,
              ),
              const SizedBox(height: 20),

              _inputField(
                controller: _nombreController,
                label: 'Nombre completo',
                icon: Icons.person,
                validator: (v) => v!.isEmpty ? 'Ingrese el nombre' : null,
              ),
              const SizedBox(height: 15),

              _inputField(
                controller: _correoController,
                label: 'Correo electrónico',
                icon: Icons.email,
                validator: (v) {
                  if (v!.isEmpty) return 'Ingrese un correo';
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v)) return 'Correo no válido';
                  return null;
                },
              ),
              const SizedBox(height: 15),

              _inputField(
                controller: _telefonoController,
                label: 'Teléfono',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Ingrese un número de teléfono' : null,
              ),
              const SizedBox(height: 15),

              _inputField(
                controller: _puestoLaboralController,
                label: 'Puesto laboral',
                icon: Icons.badge,
                validator: (v) => v!.isEmpty ? 'Ingrese el puesto laboral' : null,
              ),
              const SizedBox(height: 20),

              // 🔹 Estado del usuario
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estado del usuario:', style: TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        Text(
                          _estadoActivo ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            color: _estadoActivo ? Colors.green : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Switch(
                          value: _estadoActivo,
                          onChanged: (value) {
                            setState(() {
                              _estadoActivo = value;
                            });
                          },
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.redAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _actualizarUsuario,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'GUARDAR CAMBIOS',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: _eliminarUsuario,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ELIMINAR USUARIO',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Campo reutilizable
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  /// 🔹 Decoración reutilizable para Dropdowns
  InputDecoration _dropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[200],
    );
  }
}
