import 'package:flutter/material.dart';
import '../../../servicesapi/api_permisos.dart';

class PagePermisos extends StatefulWidget {
  const PagePermisos({super.key});

  @override
  State<PagePermisos> createState() => _PagePermisosState();
}

class _PagePermisosState extends State<PagePermisos> {
  final AuthServicesPermisos _api = AuthServicesPermisos();
  List<Map<String, dynamic>> permisos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPermisos();
  }

  Future<void> _cargarPermisos() async {
    try {
      final data = await _api.obtenerTodosPermisos();
      setState(() {
        permisos = data;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error al cargar permisos: $e');
      setState(() => isLoading = false);
    }
  }
  Future<void> _actualizarEstado(
      int permisoId,
      String nuevoEstado,
      String mensaje,
      ) async {
    try {
      final result = await _api.actualizarEstadoPermiso(
        permisoId,
        nuevoEstado,
        mensaje,
      );
      if (result['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Permiso $nuevoEstado correctamente.')),
        );
        _cargarPermisos();
      } else {
        throw Exception(result['error'] ?? 'Error desconocido');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al actualizar: $e')),
      );
    }
  }
  /// 🔹 Mostrar detalles del permiso en una subvista (modal)
  void _mostrarDetallesPermiso(Map<String, dynamic> permiso) {
    final TextEditingController mensajeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final estado =
        (permiso['estado_permiso'] ?? '').toString().toLowerCase();
        Color colorEstado;
        if (estado == 'aprobado') {
          colorEstado = Colors.green;
        } else if (estado == 'pendiente') {
          colorEstado = Colors.orange;
        } else {
          colorEstado = Colors.red;
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Detalles del Permiso',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _detalleItem('👤 Usuario', permiso['nombre_usuario']),
              _detalleItem('📅 Fecha solicitud', permiso['fecha_solicitud']),
              _detalleItem('📆 Fechas solicitadas', permiso['fechas_solicitadas']),
              _detalleItem('📝 Motivo', permiso['motivo']),
              _detalleItem('💬 Mensaje del administrador', permiso['mensaje_admin']),
              Row(
                children: [
                  const Text('📌 Estado: ',
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    estado.isNotEmpty
                        ? '${estado[0].toUpperCase()}${estado.substring(1)}'
                        : '',
                    style: TextStyle(
                        color: colorEstado, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (estado == 'pendiente') ...[
                const Text(
                  "Mensaje para el usuario:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: mensajeController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Escribe un mensaje...",
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _actualizarEstado(
                          permiso['id_permisos'],
                          'aprobado',
                          mensajeController.text.trim(),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Aprobar'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _actualizarEstado(
                          permiso['id_permisos'],
                          'rechazado',
                          mensajeController.text.trim(),
                        );
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Rechazar'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }


  Widget _detalleItem(String titulo, dynamic valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        '$titulo: ${valor ?? '---'}',
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Permisos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : permisos.isEmpty
          ? const Center(child: Text('No hay permisos registrados'))
          : ListView.builder(
        itemCount: permisos.length,
        itemBuilder: (context, index) {
          final s = permisos[index];
          final estado =
          (s['estado_permiso'] ?? '').toString().toLowerCase();

          Color colorEstado;
          if (estado == 'aprobado') {
            colorEstado = Colors.green;
          } else if (estado == 'pendiente') {
            colorEstado = Colors.orange;
          } else {
            colorEstado = Colors.red;
          }

          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              onTap: () => _mostrarDetallesPermiso(s),
              title: Text(
                s['nombre_usuario'] ?? 'Sin nombre',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Motivo: ${s['motivo'] ?? 'Sin motivo'}'),
                  Text('Fecha: ${s['fecha_solicitud'] ?? '---'}'),
                  Row(
                    children: [
                      const Text('Estado: '),
                      Text(
                        estado.isNotEmpty
                            ? '${estado[0].toUpperCase()}${estado.substring(1)}'
                            : '',
                        style: TextStyle(
                          color: colorEstado,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: estado == 'pendiente'
                  ? const Icon(Icons.arrow_forward_ios,
                  color: Colors.grey)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
