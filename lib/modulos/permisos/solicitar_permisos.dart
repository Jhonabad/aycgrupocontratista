import 'package:flutter/material.dart';
import '../../servicesapi/api_add_permisos.dart';

class SolicitarPermisoScreen extends StatefulWidget {
  final int idUsuario; // 🔥 Usuario logeado REAL

  const SolicitarPermisoScreen({super.key, required this.idUsuario});

  @override
  State<SolicitarPermisoScreen> createState() => _SolicitarPermisoScreenState();
}

class _SolicitarPermisoScreenState extends State<SolicitarPermisoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _permisoService = AddPermisoAdminService();

  final TextEditingController _motivoController = TextEditingController();
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();
  final TextEditingController _tipoPermisoController = TextEditingController();

  // 🔹 Convierte dd/mm/yyyy → yyyy-mm-dd
  String _convertirFecha(String fecha) {
    final partes = fecha.split('/');
    return "${partes[2]}-${partes[1].padLeft(2, '0')}-${partes[0].padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOLICITUD DE PERMISO'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: const Text(
                  "Formulario",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              // 🔥 Tipo de permiso libre
              TextFormField(
                controller: _tipoPermisoController,
                decoration: InputDecoration(
                  labelText: 'Tipo de Permiso',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) =>
                value!.isEmpty ? 'Escriba el tipo de permiso' : null,
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _fechaInicioController,
                readOnly: true,
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _fechaInicioController.text =
                      "${picked.day}/${picked.month}/${picked.year}";
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Fecha de inicio',
                  filled: true,
                  fillColor: Colors.grey[200],
                  suffixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) =>
                value!.isEmpty ? 'Seleccione la fecha de inicio' : null,
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _fechaFinController,
                readOnly: true,
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _fechaFinController.text =
                      "${picked.day}/${picked.month}/${picked.year}";
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Fecha de fin',
                  filled: true,
                  fillColor: Colors.grey[200],
                  suffixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) =>
                value!.isEmpty ? 'Seleccione la fecha de fin' : null,
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _motivoController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Motivo del permiso',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) => value!.isEmpty ? 'Ingrese el motivo' : null,
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final String inicio = _convertirFecha(_fechaInicioController.text);
                    final String fin = _convertirFecha(_fechaFinController.text);

                    final response = await _permisoService.registrarPermisoUsuario(
                      idUsuario: widget.idUsuario, // 🔥 usuario logeado real
                      tipoPermiso: _tipoPermisoController.text,
                      fechaInicio: inicio,
                      fechaFin: fin,
                      motivo: _motivoController.text,
                    );

                    if (response["success"] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Solicitud enviada con éxito'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      _formKey.currentState!.reset();
                      _fechaInicioController.clear();
                      _fechaFinController.clear();
                      _motivoController.clear();
                      _tipoPermisoController.clear();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${response["error"]}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'ENVIAR SOLICITUD',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
