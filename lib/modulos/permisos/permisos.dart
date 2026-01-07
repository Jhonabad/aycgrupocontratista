import 'package:flutter/material.dart';
import 'historial_permisos.dart';
import 'solicitar_permisos.dart';

class PermisosScreen extends StatelessWidget {
  final Map<String, dynamic> usuario;

  const PermisosScreen({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    final int idUsuario = usuario['id_usuario'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _botonPrincipal(
              context,
              text: 'SOLICITAR PERMISO',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SolicitarPermisoScreen(idUsuario: idUsuario),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _botonPrincipal(
              context,
              text: 'HISTORIAL DE PERMISOS',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PageHistorialPermisos(idUsuario: idUsuario),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonPrincipal(BuildContext context,
      {required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[400],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
