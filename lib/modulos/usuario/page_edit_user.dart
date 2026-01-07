import 'package:flutter/material.dart';
import '../../servicesapi/api_editar_user.dart';

class EditUserScreen extends StatefulWidget {
  final int idUsuario;
  final String nombre;
  final String correo;
  final String telefono;
  final String puestoLaboral;
  final bool estadoUsuario; // 🔹 Se recibe, pero no se muestra

  const EditUserScreen({
    super.key,
    required this.idUsuario,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.puestoLaboral,
    required this.estadoUsuario,
  });

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  late TextEditingController _nombreController;
  late TextEditingController _correoController;
  late TextEditingController _telefonoController;
  late String _puestoLaboral;
  late bool _estadoUsuario;

  final _editUserService = EditUserService();

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.nombre);
    _correoController = TextEditingController(text: widget.correo);
    _telefonoController = TextEditingController(text: widget.telefono);
    _puestoLaboral = widget.puestoLaboral;
    _estadoUsuario = widget.estadoUsuario; // 🔹 Se guarda, pero no se edita
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    try {
      final response = await _editUserService.actualizarUsuario(
        usuarioId: widget.idUsuario,
        nombreUsuario: _nombreController.text,
        correo: _correoController.text,
        telefono: _telefonoController.text,
        puestoLaboral: _puestoLaboral,
        estado_usuario: _estadoUsuario, // 🔹 Se envía igual
      );

      print('✅ Respuesta API: $response');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Usuario actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Devuelve true para refrescar
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al actualizar usuario: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField("Nombre", _nombreController),
            const SizedBox(height: 16),
            _buildTextField("Correo", _correoController),
            const SizedBox(height: 16),
            _buildTextField("Teléfono", _telefonoController),
            const SizedBox(height: 16),
            // 🔹 No se muestra el switch ni el puesto laboral
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _guardarCambios,
              icon: const Icon(Icons.save, color: Colors.black),
              label: const Text("Guardar cambios"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[50],
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
