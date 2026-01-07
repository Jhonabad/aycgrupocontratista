import 'package:aycgcsac/modulos/gestion/gestion_asistencias/page_consul_asistencia.dart';
import 'package:aycgcsac/modulos/gestion/gestion_asistencias/page_edit_asistencia.dart';
import 'package:aycgcsac/modulos/gestion/gestion_asistencias/page_reg_asistencia.dart';
import 'package:flutter/material.dart';

class PageGesAsistencias extends StatelessWidget {


  const PageGesAsistencias({super.key});



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Gestión de Asistencias",
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
             _actionButton(
              icon: Icons.list_alt,
              label: "Consultar Asistencias",
              color: Colors.green,
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder:
                        (_)=>const PageConsultarAsistenciasAdmin()
                    )
                );
              },
            ),
            const SizedBox(height: 20),
            // 🔹 Botón 1 - Registrar asistencia
            _actionButton(
              icon: Icons.how_to_reg,
              label: "Registrar Asistencia",
              color: Colors.blueAccent,
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder:
                    (_)=>const PageRegistrarAsistenciaAdmin()
                    )
                );
              },
            ),
            const SizedBox(height: 20),
            _actionButton(
              icon: Icons.edit_calendar,
              label: "Editar/Eliminar Asistencia",
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PageEditarAsistencias(),
                  ),
                );
              },
            ),
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
