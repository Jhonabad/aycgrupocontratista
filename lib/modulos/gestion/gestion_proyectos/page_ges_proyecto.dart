import 'package:aycgcsac/modulos/gestion/gestion_proyectos/page_crear_proyecto.dart';
import 'package:aycgcsac/modulos/gestion/gestion_proyectos/page_edit_proyectos.dart';
import 'package:aycgcsac/modulos/gestion/gestion_proyectos/page_ver_proyectos.dart';
import 'package:flutter/material.dart';

class PageGesProyectos extends StatelessWidget {
  const PageGesProyectos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Gestión de Proyectos",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            // 🔹 Botón 1 - Ver proyectos
            _actionButton(
              icon: Icons.folder_open,
              label: "Ver Proyectos",
              color: Colors.green,
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder:
                    (_)=>const PageVerProyectos()));
              },
            ),
            const SizedBox(height: 20),
            // 🔹 Botón 2 - Crear proyecto
            _actionButton(
              icon: Icons.add_business,
              label: "Crear Proyecto",
              color: Colors.blueAccent,
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder:
                    (_)=>const PageCrearProyecto()));
              },
            ),
            const SizedBox(height: 20),
            // 🔹 Botón 3 - Editar proyecto
            _actionButton(
              icon: Icons.edit_document,
              label: "Editar / Eliminar Proyecto",
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder:
                    (_)=>const PageEditarProyecto()));
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔸 Widget reutilizable para los botones
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
