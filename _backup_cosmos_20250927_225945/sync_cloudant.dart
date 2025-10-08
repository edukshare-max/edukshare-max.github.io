// lib/data/sync_cloudant.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/db.dart' as DB;

/// ====== CONFIGURACIÓN COUCHDB (ajusta a tu servidor) ======
const String kCouchBaseUrl = 'http://100.73.52.97:5984'; 
const String kCouchDbName  = 'cres_salud';
const String kCouchUser    = 'admin';
const String kCouchPass    = 'supersegura';
const Duration _timeout    = Duration(seconds: 15);

Map<String, String> get _headers => {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Authorization': 'Basic ${base64Encode(utf8.encode('$kCouchUser:$kCouchPass'))}',
};

Uri _u(String path) => Uri.parse('$kCouchBaseUrl/$path');

void _log(String m) {
  // ignore: avoid_print
  print('[CouchSync] $m');
}

/// Obtiene un documento por _id (para leer _rev cuando hay conflicto).
Future<Map<String, dynamic>?> _getDoc(String id) async {
  final uri = _u('$kCouchDbName/${Uri.encodeComponent(id)}');
  final r = await http.get(uri, headers: _headers).timeout(_timeout);
  if (r.statusCode == 200) {
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
  if (r.statusCode == 404) return null;
  _log('GET $id FAILED ${r.statusCode}: ${r.body}');
  throw Exception('GET $id -> ${r.statusCode}: ${r.body}');
}

/// Sube (upsert) un documento a CouchDB por _id.
/// - Si no existe: PUT directo.
/// - Si existe (409): GET para obtener _rev y reintenta el PUT con _rev.
Future<void> _putDocUpsert(String id, Map<String, dynamic> doc) async {
  final uri = _u('$kCouchDbName/${Uri.encodeComponent(id)}');

  Future<http.Response> doPut(Map<String, dynamic> body) {
    return http
        .put(uri, headers: _headers, body: jsonEncode(body))
        .timeout(_timeout);
  }

  // Intento 1: PUT sin _rev
  var r = await doPut(doc);
  if (r.statusCode == 201 || r.statusCode == 202) return;

  // Si hay conflicto, obtenemos _rev y reintentamos con _rev
  if (r.statusCode == 409) {
    final existing = await _getDoc(id);
    if (existing != null && existing['_rev'] is String) {
      final withRev = Map<String, dynamic>.from(doc)..['_rev'] = existing['_rev'];
      r = await doPut(withRev);
      if (r.statusCode == 201 || r.statusCode == 202) return;
    }
  }

  _log('PUT $id FAILED ${r.statusCode}: ${r.body}');
  throw Exception('PUT $id -> ${r.statusCode}: ${r.body}');
}

/// Sincroniza TODOS los carnets y notas locales hacia CouchDB.
/// Prototipo sencillo: re-sube todo cada vez con _id determinístico
/// (al existir, se hace upsert usando _rev).
Future<void> syncToCloudant(DB.AppDatabase db) async {
  _log('Sincronizando…');

  // 1) Carnets
  final carnets = await db.select(db.healthRecords).get();
  for (final c in carnets) {
    final ts = (c.timestamp ?? DateTime.now()).toIso8601String();
    final id = 'carnet:${c.matricula}:$ts';

    final doc = <String, dynamic>{
      '_id': id,
      'timestamp': ts,
      'matricula': c.matricula,
      'nombreCompleto': c.nombreCompleto,
      'correo': c.correo,
      'edad': c.edad,
      'sexo': c.sexo,
      'categoria': c.categoria,
      'programa': c.programa,
      'discapacidad': c.discapacidad,
      'tipoDiscapacidad': c.tipoDiscapacidad,
      'alergias': c.alergias,
      'tipoSangre': c.tipoSangre,
      'enfermedadCronica': c.enfermedadCronica,
      'unidadMedica': c.unidadMedica,
      'numeroAfiliacion': c.numeroAfiliacion,
      'usoSeguroUniversitario': c.usoSeguroUniversitario,
      'donante': c.donante,
      'emergenciaTelefono': c.emergenciaTelefono,
      'emergenciaContacto': c.emergenciaContacto,
      'expedienteNotas': c.expedienteNotas,
      'expedienteAdjuntos': c.expedienteAdjuntos,
    };

    await _putDocUpsert(id, doc);
  }

  // 2) Notas
  final notas = await db.select(db.notes).get();
  for (final n in notas) {
    final ts = (n.createdAt ?? DateTime.now()).toIso8601String();
    final id = 'nota:${n.matricula}:$ts';

    final doc = <String, dynamic>{
      '_id': id,
      'matricula': n.matricula,
      'departamento': n.departamento,
      'cuerpo': n.cuerpo,
      'tratante': n.tratante,
      'createdAt': ts,
    };

    await _putDocUpsert(id, doc);
  }

  _log('Sincronización OK ✓');
}
