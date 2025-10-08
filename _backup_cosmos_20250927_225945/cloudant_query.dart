// lib/data/cloudant_query.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Tomamos la configuración de CouchDB del sync
import 'sync_cloudant.dart'
    show kCouchBaseUrl, kCouchDbName, kCouchUser, kCouchPass;

/// Cliente de consultas para CouchDB (Mango / _find).
/// Sustituye al viejo cliente de IBM Cloudant IAM.
class CloudantQueries {
  // Log sencillo
  void _log(String msg) {
    // ignore: avoid_print
    print('[CouchQueries] $msg');
  }

  static const _httpTimeout = Duration(seconds: 15);

  Map<String, String> get _headers => {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$kCouchUser:$kCouchPass'))}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Uri _u(String path) => Uri.parse('$kCouchBaseUrl/$path');

  /// Obtiene el ÚLTIMO carnet en nube por matrícula (ordenamos en cliente).
  Future<Map<String, dynamic>?> fetchLatestPatient(String matricula) async {
final uri = Uri.parse('$kCouchBaseUrl/$kCouchDbName/_find'); // etc.

    final payload = {
      'selector': {
        'matricula': matricula.trim(),
      },
      'fields': [
        '_id',
        'timestamp',
        'matricula',
        'nombreCompleto',
        'correo',
        'edad',
        'sexo',
        'categoria',
        'programa',
        'discapacidad',
        'tipoDiscapacidad',
        'alergias',
        'tipoSangre',
        'enfermedadCronica',
        'unidadMedica',
        'numeroAfiliacion',
        'usoSeguroUniversitario',
        'donante',
        'emergenciaTelefono',
        'emergenciaContacto',
        'expedienteNotas',
        'expedienteAdjuntos',
      ],
      'limit': 200,
      // Si tuvieras índice por ["matricula","timestamp"], CouchDB lo usa automáticamente.
    };

    _log('POST $uri selector=${payload['selector']}');
    http.Response r;
    try {
      r = await http
          .post(uri, headers: _headers, body: jsonEncode(payload))
          .timeout(_httpTimeout);
    } on TimeoutException {
      _log('timeout carnet');
      throw Exception('Timeout consultando CouchDB (carnet)');
    } catch (e) {
      _log('error carnet: $e');
      rethrow;
    }

    _log('status carnet=${r.statusCode}');
    if (r.statusCode != 200) {
      _log('body carnet=${r.body}');
      throw Exception('CouchDB _find carnet ${r.statusCode}: ${r.body}');
    }

    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final docs = (data['docs'] as List).cast<Map<String, dynamic>>();
    _log('docs carnet=${docs.length}');
    if (docs.isEmpty) return null;

    // Ordenamos por timestamp DESC (string ISO-8601 compara bien)
    docs.sort((a, b) {
      final at = (a['timestamp'] ?? '') as String;
      final bt = (b['timestamp'] ?? '') as String;
      return bt.compareTo(at);
    });

    _log('first carnet id=${docs.first['_id']}');
    return docs.first;
  }

  /// Todas las notas en nube por matrícula (ordenamos en cliente).
  Future<List<Map<String, dynamic>>> fetchNotes(String matricula) async {
    final uri = _u('$kCouchDbName/_find');

    final payload = {
      'selector': {
        'matricula': matricula.trim(),
      },
      'fields': [
        '_id',
        'matricula',
        'departamento',
        'tratante',
        'cuerpo',
        'createdAt',
      ],
      'limit': 500,
      // Si tienes índice por ["matricula","createdAt"], se usará.
    };

    _log('POST $uri selector=${payload['selector']} (notas)');
    http.Response r;
    try {
      r = await http
          .post(uri, headers: _headers, body: jsonEncode(payload))
          .timeout(_httpTimeout);
    } on TimeoutException {
      _log('timeout notas');
      throw Exception('Timeout consultando CouchDB (notas)');
    } catch (e) {
      _log('error notas: $e');
      rethrow;
    }

    _log('status notas=${r.statusCode}');
    if (r.statusCode != 200) {
      _log('body notas=${r.body}');
      throw Exception('CouchDB _find notas ${r.statusCode}: ${r.body}');
    }

    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final docs = (data['docs'] as List).cast<Map<String, dynamic>>();
    _log('docs notas=${docs.length}');

    // Orden DESC por createdAt
    docs.sort((a, b) {
      final at = (a['createdAt'] ?? '') as String;
      final bt = (b['createdAt'] ?? '') as String;
      return bt.compareTo(at);
    });

    return docs;
  }

  /// (Opcional) Subir UNA nota directa (sin esperar "Sincronizar").
  Future<void> pushSingleNote({
    required String matricula,
    required String departamento,
    required String cuerpo,
    String? tratante,
    DateTime? createdAt,
  }) async {
    final ts = (createdAt ?? DateTime.now()).toIso8601String();
    final id = 'nota:$matricula:$ts';
    final uri = _u('$kCouchDbName/$id');

    final doc = {
      '_id': id,
      'matricula': matricula,
      'departamento': departamento,
      'cuerpo': cuerpo,
      'tratante': tratante,
      'createdAt': ts,
    };

    _log('PUT $uri (pushSingleNote)');
    http.Response r;
    try {
      r = await http
          .put(uri, headers: _headers, body: jsonEncode(doc))
          .timeout(_httpTimeout);
    } on TimeoutException {
      _log('timeout put nota');
      throw Exception('Timeout enviando nota a CouchDB');
    } catch (e) {
      _log('error put nota: $e');
      rethrow;
    }

    _log('status put=${r.statusCode}');
    if (r.statusCode != 201 && r.statusCode != 202) {
      _log('body put=${r.body}');
      throw Exception('CouchDB push nota ${r.statusCode}: ${r.body}');
    }
  }
}
