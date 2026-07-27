import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aycgcsac/modulos/usuario/page_edit_user.dart';
import 'package:aycgcsac/main.dart';
import '../../servicesapi/api_info_user.dart';

class PageUserScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const PageUserScreen({super.key, required this.usuario});

  @override
  State<PageUserScreen> createState() => _PageUserScreenState();
}

class _PageUserScreenState extends State<PageUserScreen> {
  final AuthServicesList _api = AuthServicesList();
  late Future<Map<String, dynamic>> _usuarioFuture;
  File? _imagenSeleccionada;
  bool _subiendoImagen = false;

  @override
  void initState() {
    super.initState();
    _usuarioFuture = _obtenerUsuarioActualizado();
  }

  Future<Map<String, dynamic>> _obtenerUsuarioActualizado() async {
    try {
      final todos = await _api.obtenerTodosUsuarios();
      final usuarioActual = todos.firstWhere(
            (u) => u['id_usuario'] == widget.usuario['id_usuario'],
        orElse: () => widget.usuario,
      );
      return usuarioActual;
    } catch (e) {
      print('❌ Error al actualizar usuario: $e');
      return widget.usuario;
    }
  }

  /// 📸 Seleccionar y subir imagen a Supabase
  Future<void> _seleccionarYSubirImagen() async {
    final picker = ImagePicker();
    final XFile? imagen = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de galería'),
                onTap: () async {
                  final img = await picker.pickImage(source: ImageSource.gallery);
                  Navigator.pop(context, img);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () async {
                  final img = await picker.pickImage(source: ImageSource.camera);
                  Navigator.pop(context, img);
                },
              ),
            ],
          ),
        );
      },
    );

    if (imagen == null) return;

    setState(() => _subiendoImagen = true);

    try {
      final archivo = File(imagen.path);
      print("⚙️ Subiendo imagen para usuario con ID: ${widget.usuario['id_usuario']}");
      final url = await _api.subirImagenUsuarioSupabase(
        archivo,
        widget.usuario['id_usuario'],
      );

      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen actualizada correctamente'),
          backgroundColor: Colors.green),
        );

        setState(() {
          _imagenSeleccionada = archivo;
          _usuarioFuture = _obtenerUsuarioActualizado();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Error al subir la imagen')),
        );
      }
    } catch (e) {
      print('🚨 Error en _seleccionarYSubirImagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ No se pudo subir la imagen')),
      );
    } finally {
      setState(() => _subiendoImagen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _usuarioFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('❌ Error: ${snapshot.error}', textAlign: TextAlign.center),
            );
          }

          final usuario = snapshot.data ?? widget.usuario;
          return _buildUserInfo(context, usuario);
        },
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, Map<String, dynamic> usuario) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // 🔹 Foto de perfil + botón cámara
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 70,
                backgroundColor: Colors.grey[300],
                backgroundImage: _imagenSeleccionada != null
                    ? FileImage(_imagenSeleccionada!)
                    : (usuario['foto_usuario'] != null &&
                    usuario['foto_usuario'].toString().isNotEmpty)
                    ? NetworkImage(usuario['foto_usuario'])
                    : null,
                child: (usuario['foto_usuario'] == null ||
                    usuario['foto_usuario'].toString().isEmpty) &&
                    _imagenSeleccionada == null
                    ? const Icon(Icons.person, size: 80, color: Colors.white)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 4,
                child: InkWell(
                  onTap: _subiendoImagen ? null : _seleccionarYSubirImagen,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _subiendoImagen
                          ? Colors.grey
                          : Colors.blueAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _subiendoImagen
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.camera_alt,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 🔹 Botón editar perfil
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditUserScreen(
                    idUsuario: usuario['id_usuario'],
                    nombre: usuario['nombre_usuario'] ?? '',
                    correo: usuario['correo'] ?? '',
                    telefono: usuario['telefono'] ?? '',
                    puestoLaboral: usuario['puesto_laboral'] ?? '',
                    estadoUsuario: usuario['estado_usuario'] ?? true,
                  ),
                ),
              );

              if (result == true) {
                setState(() {
                  _usuarioFuture = _obtenerUsuarioActualizado();
                });
              }
            },
            icon: const Icon(Icons.edit, color: Colors.black),
            label: const Text("Editar perfil"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
          ),

          const SizedBox(height: 20),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Datos personales",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 10),

          _buildUserData(usuario),

          const SizedBox(height: 40),

          // 🔹 Botón cerrar sesión
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text("Cerrar sesión",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserData(Map<String, dynamic> usuario) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserInfoRow(label: "Nombre completo", value: usuario['nombre_usuario'] ?? '-'),
          const Divider(),
          _UserInfoRow(label: "Correo", value: usuario['correo'] ?? '-'),
          const Divider(),
          _UserInfoRow(label: "Teléfono", value: usuario['telefono'] ?? '-'),
          const Divider(),
          _UserInfoRow(label: "Ocupación", value: usuario['puesto_laboral'] ?? '-'),
          const Divider(),
          _UserInfoRow(label: "Perfil", value: usuario['nombre_rol'] ?? '-'),
          const Divider(),
          _UserInfoRow(
            label: "Estado",
            value: (usuario['estado_usuario'] == true ||
                usuario['estado_usuario'] == 'Activo')
                ? 'Activo'
                : 'Inactivo',
          ),
          const Divider(),
          _UserInfoRow(
            label: "Fecha de contrato",
            value: _formatFecha(usuario['fecha_contrato']),
          ),
        ],
      ),
    );
  }

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return '-';
    try {
      final date = DateTime.parse(fecha.toString());
      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year}";
    } catch (e) {
      return fecha.toString();
    }
  }
}

class _UserInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _UserInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              )),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
