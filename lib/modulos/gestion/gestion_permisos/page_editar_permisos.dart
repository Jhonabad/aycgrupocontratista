import 'package:flutter/material.dart';
import '../../../servicesapi/api_edit_permiso.dart';
import '../../../servicesapi/api_permisos.dart';

class EditarPermisoScreen extends StatefulWidget {
  const EditarPermisoScreen({super.key});

  @override
  State<EditarPermisoScreen> createState() => _EditarPermisoScreenState();
}

  class _EditarPermisoScreenState extends State<EditarPermisoScreen> {
    final _formKey = GlobalKey<FormState>();
    final _authService = AuthServicesPermisos();
    final _editService = EditServicesPermisos();

    List<Map<String, dynamic>> _permisos = [];
    Map<String, dynamic>? _permisoSeleccionado;
    bool _cargando = true;

    // Controladores
    final TextEditingController _nombreController = TextEditingController();
    final TextEditingController _fechaInicioController = TextEditingController();
    final TextEditingController _fechaFinController = TextEditingController();
    final TextEditingController _motivoController = TextEditingController();
    final TextEditingController _tipoPermisoController = TextEditingController();
    final TextEditingController _mensajeAdminController = TextEditingController();
    String? _estadoPermiso;

    Future<void> _cargarPermisos() async {
      setState(() => _cargando = true);
      try {
        final permisos = await _authService.obtenerTodosPermisos();
        setState(() {
          _permisos = permisos;
          _cargando = false;
        });
      } catch (e) {
        print('❌ Error al cargar permisos: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar permisos')),
        );
        setState(() => _cargando = false);
      }
    }

    void _cargarPermisoSeleccionado(Map<String, dynamic> permiso) {
      setState(() {
        _permisoSeleccionado = permiso;
        _mensajeAdminController.text = permiso['mensaje_admin'] ?? '';
        _nombreController.text = permiso['nombre_usuario'] ?? '';
        final rango = permiso['fechas_solicitadas'] ?? '';
        if (rango is String && rango.contains(',')) {
          final match = RegExp(r'\[([\d-]+),([\d-]+)\)').firstMatch(rango);
          if (match != null) {
            _fechaInicioController.text = match.group(1)!;
            _fechaFinController.text = match.group(2)!;
          } else {
            _fechaInicioController.text = '';
            _fechaFinController.text = '';
          }
        } else {
          _fechaInicioController.text = '';
          _fechaFinController.text = '';
        }

        _motivoController.text = permiso['motivo'] ?? '';
        _tipoPermisoController.text = permiso['tipo_permiso'] ?? '';
        _estadoPermiso = permiso['estado_permiso'] ?? 'Pendiente';
      });
    }

    // 🔹 Guardar cambios
    Future<void> _guardarCambios() async {
      if (!_formKey.currentState!.validate() || _permisoSeleccionado == null) {
        return;
      }

      final idPermiso = _permisoSeleccionado!['id_permisos'];
      final tipo = _tipoPermisoController.text;
      final inicio = _fechaInicioController.text;
      final fin = _fechaFinController.text;
      final motivo = _motivoController.text;
      final mensaje = _mensajeAdminController.text;
      final estado = _estadoPermiso ?? 'Pendiente';

      try {
        final confirmar = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Confirmar actualización"),
            content: const Text("¿Deseas guardar los cambios en este permiso?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Guardar"),
              ),
            ],
          ),
        );
        // 🟢 Llamada al servicio
        final respuesta = await _editService.editarPermiso(
          idPermiso: idPermiso,
          tipoPermiso: tipo,
          fechaInicio: inicio,
          fechaFin: fin,
          motivo: motivo,
          estado: estado,
          mensajeAdmin: mensaje,
        );

        if (respuesta['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Permiso actualizado correctamente'),
              backgroundColor: Colors.green[700],
              duration: const Duration(seconds: 2),
            ),
          );

          // ⏳ Esperar un momento antes de cerrar
          await Future.delayed(const Duration(milliseconds: 700));
          if (context.mounted) Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Error: ${respuesta['error']}'),
              backgroundColor: Colors.orange[700],
            ),
          );
        }
      } catch (e) {
        print('❌ Error al guardar cambios: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar cambios: $e'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    @override
    void initState() {
      super.initState();
      _cargarPermisos();
    }
    Future<void> _eliminarPermiso() async {
      if (_permisoSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Seleccione un permiso primero"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final idPermiso = _permisoSeleccionado!['id_permisos'];

      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Confirmar eliminación"),
          content: Text(
            "¿Está seguro que desea eliminar el permiso de ${_permisoSeleccionado!['nombre_usuario']}?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Eliminar"),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        final respuesta = await _editService.eliminarPermiso(idPermiso);

        if (respuesta["ok"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("🗑️ Permiso eliminado exitosamente"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));

          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ Error: ${respuesta["message"]}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('❌ Error al eliminar permiso: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }


    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Editar Permiso'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: _permisoSeleccionado?['id_permisos'],
                items: _permisos.map<DropdownMenuItem<int>>((permiso) {
                  return DropdownMenuItem<int>(
                    value: permiso['id_permisos'],
                    child: Text(
                      '${permiso['nombre_usuario'] ?? 'Sin nombre'} — ${permiso['tipo_permiso'] ?? ''}',
                    ),
                  );
                }).toList(),
                onChanged: (idSeleccionado) {
                  if (idSeleccionado != null) {
                    final permiso = _permisos.firstWhere(
                          (p) => p['id_permisos'] == idSeleccionado,
                    );
                    _cargarPermisoSeleccionado(permiso);
                    setState(() {
                      _permisoSeleccionado = permiso;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Seleccionar permiso a editar',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (_permisoSeleccionado != null)
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _nombreController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Nombre del empleado',
                            filled: true,
                            fillColor: Colors.grey[300],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _tipoPermisoController,
                          decoration: InputDecoration(
                            labelText: 'Tipo de permiso',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) => value!.isEmpty
                              ? 'Ingrese el tipo de permiso'
                              : null,
                        ),
                        const SizedBox(height: 20),

  // 🔹 Fecha de inicio
                        TextFormField(
                          controller: _fechaInicioController,
                          readOnly: true, // Evita que se edite manualmente
                          decoration: InputDecoration(
                            labelText: 'Fecha de inicio',
                            suffixIcon: const Icon(Icons.calendar_today),
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) =>
                          value!.isEmpty ? 'Ingrese la fecha de inicio' : null,
                          onTap: () async {
                            FocusScope.of(context).requestFocus(FocusNode()); // Oculta teclado
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.blueGrey, // color del encabezado
                                      onPrimary: Colors.white, // texto del encabezado
                                      onSurface: Colors.black, // texto de días
                                    ),
                                    dialogBackgroundColor: Colors.white,
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                _fechaInicioController.text =
                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),

  // 🔹 Fecha de fin
                        TextFormField(
                          controller: _fechaFinController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Fecha de fin',
                            suffixIcon: const Icon(Icons.calendar_today),
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) =>
                          value!.isEmpty ? 'Ingrese la fecha de fin' : null,
                          onTap: () async {
                            FocusScope.of(context).requestFocus(FocusNode());
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.blueGrey,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                    dialogBackgroundColor: Colors.white,
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                _fechaFinController.text =
                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _motivoController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Motivo',
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) =>
                          value!.isEmpty ? 'Ingrese el motivo' : null,
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _estadoPermiso,
                          items: const [
                            DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
                            DropdownMenuItem(value: 'Aprobado', child: Text('Aprobado')),
                            DropdownMenuItem(value: 'Rechazado', child: Text('Rechazado')),
                          ],
                          onChanged: (value) => setState(() => _estadoPermiso = value),
                          decoration: InputDecoration(
                            labelText: 'Estado del permiso',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) => value == null ? 'Seleccione un estado' : null,
                        ),
                        const SizedBox(height: 20),

                          // 🔹 CAMPO NUEVO: MENSAJE DEL ADMIN
                        TextFormField(
                          controller: _mensajeAdminController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Mensaje del administrador',
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),


                        ElevatedButton(
                          onPressed: _guardarCambios,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent                            ,
                            minimumSize:
                            const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            'GUARDAR CAMBIOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _eliminarPermiso,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent
                            ,
                            minimumSize:
                            const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            'ELIMINAR PERMISO',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
  }
