import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../servicesapi/api_reporte_general.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


class PageReporteGeneral extends StatefulWidget {
  const PageReporteGeneral({super.key});

  @override
  State<PageReporteGeneral> createState() => _PageReporteGeneralState();
}

class _PageReporteGeneralState extends State<PageReporteGeneral> {
  String _tipoSeleccionado = 'Todos';
  String _personaSeleccionada = 'Todos';
  String _estadoSeleccionado = 'Todos';
  String _estadoProyectoSeleccionado = 'Todos';
  String _estadoPersonalSeleccionado = 'Todos';
  String _proyectoSeleccionado = 'Todos';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  List<Map<String, dynamic>> _resultados = [];
  List<String> _personas = ['Todos'];
  List<String> _proyectos = ['Todos'];
  List<String> _tipos = [
    'Todos',
    'Asistencias',
    'Proyectos',
    'Permisos',
    'Personal'
  ];
  List<String> _estados = ['Todos', 'Aprobado', 'Pendiente', 'Rechazado'];
  List<String> _estadosProyecto = ['Todos', 'Planificado', 'En curso', 'Finalizado'];
  List<String> _estadosPersonal = ['Todos', 'Encargados', 'Personal'];

  bool _cargando = false;

  int _totalProyectosGlobal = 0;
  int _totalAsistenciasGlobal = 0;
  int _totalPermisosGlobal = 0;
  int _totalHorasGlobal = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      await _cargarTotalesGlobales();
      await _cargarProyectosIniciales();
    });
  }

  Future<void> _cargarTotalesGlobales() async {
    final data = await ReporteGeneralApi.obtenerReporteGeneral(
      tipo: 'Todos',
      persona: 'Todos',
      estado: 'Todos',
      proyecto: 'Todos',
    );

    final asistencias = data.where((r) => r['tipo'] == 'Asistencia').toList();
    final proyectos = data.where((r) => r['tipo'] == 'Proyecto').toList();
    final permisos = data.where((r) => r['tipo'] == 'Permiso').toList();

    setState(() {
      _totalProyectosGlobal = proyectos.length;
      _totalAsistenciasGlobal = asistencias.length;
      _totalPermisosGlobal = permisos.length;
      _totalHorasGlobal = asistencias.fold<int>(
        0,
            (sum, a) => sum + ((a['horas'] ?? 0) as num).toInt(),
      );
    });
  }

  Future<void> _cargarProyectosIniciales() async {
    setState(() => _cargando = true);

    final data = await ReporteGeneralApi.obtenerReporteGeneral(
      tipo: 'Proyectos',
      persona: 'Todos',
      estado: 'Todos',
      proyecto: 'Todos',
    );

    final proyectos = data
        .map((e) => e['proyecto']?.toString() ?? e['nombre']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    setState(() {
      _proyectos = ['Todos', ...proyectos];
      _cargando = false;
    });

    await _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);

    final data = await ReporteGeneralApi.obtenerReporteGeneral(
      tipo: _tipoSeleccionado,
      persona: _personaSeleccionada,
      estado: _tipoSeleccionado == 'Proyectos'
          ? _estadoProyectoSeleccionado
          : _tipoSeleccionado == 'Personal'
          ? _estadoPersonalSeleccionado
          : _estadoSeleccionado,
      proyecto: _proyectoSeleccionado,
      fechaInicio: _fechaInicio != null
          ? DateFormat('yyyy-MM-dd').format(_fechaInicio!)
          : null,
      fechaFin: _fechaFin != null
          ? DateFormat('yyyy-MM-dd').format(_fechaFin!)
          : null,
    );

    final personas = data
        .map((e) => (e['persona']?.toString().trim() ?? ''))
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    setState(() {
      _personas = ['Todos', ...personas];
      _resultados = data;
      _cargando = false;
    });
  }

  Future<void> _seleccionarFecha(BuildContext context, bool inicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (inicio) {
          _fechaInicio = picked;
        } else {
          _fechaFin = picked;
        }
      });
      if (_tipoSeleccionado == 'Asistencias') _cargarDatos();
    }
  }

  Future<void> _exportar() async {
    if (_resultados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos para exportar')),
      );
      return;
    }

    final pdf = pw.Document();

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final now = dateFormat.format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Reporte General', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.Text(now, style: pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Filtros aplicados:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.Text('Tipo: $_tipoSeleccionado'),
            pw.Text('Persona: $_personaSeleccionada'),
            pw.Text('Proyecto: $_proyectoSeleccionado'),
            if (_fechaInicio != null && _fechaFin != null)
              pw.Text(
                  'Rango de fechas: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}'),
            pw.SizedBox(height: 15),

            pw.Table.fromTextArray(
              headers: ['Tipo', 'Persona', 'Proyecto', 'Estado', 'Horas', 'Fecha'],
              data: _resultados.map((r) {
                return [
                  r['tipo'] ?? '',
                  r['persona'] ?? '',
                  r['proyecto'] ?? '',
                  r['estado'] ?? '',
                  r['horas']?.toString() ?? '',
                  r['fecha'] != null
                      ? DateFormat('dd/MM/yyyy').format(DateTime.parse(r['fecha']))
                      : '',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellHeight: 25,
              columnWidths: {
                0: const pw.FixedColumnWidth(60),
                1: const pw.FixedColumnWidth(80),
                2: const pw.FixedColumnWidth(80),
                3: const pw.FixedColumnWidth(60),
                4: const pw.FixedColumnWidth(40),
                5: const pw.FixedColumnWidth(60),
              },
            ),

            pw.SizedBox(height: 25),
            pw.Text(
              'Totales:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.Text('Asistencias: ${_resultados.where((r) => r['tipo'] == 'Asistencia').length}'),
            pw.Text('Proyectos: ${_resultados.where((r) => r['tipo'] == 'Proyecto').length}'),
            pw.Text('Permisos: ${_resultados.where((r) => r['tipo'] == 'Permiso').length}'),
            pw.Text('Horas totales: ${_resultados.fold<int>(0, (s, r) => s + ((r['horas'] ?? 0) as num).toInt())}'),
          ];
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/reporte_general.pdf");
      await file.writeAsBytes(await pdf.save());

      // Mostrar opción de ver o compartir PDF
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'reporte_general.pdf');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ PDF generado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al generar PDF: $e')),
      );
    }
  }

  /// 🔹 Cuadros de resumen ajustados en tamaño
  Widget _buildResumen() {
    if (_resultados.isEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _cardResumen('Asistencias', '0', Colors.blue),
          _cardResumen('Proyectos', '0', Colors.green),
          _cardResumen('Permisos', '0', Colors.orange),
          _cardResumen('Horas', '0', Colors.purple),
        ],
      );
    }

    // 🔹 Calcula dinámicamente según los resultados visibles
    final totalAsistencias =
        _resultados.where((r) => r['tipo'] == 'Asistencia').length;
    final totalProyectos =
        _resultados.where((r) => r['tipo'] == 'Proyecto').length;
    final totalPermisos =
        _resultados.where((r) => r['tipo'] == 'Permiso').length;

    final totalHoras = _resultados.fold<int>(
      0,
          (sum, r) {
        final h = (r['horas'] ?? 0);
        return sum + (h is num ? h.toInt() : int.tryParse(h.toString()) ?? 0);
      },
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _cardResumen('Asistencias', totalAsistencias.toString(), Colors.blue),
        _cardResumen('Proyectos', totalProyectos.toString(), Colors.green),
        _cardResumen('Permisos', totalPermisos.toString(), Colors.orange),
        _cardResumen('Horas', totalHoras.toString(), Colors.purple),
      ],
    );
  }

  /// 🔹 Tarjeta de resumen con estilo compacto
  Widget _cardResumen(String titulo, String valor, Color color) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 20,
      child: Card(
        elevation: 2,
        color: color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text(
                valor,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                titulo,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Reporte General', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _exportar)],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildResumen(),
            const SizedBox(height: 16),

            /// 🔸 Proyecto
            DropdownButtonFormField<String>(
              value: _proyectoSeleccionado,
              isExpanded: true,
              items: _proyectos
                  .map((p) =>
                  DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis)))
                  .toList(),
              decoration: _decoracionCampo('Proyecto', Icons.work),
              onChanged: (v) {
                setState(() => _proyectoSeleccionado = v!);
                _cargarDatos();
              },
            ),
            const SizedBox(height: 10),

            /// 🔸 Tipo
            DropdownButtonFormField<String>(
              value: _tipoSeleccionado,
              isExpanded: true,
              items: _tipos
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              decoration: _decoracionCampo('Tipo de Reporte', Icons.assignment),
              onChanged: (v) {
                setState(() => _tipoSeleccionado = v!);
                _cargarDatos();
              },
            ),
            const SizedBox(height: 10),

            /// 🔸 Persona o Estado Proyecto o Estado Personal
            if (_tipoSeleccionado == 'Proyectos')
              DropdownButtonFormField<String>(
                value: _estadoProyectoSeleccionado,
                isExpanded: true,
                items: _estadosProyecto
                    .map((e) =>
                    DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                decoration: _decoracionCampo('Estado del Proyecto', Icons.flag),
                onChanged: (v) {
                  setState(() => _estadoProyectoSeleccionado = v!);
                  _cargarDatos();
                },
              )
            else if (_tipoSeleccionado == 'Personal')
              DropdownButtonFormField<String>(
                value: _estadoPersonalSeleccionado,
                isExpanded: true,
                items: _estadosPersonal
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                decoration:
                _decoracionCampo('Estado del Personal', Icons.badge),
                onChanged: (v) {
                  setState(() => _estadoPersonalSeleccionado = v!);
                  _cargarDatos();
                },
              )
            else
              DropdownButtonFormField<String>(
                value: _personaSeleccionada,
                isExpanded: true,
                items: _personas
                    .map((p) =>
                    DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis)))
                    .toList(),
                decoration: _decoracionCampo('Persona', Icons.person),
                onChanged: (v) {
                  setState(() => _personaSeleccionada = v!);
                  _cargarDatos();
                },
              ),

            const SizedBox(height: 10),

            /// 🔸 Estado permisos
            if (_tipoSeleccionado == 'Permisos')
              DropdownButtonFormField<String>(
                value: _estadoSeleccionado,
                isExpanded: true,
                items: _estados
                    .map((e) =>
                    DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                decoration: _decoracionCampo('Estado', Icons.flag),
                onChanged: (v) {
                  setState(() => _estadoSeleccionado = v!);
                  _cargarDatos();
                },
              ),

            const SizedBox(height: 10),

            /// 🔸 Fechas (solo asistencias)
            if (_tipoSeleccionado == 'Asistencias')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _seleccionarFecha(context, true),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_fechaInicio == null
                          ? 'Fecha inicio'
                          : dateFormat.format(_fechaInicio!)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _seleccionarFecha(context, false),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_fechaFin == null
                          ? 'Fecha fin'
                          : dateFormat.format(_fechaFin!)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            /// 🔸 Lista resultados
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _resultados.isEmpty
                  ? const Center(
                child: Text('No hay datos para mostrar',
                    style: TextStyle(color: Colors.grey)),
              )
                  : ListView.builder(
                itemCount: _resultados.length,
                itemBuilder: (context, i) {
                  final r = _resultados[i];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(
                        r['tipo'] == 'Asistencia'
                            ? Icons.access_time
                            : r['tipo'] == 'Proyecto'
                            ? Icons.business_center
                            : r['tipo'] == 'Permiso'
                            ? Icons.assignment
                            : Icons.people,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        r['tipo'] == 'Proyecto'
                            ? (r['nombre'] ?? '')
                            : (r['persona'] ?? 'Desconocido'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (r['proyecto'] != null)
                            Text("🏗️ Proyecto: ${r['proyecto']}",
                                overflow: TextOverflow.ellipsis),
                          if (r['rol'] != null)
                            Text("👤 Rol: ${r['rol']}"),
                          if (r['horas'] != null)
                            Text("⏱️ Horas: ${r['horas']}"),
                          if (r['estado'] != null)
                            Text("📋 Estado: ${r['estado']}",
                                overflow: TextOverflow.ellipsis),
                          if (r['motivo'] != null)
                            Text("📝 Motivo: ${r['motivo']}",
                                overflow: TextOverflow.ellipsis),
                          if (r['fecha'] != null)
                            Text(
                                "📅 ${dateFormat.format(DateTime.parse(r['fecha']))}"),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            ElevatedButton.icon(
              onPressed: _exportar,
              icon: const Icon(Icons.download),
              label: const Text('Exportar Reporte'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blueAccent,
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoracionCampo(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
