import 'package:aycgcsac/modulos/gestion/gestion_usuarios/page_edit_user.dart';
import 'package:aycgcsac/modulos/gestion/gestion_usuarios/page_lista_user.dart';
import 'package:aycgcsac/modulos/gestion/gestion_usuarios/page_reg_nu.dart';
import 'package:flutter/material.dart';

class PageGesUsers extends StatelessWidget {
  const PageGesUsers({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Gestión de Personal",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),

            // 🔹 Botón 1 - Lista de usuarios
            _actionButton(
              icon: Icons.group,
              label: "Lista de Personal",
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PageListUsers()),
                );
              },
            ),
            const SizedBox(height: 20),

            // 🔹 Botón 2 - Registrar nuevo usuario
            _actionButton(
              icon: Icons.person_add,
              label: "Registrar Nuevo Usuario",
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PageAddUser()),
                );
              },
            ),
            const SizedBox(height: 20),

            // 🔹 Botón 3 - Editar usuario
            _actionButton(
              icon: Icons.edit,
              label: "Editar / Eliminar",
              color: Colors.orange.shade700,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PageEditUser(),),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 🔸 Botón de acción reutilizable
  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 28),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
      ),
    );
  }
}
