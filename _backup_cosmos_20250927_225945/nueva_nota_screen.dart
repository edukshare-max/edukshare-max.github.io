// lib/screens/nueva_nota_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value, OrderingTerm, OrderingMode;
import 'package:intl/intl.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;

// Adjuntos
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// PDF / Print
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../data/db.dart' as DB;
import '../data/cloudant_query.dart';
import '../data/sync_cloudant.dart'; // kCouchBaseUrl, kCouchDbName, kCouchUser, kCouchPass

// Formulario (Editar carnet)
import 'form_screen.dart';

// UI UAGro
import 'package:cres_carnets_ibmcloud/ui/uagro_widgets.dart';

// ====== Supervisor key ======
const String kSupervisorKey = 'UAGROcres2025';

// Helper UI seguro
Widget safe(Widget Function() builder) {
  try {
    return builder();
  } catch (e, st) {
    // ignore: avoid_print
    print('🔥 UI error: $e\n$st');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(.25)),
      ),
      child: const Text(
        'Ocurrió un error de UI (revisa consola).',
        style: TextStyle(color: Colors.red),
      ),
    );
  }
}

class NuevaNotaScreen extends StatefulWidget {
  final DB.AppDatabase db;
  final String? matriculaInicial;
  const NuevaNotaScreen({super.key, required this.db, this.matriculaInicial});

  @override
  State<NuevaNotaScreen> createState() => _NuevaNotaScreenState();
}

class _NuevaNotaScreenState extends State<NuevaNotaScreen> {
  // Controllers base
  final _mat = TextEditingController();
  final _depto = TextEditingController(); // cuando "Otra…" se usa este como texto libre
  final _tratante = TextEditingController();
  final _cuerpo = TextEditingController();
  final _diagnostico = TextEditingController();

  // Campos específicos de Nutrición
  final _peso = TextEditingController();   // kg
  final _talla = TextEditingController();  // m
  final _cintura = TextEditingController(); // cm
  final _cadera = TextEditingController();  // cm

  String? _tipoConsulta; // 'Primera vez' | 'Subsecuente'
  final List<PlatformFile> _adjuntos = [];

  // API Couch
  final _api = CloudantQueries();

  // Estado
  bool _cargando = false;
  String? _error;

  // Mostrar todas o últimas 5
  bool _showAllCloud = false;
  bool _showAllLocal = false;
  static const int _limit = 5;

  // Datos NUBE/LOCAL
  Map<String, dynamic>? _expedienteCloud;
  List<Map<String, dynamic>> _notasCloud = const [];

  DB.HealthRecord? _expedienteLocal;
  List<DB.Note> _notasLocal = const [];

  // Atención integral (≥2 servicios diferentes)
  bool _atencionIntegral = false;

  // Departamento seleccionado (por lista)
  String? _deptChoice;
  final List<String> _deptOpciones = const [
    'Departamento psicopedagógico',
    'Consultorio médico',
    'Consultorio de Nutrición',
    'Consultorio Odontología',
    'Atención estudiantil',
    'Otra…',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.matriculaInicial != null &&
        widget.matriculaInicial!.trim().isNotEmpty) {
      _mat.text = widget.matriculaInicial!.trim();
      _buscar();
    }
    // Cálculo IMC en tiempo real
    _peso.addListener(_refresh);
    _talla.addListener(_refresh);
    _cintura.addListener(_refresh);
    _cadera.addListener(_refresh);
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _mat.dispose();
    _depto.dispose();
    _tratante.dispose();
    _cuerpo.dispose();
    _diagnostico.dispose();
    _peso.dispose();
    _talla.dispose();
    _cintura.dispose();
    _cadera.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal());
  }

  String _show(dynamic v) {
    if (v == null) return '—';
    if (v is String && v.trim().isEmpty) return '—';
    return '$v';
  }

  Widget _line(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text('$label: ${_show(value)}'),
    );
  }

  // ====== Buscar expediente + notas ======
  Future<void> _buscar() async {
    final m = _mat.text.trim();
    if (m.isEmpty) {
      setState(() {
        _expedienteCloud = null;
        _notasCloud = const [];
        _expedienteLocal = null;
        _notasLocal = const [];
        _atencionIntegral = false;
        _error = 'Escribe una matrícula para buscar.';
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      // NUBE
      Map<String, dynamic>? pac;
      List<Map<String, dynamic>> notasNube = const [];
      try {
        pac = await _api.fetchLatestPatient(m);
      } catch (e) {
        _error = 'Nube: $e';
      }
      try {
        notasNube = await _api.fetchNotes(m);
      } catch (e) {
        _error = (_error == null) ? 'Nube: $e' : '${_error!}\nNube: $e';
      }

      // LOCAL
      DB.HealthRecord? expLocal;
      List<DB.Note> notasLocal = const [];
      final qExp = widget.db.select(widget.db.healthRecords)
        ..where((t) => t.matricula.equals(m))
        ..orderBy([
          (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
        ])
        ..limit(1);
      final expList = await qExp.get();
      if (expList.isNotEmpty) expLocal = expList.first;

      final qNotas = widget.db.select(widget.db.notes)
        ..where((t) => t.matricula.equals(m))
        ..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]);
      notasLocal = await qNotas.get();

      // Calcular atención integral: unión de departamentos nube + local
      final servicios = <String>{};
      for (final n in notasNube) {
        final d = (n['departamento'] ?? '').toString().trim();
        if (d.isNotEmpty) servicios.add(d);
      }
      for (final n in notasLocal) {
        final d = n.departamento.trim();
        if (d.isNotEmpty) servicios.add(d);
      }
      final integral = servicios.length >= 2;

      if (!mounted) return;
      setState(() {
        _expedienteCloud = pac;
        _notasCloud = notasNube;
        _expedienteLocal = expLocal;
        _notasLocal = notasLocal;
        _atencionIntegral = integral;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  // ====== Adjuntar archivos (OPCIONAL) ======
  Future<void> _pickAdjuntos() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      if (res == null) return;
      setState(() {
        _adjuntos.addAll(res.files);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron seleccionar archivos: $e')),
      );
    }
  }

  Future<List<String>> _guardarAdjuntosLocal(String matricula) async {
    final List<String> rutas = [];
    if (_adjuntos.isEmpty) return rutas;

    try {
      final baseDir = await getApplicationSupportDirectory();
      final dir = Directory(p.join(baseDir.path, 'adjuntos', matricula));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      for (final f in _adjuntos) {
        try {
          if (f.path == null) continue;
          // Windows: limpiar nombre
          final safeName = f.name.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
          final dstName = '${DateTime.now().microsecondsSinceEpoch}_$safeName';
          final dst = File(p.join(dir.path, dstName));
          await File(f.path!).copy(dst.path);
          rutas.add(dst.path);
        } catch (e) {
          // ignore: avoid_print
          print('No se pudo copiar adjunto ${f.name}: $e');
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Error creando carpeta de adjuntos: $e');
      return [];
    }
    return rutas;
  }

  // ====== Nutrición: cálculos ======
  double? get _pesoVal {
    final v = double.tryParse(_peso.text.replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return v;
  }

  double? get _tallaVal {
    final v = double.tryParse(_talla.text.replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return v;
  }

  double? get _imcVal {
    final p = _pesoVal, t = _tallaVal;
    if (p == null || t == null || t == 0) return null;
    return p / (t * t);
  }

  double? get _cinturaVal {
    final v = double.tryParse(_cintura.text.replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return v;
  }

  double? get _caderaVal {
    final v = double.tryParse(_cadera.text.replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return v;
  }

  double? get _iccVal {
    final c = _cinturaVal, ca = _caderaVal;
    if (c == null || ca == null || ca == 0) return null;
    return c / ca;
  }

  // ====== Guardar nueva nota ======
  Future<void> _guardarNota() async {
    final m = _mat.text.trim();
    final dep = (_deptChoice == 'Otra…'
        ? _depto.text.trim()
        : (_deptChoice ?? '')).trim();
    final t = _tratante.text.trim();
    final dx = _diagnostico.text.trim();
    final tc = _tipoConsulta?.trim() ?? '';
    final c = _cuerpo.text.trim();

    final missing = <String>[];
    if (m.isEmpty) missing.add('Matrícula');
    if (dep.isEmpty) missing.add('Departamento / Área');
    if (t.isEmpty) missing.add('Tratante');

    final requiereDx = !(dep == 'Atención estudiantil' || _deptChoice == 'Otra…');
    if (requiereDx && dx.isEmpty) missing.add('Diagnóstico');

    if (tc.isEmpty) missing.add('Consulta (Primera/Subsecuente)');
    if (c.isEmpty) missing.add('Cuerpo de la nota');

    if (missing.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Completa los campos obligatorios'),
          content: Text('Faltan: ${missing.join(', ')}'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    try {
      final rutasAdj = await _guardarAdjuntosLocal(m);

      final buffer = StringBuffer();
      if (requiereDx) buffer.writeln('Diagnóstico: $dx');
      buffer.writeln('Consulta: $tc');

      if (dep == 'Consultorio de Nutrición') {
        final imcStr = _imcVal == null ? '—' : _imcVal!.toStringAsFixed(2);
        final iccStr = _iccVal == null ? '—' : _iccVal!.toStringAsFixed(2);
        buffer.writeln('NUTRICIÓN:');
        buffer.writeln('• Peso (kg): ${_peso.text.trim().isEmpty ? '—' : _peso.text.trim()}');
        buffer.writeln('• Talla (m): ${_talla.text.trim().isEmpty ? '—' : _talla.text.trim()}');
        buffer.writeln('• IMC: $imcStr');
        buffer.writeln('• Cintura (cm): ${_cintura.text.trim().isEmpty ? '—' : _cintura.text.trim()}');
        buffer.writeln('• Cadera (cm): ${_cadera.text.trim().isEmpty ? '—' : _cadera.text.trim()}');
        buffer.writeln('• Índice Cintura/Cadera: $iccStr');
      }

      buffer.writeln();
      buffer.writeln(c);

      if (rutasAdj.isNotEmpty) {
        buffer.writeln('\nAdjuntos:');
        for (final r in rutasAdj) {
          buffer.writeln('- $r');
        }
      }
      final cuerpoFinal = buffer.toString();

      final comp = DB.NotesCompanion.insert(
        matricula: m,
        departamento: dep.isEmpty ? 'Nota' : dep,
        cuerpo: cuerpoFinal,
        tratante: Value(t),
        createdAt: Value(DateTime.now()),
      );

      final rowId = await widget.db.insertNote(comp);
      // ignore: avoid_print
      print('✅ Nota insertada rowId=$rowId para matrícula=$m depto=$dep');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota guardada localmente ✓')),
      );

      if (_deptChoice == 'Otra…') _depto.clear();
      _tratante.clear();
      _cuerpo.clear();
      _diagnostico.clear();
      _tipoConsulta = null;
      _adjuntos.clear();

      _peso.clear();
      _talla.clear();
      _cintura.clear();
      _cadera.clear();

      setState(() {});
      await _buscar();
    } catch (e, st) {
      // ignore: avoid_print
      print('❌ Error al guardar nota: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar nota: $e')),
      );
    }
  }

  // ========== AUTORIZACIÓN SUPERVISOR ==========
  Future<bool> _askSupervisorPass() async {
    final ctrl = TextEditingController();
    bool ok = false;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Autorización de supervisor'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Clave',
            helperText: 'Ingrese la clave de supervisor para editar',
          ),
          onSubmitted: (_) => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim() == kSupervisorKey) {
                ok = true;
              }
              Navigator.of(context).pop();
            },
            child: const Text('Validar'),
          ),
        ],
      ),
    );
    return ok;
  }

  // ========== EDITAR NOTA LOCAL ==========
  Future<void> _editLocalNote(DB.Note n) async {
    final allowed = await _askSupervisorPass();
    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clave incorrecta o cancelado.')),
      );
      return;
    }

    final depCtrl = TextEditingController(text: n.departamento);
    final tratCtrl = TextEditingController(text: n.tratante ?? '');
    final cuerpoCtrl = TextEditingController(text: n.cuerpo);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 8, bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Editar nota (LOCAL)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: depCtrl, decoration: const InputDecoration(labelText: 'Departamento')),
            const SizedBox(height: 8),
            TextField(controller: tratCtrl, decoration: const InputDecoration(labelText: 'Tratante')),
            const SizedBox(height: 8),
            TextField(controller: cuerpoCtrl, minLines: 6, maxLines: 12, decoration: const InputDecoration(labelText: 'Cuerpo')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: ()=>Navigator.of(ctx).pop(), child: const Text('Cancelar'))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(
                  onPressed: () async {
                    // Actualizar en DB
                    await (widget.db.update(widget.db.notes)
                      ..where((t) => t.id.equals(n.id)))
                      .write(DB.NotesCompanion(
                        departamento: Value(depCtrl.text.trim()),
                        tratante: Value(tratCtrl.text.trim().isEmpty ? null : tratCtrl.text.trim()),
                        cuerpo: Value(cuerpoCtrl.text),
                      ));
                    if (mounted) Navigator.of(ctx).pop();
                    await _buscar();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nota local actualizada ✓')),
                    );
                  },
                  child: const Text('Guardar cambios'),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========== EDITAR NOTA NUBE (COUCHDB) ==========
  Future<void> _editCloudNote(Map<String, dynamic> n) async {
    final allowed = await _askSupervisorPass();
    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clave incorrecta o cancelado.')),
      );
      return;
    }

    final id = (n['_id'] ?? '').toString().trim();
    if (id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró _id de la nota en nube.')),
      );
      return;
    }

    // Obtener doc actual para leer _rev
    final basic = base64Encode(utf8.encode('$kCouchUser:$kCouchPass'));
    final getUri = Uri.parse('$kCouchBaseUrl/$kCouchDbName/$id');
    final getResp = await http.get(getUri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Basic $basic',
    });
    if (getResp.statusCode != 200) {
      // ignore: avoid_print
      print('GET $id fallo: ${getResp.statusCode} ${getResp.body}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo leer la nota en nube: ${getResp.statusCode}')),
      );
      return;
    }
    final doc = jsonDecode(getResp.body) as Map<String, dynamic>;
    final rev = (doc['_rev'] ?? '').toString();

    // Campos editables
    final depCtrl = TextEditingController(text: (doc['departamento'] ?? '').toString());
    final tratCtrl = TextEditingController(text: (doc['tratante'] ?? '').toString());
    final cuerpoCtrl = TextEditingController(text: (doc['cuerpo'] ?? '').toString());

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 8, bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Editar nota (NUBE)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: depCtrl, decoration: const InputDecoration(labelText: 'Departamento')),
            const SizedBox(height: 8),
            TextField(controller: tratCtrl, decoration: const InputDecoration(labelText: 'Tratante')),
            const SizedBox(height: 8),
            TextField(controller: cuerpoCtrl, minLines: 6, maxLines: 12, decoration: const InputDecoration(labelText: 'Cuerpo')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: ()=>Navigator.of(ctx).pop(), child: const Text('Cancelar'))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(
                  onPressed: () async {
                    final putUri = getUri;
                    final updated = {
                      '_id': id,
                      '_rev': rev,
                      // preservar campos clave
                      'matricula': (doc['matricula'] ?? ''),
                      'createdAt': (doc['createdAt'] ?? ''),
                      // editables
                      'departamento': depCtrl.text.trim(),
                      'tratante': tratCtrl.text.trim().isEmpty ? null : tratCtrl.text.trim(),
                      'cuerpo': cuerpoCtrl.text,
                    };
                    final putResp = await http.put(
                      putUri,
                      headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'Authorization': 'Basic $basic',
                      },
                      body: jsonEncode(updated),
                    );
                    if (putResp.statusCode != 201 && putResp.statusCode != 202) {
                      // ignore: avoid_print
                      print('PUT $id fallo: ${putResp.statusCode} ${putResp.body}');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al actualizar en nube: ${putResp.statusCode}')),
                        );
                      }
                      return;
                    }
                    if (mounted) Navigator.of(ctx).pop();
                    await _buscar();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nota en nube actualizada ✓')),
                    );
                  },
                  child: const Text('Guardar cambios'),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========== CREADOR DE CITAS ==========
  Future<void> _openCitaCreator() async {
    if (_mat.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero escribe y busca una matrícula.')),
      );
      return;
    }

    final _citaDepto = TextEditingController(
        text: _deptChoice == 'Otra…'
            ? (_depto.text.trim())
            : (_deptChoice ?? ''));
    final _citaMotivo = TextEditingController();
    final _citaLugar = TextEditingController(text: 'CRES');
    String? _modalidad = 'Presencial';
    String? _tratanteCita =
        _tratante.text.trim().isEmpty ? null : _tratante.text.trim();
    DateTime? _fecha = DateTime.now();
    TimeOfDay _hora = const TimeOfDay(hour: 9, minute: 0);
    Duration _dur = const Duration(minutes: 30);

    Future<void> pickFecha() async {
      final now = DateTime.now();
      final res = await showDatePicker(
        context: context,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
        initialDate: _fecha ?? now,
      );
      if (res != null) _fecha = res;
    }

    Future<void> pickHora() async {
      final res = await showTimePicker(
        context: context,
        initialTime: _hora,
        helpText: 'Selecciona la hora',
      );
      if (res != null) _hora = res;
    }

    Future<File?> _writeIcsFile({
      required DateTime startLocal,
      required Duration dur,
      required String summary,
      required String description,
      String? location,
    }) async {
      try {
        final endLocal = startLocal.add(dur);
        String fmt(DateTime dt) {
          final u = dt.toUtc();
          String two(int n) => n.toString().padLeft(2, '0');
          return '${u.year}${two(u.month)}${two(u.day)}T${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
        }

        final uid = 'cita-${DateTime.now().microsecondsSinceEpoch}@cres-carnets';
        final ics = '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//CRES//Carnets//ES
CALSCALE:GREGORIAN
METHOD:PUBLISH
BEGIN:VEVENT
UID:$uid
DTSTAMP:${fmt(DateTime.now())}
DTSTART:${fmt(startLocal)}
DTEND:${fmt(endLocal)}
SUMMARY:${summary.replaceAll('\n', ' ')}
DESCRIPTION:${description.replaceAll('\n', '\\n')}
${location != null && location.trim().isNotEmpty ? 'LOCATION:${location.replaceAll('\n', ' ')}' : ''}
END:VEVENT
END:VCALENDAR
''';

        final dir = await getApplicationSupportDirectory();
        final file = File(
            p.join(dir.path, 'cita_${DateTime.now().millisecondsSinceEpoch}.ics'));
        await file.writeAsString(ics);
        return file;
      } catch (_) {
        return null;
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_available_outlined),
                  const SizedBox(width: 8),
                  const Text('Crear cita',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      await pickFecha();
                      await pickHora();
                      (ctx as Element).markNeedsBuild();
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('Fecha y hora'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _citaDepto,
                      decoration: const InputDecoration(
                        labelText: 'Servicio / Departamento',
                        hintText: 'Ej. Consultorio médico',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _modalidad,
                      items: const [
                        DropdownMenuItem(
                            value: 'Presencial', child: Text('Presencial')),
                        DropdownMenuItem(value: 'Virtual', child: Text('Virtual')),
                      ],
                      decoration: const InputDecoration(labelText: 'Modalidad'),
                      onChanged: (v) => _modalidad = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _citaMotivo,
                decoration: const InputDecoration(labelText: 'Motivo de consulta'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _citaLugar,
                      decoration:
                          const InputDecoration(labelText: 'Lugar (opcional)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: _tratanteCita ?? ''),
                      decoration:
                          const InputDecoration(labelText: 'Tratante (opcional)'),
                      onChanged: (v) =>
                          _tratanteCita = v.trim().isEmpty ? null : v.trim(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: Text(
                          'Fecha: ${DateFormat('yyyy-MM-dd').format(_fecha!)}')),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Hora: ${_hora.format(ctx)}')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _dur.inMinutes,
                      items: const [15, 30, 45, 60]
                          .map((m) =>
                              DropdownMenuItem(value: m, child: Text('$m min')))
                          .toList(),
                      decoration: const InputDecoration(labelText: 'Duración'),
                      onChanged: (v) {
                        if (v != null) _dur = Duration(minutes: v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  final dep = _citaDepto.text.trim();
                  final mot = _citaMotivo.text.trim();
                  if (dep.isEmpty || _fecha == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Servicio y fecha/hora son obligatorios.')),
                    );
                    return;
                  }

                  final startLocal = DateTime(
                    _fecha!.year,
                    _fecha!.month,
                    _fecha!.day,
                    _hora.hour,
                    _hora.minute,
                  );

                  final buf = StringBuffer()
                    ..writeln('CITA:')
                    ..writeln('• Modalidad: ${_modalidad ?? 'Presencial'}')
                    ..writeln(
                        '• Fecha: ${DateFormat('yyyy-MM-dd – HH:mm').format(startLocal)}')
                    ..writeln('• Duración: ${_dur.inMinutes} min')
                    ..writeln(
                        '• Lugar: ${_citaLugar.text.trim().isEmpty ? '—' : _citaLugar.text.trim()}')
                    ..writeln('• Motivo: ${mot.isEmpty ? '—' : mot}')
                    ..writeln('• Tratante: ${_tratanteCita ?? '—'}');

                  final comp = DB.NotesCompanion.insert(
                    matricula: _mat.text.trim(),
                    departamento: dep.isEmpty ? 'Cita' : dep,
                    cuerpo: buf.toString(),
                    tratante: Value(_tratanteCita),
                    createdAt: Value(DateTime.now()),
                  );
                  await widget.db.insertNote(comp);

                  final icsFile = await _writeIcsFile(
                    startLocal: startLocal,
                    dur: _dur,
                    summary: '$dep — Cita',
                    description:
                        'Motivo: $mot\nPaciente: ${_expedienteCloud?['nombreCompleto'] ?? _expedienteLocal?.nombreCompleto ?? _mat.text}',
                    location: _citaLugar.text.trim(),
                  );

                  if (mounted) Navigator.of(ctx).pop();
                  await _buscar();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Cita creada y guardada como nota ✓')),
                  );

                  if (icsFile != null) {
                    if (!mounted) return;
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Evento de calendario',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text(
                                '¿Deseas abrir el archivo .ics para añadirlo a tu calendario?'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(Icons.close),
                                    label: const Text('Ahora no'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      await OpenFilex.open(icsFile.path);
                                    },
                                    icon: const Icon(Icons.event),
                                    label: const Text('Abrir .ics'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Guardar cita'),
              ),
              const SizedBox(height: 8),
              Text(
                'Consejo: las citas se guardan como notas (no cambian el esquema) y puedes exportar .ics para tu calendario.',
                style:
                    TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(.7)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===================== PDF/PRINT =====================
  Future<Uint8List> _buildNotePdf({
    required String title, // Departamento
    required String matricula,
    required String? tratante,
    required String createdAtStr,
    required String cuerpo,
    String? diagnostico,
    String? tipoConsulta,
    List<String>? adjuntos,
  }) async {
    final doc = pw.Document();

    pw.Widget rowKV(String k, String v) => pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 120,
              child:
                  pw.Text(k, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Expanded(child: pw.Text(v)),
          ],
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.copyWith(
          marginLeft: 36,
          marginRight: 36,
          marginTop: 36,
          marginBottom: 36,
        ),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('CRES Carnets — Nota clínica',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(title),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          rowKV('Matrícula', matricula),
          rowKV('Tratante', tratante ?? '—'),
          rowKV('Fecha', createdAtStr),
          if (diagnostico != null && diagnostico.trim().isNotEmpty)
            rowKV('Diagnóstico', diagnostico.trim()),
          if (tipoConsulta != null && tipoConsulta.trim().isNotEmpty)
            rowKV('Consulta', tipoConsulta.trim()),
          pw.SizedBox(height: 12),
          pw.Text('Cuerpo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(cuerpo),
          if (adjuntos != null && adjuntos.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Adjuntos',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: adjuntos.map((a) => pw.Bullet(text: a)).toList(),
            ),
          ],
          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.Text('Generado por CRES Carnets',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ],
      ),
    );

    return doc.save();
  }

  Map<String, String?> _extractDxConsulta(String cuerpo) {
    String? dx;
    String? tc;
    final lines = cuerpo.split('\n');
    if (lines.isNotEmpty &&
        lines[0].toLowerCase().startsWith('diagnóstico:')) {
      dx = lines[0].substring('diagnóstico:'.length).trim();
    }
    if (lines.length > 1 && lines[1].toLowerCase().startsWith('consulta:')) {
      tc = lines[1].substring('consulta:'.length).trim();
    }
    return {'dx': dx, 'tc': tc};
  }

  List<String> _extractAdjuntos(String cuerpo) {
    final out = <String>[];
    final idx = cuerpo.indexOf('\nAdjuntos:');
    if (idx == -1) return out;
    final tail = cuerpo.substring(idx).split('\n');
    for (final line in tail) {
      if (line.trim().startsWith('- ')) {
        out.add(line.trim().substring(2));
      }
    }
    return out;
  }

  Future<void> _printPdf(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }

  Future<void> _sharePdf(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  Future<void> _exportCloudNote(Map<String, dynamic> n) async {
    final dep = (n['departamento'] ?? '-') as String;
    final cuerpo = (n['cuerpo'] ?? '') as String;
    final trat = (n['tratante'] ?? '') as String?;
    final fecha = (n['createdAt'] ?? '') as String;
    final mat = _mat.text.trim();

    final ex = _extractDxConsulta(cuerpo);
    final atts = _extractAdjuntos(cuerpo);

    final pdfBytes = await _buildNotePdf(
      title: dep,
      matricula: mat,
      tratante: trat,
      createdAtStr: fecha,
      cuerpo: cuerpo,
      diagnostico: ex['dx'],
      tipoConsulta: ex['tc'],
      adjuntos: atts,
    );

    await _showPdfActions(pdfBytes, 'nota_${mat}_$dep.pdf');
  }

  Future<void> _exportLocalNote(DB.Note n) async {
    final dep = n.departamento;
    final cuerpo = n.cuerpo;
    final trat = n.tratante;
    final fecha = _fmtDate(n.createdAt);
    final mat = _mat.text.trim();

    final ex = _extractDxConsulta(cuerpo);
    final atts = _extractAdjuntos(cuerpo);

    final pdfBytes = await _buildNotePdf(
      title: dep,
      matricula: mat,
      tratante: trat,
      createdAtStr: fecha,
      cuerpo: cuerpo,
      diagnostico: ex['dx'],
      tipoConsulta: ex['tc'],
      adjuntos: atts,
    );

    await _showPdfActions(pdfBytes, 'nota_${mat}_$dep.pdf');
  }

  Future<void> _showPdfActions(Uint8List pdfBytes, String fileName) async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Exportar / Imprimir',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _printPdf(pdfBytes);
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimir'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _sharePdf(pdfBytes, fileName);
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Exportar PDF'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Acordeones ----------
  Widget _buildCloudNotesAccordion() {
    final cs = Theme.of(context).colorScheme;

    if (_notasCloud.isEmpty) {
      return Text(
        'Sin notas en nube para esta matrícula.',
        style: TextStyle(color: cs.onSurface.withOpacity(.75)),
      );
    }

    final total = _notasCloud.length;
    final slice =
        _showAllCloud ? _notasCloud : _notasCloud.take(_limit).toList();

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _showAllCloud = !_showAllCloud),
            icon:
                Icon(_showAllCloud ? Icons.filter_alt_off : Icons.expand_more),
            label: Text(
              _showAllCloud ? 'Ver últimas $_limit' : 'Ver todas ($total)',
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: slice.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final n = slice[i];
            final dep = (n['departamento'] ?? '-').toString();
            final cuerpo = (n['cuerpo'] ?? '').toString();
            final trat = (n['tratante'] ?? '').toString();
            final fecha = (n['createdAt'] ?? '').toString();

            return ExpansionTile(
              leading: const Icon(Icons.cloud_done),
              title: Text(dep,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Row(
                children: [
                  if (trat.isNotEmpty) Text(trat),
                  if (trat.isNotEmpty && fecha.isNotEmpty)
                    const SizedBox(width: 8),
                  if (fecha.isNotEmpty)
                    Text(
                      fecha,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(.6),
                      ),
                    ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: SelectableText(cuerpo),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _exportCloudNote(n),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Exportar / Imprimir'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _editCloudNote(n),
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLocalNotesAccordion() {
    final cs = Theme.of(context).colorScheme;

    if (_notasLocal.isEmpty) {
      return Text(
        'Sin notas locales para esta matrícula.',
        style: TextStyle(color: cs.onSurface.withOpacity(.75)),
      );
    }

    final total = _notasLocal.length;
    final slice =
        _showAllLocal ? _notasLocal : _notasLocal.take(_limit).toList();

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _showAllLocal = !_showAllLocal),
            icon:
                Icon(_showAllLocal ? Icons.filter_alt_off : Icons.expand_more),
            label: Text(
              _showAllLocal ? 'Ver últimas $_limit' : 'Ver todas ($total)',
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: slice.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final n = slice[i];
            final dep = n.departamento;
            final cuerpo = n.cuerpo;
            final trat = n.tratante ?? '';
            final fecha = _fmtDate(n.createdAt);

            return ExpansionTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(dep,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Row(
                children: [
                  if (trat.isNotEmpty) Text(trat),
                  if (trat.isNotEmpty && fecha.isNotEmpty)
                    const SizedBox(width: 8),
                  if (fecha.isNotEmpty)
                    Text(
                      fecha,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(.6),
                      ),
                    ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: SelectableText(cuerpo),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _exportLocalNote(n),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Exportar / Imprimir'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _editLocalNote(n),
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ---------- Compositor de “Nueva nota” ----------
  Widget _highlightedNoteComposer(ColorScheme cs) {
    final isNutricion = _deptChoice == 'Consultorio de Nutrición';
    final isOtra = _deptChoice == 'Otra…';
    final requiereDx =
        !((_deptChoice == 'Otra…') || (_deptChoice == 'Atención estudiantil'));

    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(.18),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: cs.primary.withOpacity(.45), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note_outlined, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Nueva nota (se guarda local; luego sincronizas)',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: const Text(
                    'Obligatoria*',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Departamento / Área
                DropdownButtonFormField<String>(
                  value: _deptChoice,
                  items: _deptOpciones
                      .map((e) =>
                          DropdownMenuItem<String>(value: e, child: Text(e)))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Departamento / Área *',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() {
                    _deptChoice = v;
                  }),
                ),
                if (isOtra) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _depto,
                    decoration: const InputDecoration(
                      labelText: 'Especifica otra área *',
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                // Tratante
                TextField(
                  controller: _tratante,
                  decoration: const InputDecoration(labelText: 'Tratante *'),
                ),
                const SizedBox(height: 8),

                // Diagnóstico (condicional)
                if (requiereDx) ...[
                  TextField(
                    controller: _diagnostico,
                    decoration:
                        const InputDecoration(labelText: 'Diagnóstico *'),
                  ),
                  const SizedBox(height: 8),
                ],

                // Tipo de consulta
                DropdownButtonFormField<String>(
                  value: _tipoConsulta,
                  items: const [
                    DropdownMenuItem(
                        value: 'Primera vez', child: Text('Primera vez')),
                    DropdownMenuItem(
                        value: 'Subsecuente', child: Text('Subsecuente')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Consulta *',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _tipoConsulta = v),
                ),
                const SizedBox(height: 8),

                // Nutrición: bloque extra
                if (isNutricion) ...[
                  const Divider(height: 24),
                  Text('Datos antropométricos (Nutrición)',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(.9))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _peso,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Peso (kg)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _talla,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Talla (m)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cintura,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Cintura abdominal (cm)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _cadera,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Cadera (cm)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (_) {
                      final imc = _imcVal == null
                          ? '—'
                          : _imcVal!.toStringAsFixed(2);
                      final icc = _iccVal == null
                          ? '—'
                          : _iccVal!.toStringAsFixed(2);
                      return Text('IMC: $imc    •    Índice Cintura/Cadera: $icc',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withOpacity(.9)));
                    },
                  ),
                  const Divider(height: 24),
                ],

                // Cuerpo de la nota
                TextField(
                  controller: _cuerpo,
                  minLines: 4,
                  maxLines: 6,
                  decoration:
                      const InputDecoration(labelText: 'Cuerpo de la nota *'),
                ),
                const SizedBox(height: 12),

                // Adjuntar (OPCIONAL) + Agendar cita
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _pickAdjuntos,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Adjuntar archivo(s) (opcional)'),
                    ),
                    const SizedBox(width: 12),
                    if (_adjuntos.isNotEmpty)
                      Text('${_adjuntos.length} adjunto(s) seleccionado(s)'),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _openCitaCreator,
                      icon: const Icon(Icons.event_available),
                      label: const Text('Agendar cita'),
                    ),
                  ],
                ),

                if (_adjuntos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _adjuntos.map((f) {
                      return Chip(
                        label: Text(
                          f.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onDeleted: () {
                          setState(() {
                            _adjuntos.remove(f);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _guardarNota,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar nota'),
                ),
                const SizedBox(height: 4),
                Text(
                  'Campos obligatorios marcados con *. Los adjuntos son opcionales.',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Tarjetas superiores ----------
  Widget _cardNube(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      icon: Icons.cloud_outlined,
      title: 'Expediente y notas (NUBE)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_atencionIntegral)
            Align(
              alignment: Alignment.topRight,
              child: Tooltip(
                message: 'Atención integral: 2 o más servicios activos',
                child: Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_expedienteCloud == null)
            Text(
              'No hay carnet en la nube para esta matrícula.',
              style: TextStyle(color: cs.onSurface.withOpacity(.75)),
            )
          else ...[
            _line('Nombre', _expedienteCloud!['nombreCompleto']),
            _line('Correo', _expedienteCloud!['correo']),
            _line('Edad', _expedienteCloud!['edad']),
            _line('Sexo', _expedienteCloud!['sexo']),
            _line('Programa', _expedienteCloud!['programa']),
            _line('Categoría', _expedienteCloud!['categoria']),
            _line('Alergias', _expedienteCloud!['alergias']),
            _line('Tipo de sangre', _expedienteCloud!['tipoSangre']),
            _line('Enfermedad', _expedienteCloud!['enfermedadCronica']),
            _line('Discapacidad', _expedienteCloud!['discapacidad']),
            _line('Tipo de discapacidad', _expedienteCloud!['tipoDiscapacidad']),
            _line('Unidad médica', _expedienteCloud!['unidadMedica']),
            _line('Núm. de afiliación', _expedienteCloud!['numeroAfiliacion']),
            _line('Uso Seguro Universitario',
                _expedienteCloud!['usoSeguroUniversitario']),
            _line('Donante', _expedienteCloud!['donante']),
            _line('Teléfono de emergencia',
                _expedienteCloud!['emergenciaTelefono']),
            _line('Contacto de emergencia',
                _expedienteCloud!['emergenciaContacto']),
            const SizedBox(height: 6),
            _line('Actualizado', _expedienteCloud!['timestamp']),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.notes_outlined, size: 18),
              const SizedBox(width: 6),
              Text(
                'Notas en nube — ${_notasCloud.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildCloudNotesAccordion(),
        ],
      ),
    );
  }

  Widget _cardLocal(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      icon: Icons.storage_outlined,
      title: 'Respaldo LOCAL',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_atencionIntegral)
            Align(
              alignment: Alignment.topRight,
              child: Tooltip(
                message: 'Atención integral: 2 o más servicios activos',
                child: Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

          if (_expedienteLocal == null) ...[
            Text(
              'No hay carnet local para esta matrícula.',
              style: TextStyle(color: cs.onSurface.withOpacity(.75)),
            ),
          ] else ...[
            Text('Nombre: ${_expedienteLocal!.nombreCompleto}'),
            Text('Correo: ${_expedienteLocal!.correo}'),
            Text('Edad: ${_expedienteLocal!.edad ?? '-'}'),
            Text('Sexo: ${_expedienteLocal!.sexo ?? '-'}'),
            Text('Programa: ${_expedienteLocal!.programa ?? '-'}'),
            Text('Categoría: ${_expedienteLocal!.categoria ?? '-'}'),
            Text('Alergias: ${_expedienteLocal!.alergias ?? '-'}'),
            Text('Tipo de sangre: ${_expedienteLocal!.tipoSangre ?? '-'}'),
            Text('Enfermedad: ${_expedienteLocal!.enfermedadCronica ?? '-'}'),
            const SizedBox(height: 6),
            Text('Actualizado: ${_fmtDate(_expedienteLocal!.timestamp)}'),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.notes_outlined, size: 18),
              const SizedBox(width: 6),
              Text(
                'Notas locales — ${_notasLocal.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildLocalNotesAccordion(),
        ],
      ),
    );
  }

  // ---------- Sincronizar ahora ----------
  Future<void> _syncNow() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sincronizando con Cloudant…')),
    );
    try {
      await syncToCloudant(widget.db);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sincronizado ✓')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de sincronización: $e')),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: uagroAppBar('CRES Carnets', 'Agregar nota clínica'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _syncNow,
        icon: const Icon(Icons.sync),
        label: const Text('Sincronizar ahora'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Encabezado + indicador integral
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: BrandHeader(
                    title: 'CRES Carnets',
                    subtitle: 'Expediente de salud universitario',
                  ),
                ),
                if (_atencionIntegral)
                  Tooltip(
                    message: 'Atención integral detectada (≥2 servicios)',
                    child: Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(.35),
                            blurRadius: 6,
                          )
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Buscar por matrícula
            safe(
              () => SectionCard(
                icon: Icons.search,
                title: 'Buscar por matrícula',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _mat,
                            decoration: const InputDecoration(labelText: 'Matrícula'),
                            onSubmitted: (_) => _buscar(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 40),
                          ),
                          onPressed: _cargando ? null : _buscar,
                          icon: const Icon(Icons.search),
                          label: const Text('Buscar'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            if (_mat.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Escribe una matrícula')),
                              );
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FormScreen(
                                  db: widget.db,
                                  matriculaInicial: _mat.text.trim(),
                                  lockMatricula: true,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_note_outlined),
                          label: const Text('Editar carnet'),
                        ),
                      ],
                    ),
                    if (_cargando) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: cs.error)),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            _cardNube(context),
            const SizedBox(height: 12),

            // NUEVA NOTA — resaltada
            _highlightedNoteComposer(cs),

            const SizedBox(height: 12),
            _cardLocal(context),
          ],
        ),
      ),
    );
  }
}
