import 'package:flutter/material.dart';
import 'gestion_permisos/page_ges_permisos.dart';
import 'gestion_proyectos/page_ges_proyecto.dart';
import 'gestion_reportes/page_rep_general.dart';
import 'gestion_usuarios/page_ges_users.dart';
import 'gestion_asistencias/page_ges_asistencias.dart';

class GestionScreen extends StatelessWidget {
  const GestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGestionButton(
                  icon: Icons.person,
                  label: "Personal",
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder:
                            (_)=> const PageGesUsers()
                        )
                    );
                  },
                ),
                const SizedBox(height: 25),
                _buildGestionButton(
                  icon: Icons.people,
                  label: "Asistencias",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder:
                            (_)=>const PageGesAsistencias()
                        )
                    );
                  },
                ),
                const SizedBox(height: 25),
                _buildGestionButton(
                  icon: Icons.work,
                  label: "Proyectos",
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder:
                        (_)=> const PageGesProyectos()
                        )
                    );
                  },
                ),
                const SizedBox(height: 25),
                _buildGestionButton(
                  icon: Icons.article,
                  label: "Permisos",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder:
                            (_)=>PageGesPermisos()
                        )
                    );
                  },
                ),
                const SizedBox(height: 25),
                _buildGestionButton(
                  icon: Icons.bar_chart,
                  label: "Reportes",
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder:
                        (_)=>PageReporteGeneral()
                        )
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGestionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
