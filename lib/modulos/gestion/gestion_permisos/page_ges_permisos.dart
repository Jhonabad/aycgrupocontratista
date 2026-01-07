import 'package:flutter/material.dart';
import 'package:aycgcsac/modulos/gestion/gestion_permisos/page_editar_permisos.dart';
import 'package:aycgcsac/modulos/gestion/gestion_permisos/page_nuevo_permiso.dart';
import 'package:aycgcsac/modulos/gestion/gestion_permisos/page_permisos_pend.dart';

class PageGesPermisos extends StatelessWidget {
  const PageGesPermisos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Gestión de Permisos",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // 🔹 Botón 1 - Solicitudes pendientes
            _actionButton(
              context: context,
              icon: Icons.pending_actions,
              label: "Solicitudes Pendientes",
              color: Colors.blueAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PagePermisos()),
                );
              },
            ),
           const SizedBox(height: 25),

            // 🔹 Botón 2 - Crear nuevo permiso
            _actionButton(
              context: context,
              icon: Icons.add_circle_outline,
              label: "Crear Nuevo Permiso",
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrearPermisoAdminScreen()),
                );
              },
            ),

            const SizedBox(height: 25),

            // 🔹 Botón 3 - Editar permisos
            _actionButton(
              context: context,
              icon: Icons.edit_note,
              label: "Editar/Eliminar Permisos",
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditarPermisoScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🔸 Widget reutilizable para botones de acción
  Widget _actionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}
