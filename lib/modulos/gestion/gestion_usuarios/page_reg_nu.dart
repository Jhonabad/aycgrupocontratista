import 'package:flutter/material.dart';

import '../../../servicesapi/api_registro_n_user.dart';

class PageAddUser extends StatefulWidget {
  const PageAddUser({super.key});

  @override
  State<PageAddUser> createState() => _PageAddUserState();
}

class _PageAddUserState extends State<PageAddUser> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _cargoController = TextEditingController();
  final TextEditingController _fechaIngresoController = TextEditingController();

  final RegistroService _registroService = RegistroService();

  /// 🔹 Registrar usuario
  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final fechaParts = _fechaIngresoController.text.split('/');
      final fechaIngreso = DateTime(
        int.parse(fechaParts[2]),
        int.parse(fechaParts[1]),
        int.parse(fechaParts[0]),
      );

      final response = await _registroService.registrarUsuario(
        nombreUsuario: _nombreController.text,
        correo: _correoController.text,
        telefono: _telefonoController.text,
        puestoLaboral: _cargoController.text,
        password: _contrasenaController.text,
        fechaContrato: fechaIngreso,
        idRol: 2,
      );
      Navigator.pop(context);
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario registrado con éxito'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pop(context); // Cierra la vista de registro
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ ${response['message']}')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al registrar usuario: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'REGISTRAR NUEVO USUARIO',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v)) {
                    return 'Correo no válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _inputField(
                controller: _telefonoController,
                label: 'Teléfono',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Ingrese un teléfono' : null,
              ),
              const SizedBox(height: 15),
              _inputField(
                controller: _contrasenaController,
                label: 'Contraseña',
                icon: Icons.lock,
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 15),
              _inputField(
                controller: _cargoController,
                label: 'Puesto laboral',
                icon: Icons.work,
                validator: (v) => v!.isEmpty ? 'Ingrese el puesto' : null,
              ),
              const SizedBox(height: 15),
              _inputField(
                controller: _fechaIngresoController,
                label: 'Fecha de contrato',
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    locale: const Locale('es', 'ES'),
                  );
                  if (picked != null) {
                    _fechaIngresoController.text =
                    "${picked.day}/${picked.month}/${picked.year}";
                  }
                },
                validator: (v) =>
                v!.isEmpty ? 'Seleccione la fecha de ingreso' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _registrarUsuario,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'GUARDAR USUARIO',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Input reutilizable
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      validator: validator,
    );
  }
}
