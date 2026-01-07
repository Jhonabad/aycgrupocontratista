import 'package:flutter/material.dart';
import '../../../servicesapi/api_info_user.dart';

class PageListUsers extends StatefulWidget {
  const PageListUsers({super.key});

  @override
  State<PageListUsers> createState() => _PageListUsersState();
}

class _PageListUsersState extends State<PageListUsers> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AuthServicesList _authService = AuthServicesList();

  List<Map<String, dynamic>> usuarios = [];
  List<Map<String, dynamic>> usuariosFiltrados = [];
  bool isLoading = true;

  OverlayEntry? _overlayEntry;
  final GlobalKey _textFieldKey = GlobalKey();


  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _removeOverlay();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => isLoading = true);

    try {
      final lista = await _authService.obtenerTodosUsuarios();

      setState(() {
        usuarios = lista;
        usuariosFiltrados = lista;
      });
    } catch (e) {
      print('❌ Error al cargar usuarios: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar usuarios: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filtrarUsuarios(String query) {
    if (query.isEmpty) {
      _removeOverlay();
      return;
    }

    final resultados = usuarios
        .where((u) =>
    (u['nombre_usuario'] ?? '')
        .toString()
        .toLowerCase()
        .contains(query.toLowerCase()) ||
        (u['correo'] ?? '')
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();

    setState(() => usuariosFiltrados = resultados);

    if (_focusNode.hasFocus) {
      _showOverlaySuggestions(resultados);
    }
  }

  void _showOverlaySuggestions(List<Map<String, dynamic>> sugerencias) {
    _removeOverlay();

    // ✅ Busca el RenderBox del TextField real (usando GlobalKey)
    final renderBox = _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: offset.dx,
          top: offset.dy + renderBox.size.height + 5,
          width: renderBox.size.width,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: sugerencias.length,
                itemBuilder: (context, index) {
                  final user = sugerencias[index];
                  return ListTile(
                    leading: const Icon(Icons.person, color: Colors.blueAccent),
                    title: Text(user["nombre_usuario"] ?? "Sin nombre"),
                    subtitle: Text(user["correo"] ?? "Sin correo"),
                    onTap: () {
                      _searchController.text =
                          user["nombre_usuario"] ?? "Sin nombre";
                      _removeOverlay();
                      _mostrarDetallesUsuario(user);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LISTA DE PERSONAL',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _cargarUsuarios,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 🔹 Campo de búsqueda con sugerencias
              TextField(
                key: _textFieldKey,
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _filtrarUsuarios,
                decoration: InputDecoration(
                  hintText: 'Buscar usuario...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 🔹 Lista de usuarios
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : usuariosFiltrados.isEmpty
                    ? const Center(
                  child: Text(
                    'No se encontraron usuarios',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  itemCount: usuariosFiltrados.length,
                  itemBuilder: (context, index) {
                    final user = usuariosFiltrados[index];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.person,
                              color: Colors.white),
                        ),
                        title: Text(user["nombre_usuario"] ??
                            "Sin nombre"),
                        subtitle:
                        Text(user["correo"] ?? "Sin correo"),
                        trailing: IconButton(
                          icon: const Icon(Icons.info_outline,
                              color: Colors.blueAccent),
                          onPressed: () =>
                              _mostrarDetallesUsuario(user),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetallesUsuario(Map<String, dynamic> usuario) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  usuario["nombre_usuario"] ?? "-",
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  "📋 Datos personales",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey),
                ),
                const SizedBox(height: 8),
                _infoRow("Correo", usuario["correo"]),
                _infoRow("Teléfono", usuario["telefono"]),
                const SizedBox(height: 20),
                const Text(
                  "💼 Datos de trabajo",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey),
                ),
                const SizedBox(height: 8),
                _infoRow("Cargo", usuario["puesto_laboral"]),
                _infoRow("Rol", usuario["nombre_rol"]),
                _infoRow("Fecha de contrato", usuario["fecha_contrato"]),
                _infoRow("Estado",(usuario["estado_usuario"] == true || usuario["estado_usuario"] == 'true')
                      ? "Activo"
                      : "Inactivo",
                ),

                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text("Cerrar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      minimumSize: const Size(150, 45),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          Flexible(
            child: Text(
              value?.toString() ?? "-",
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

