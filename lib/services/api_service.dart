// 🌐 SERVICIO API SASU - OPTIMIZADO Y ROBUSTO
// Con reintentos automáticos, timeouts inteligentes y manejo de errores profesional

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carnet_digital_uagro/models/carnet_model.dart';
import 'package:carnet_digital_uagro/models/cita_model.dart';
import 'package:carnet_digital_uagro/models/promocion_salud_model.dart';

class ApiService {
  // 🌐 BACKEND PRODUCCIÓN EN RENDER
  static const String baseUrl = 'https://carnet-alumnos-nodes.onrender.com';
  // static const String baseUrl = 'http://localhost:3000'; // Para pruebas locales
  
  // ⚙️ CONFIGURACIÓN DE REINTENTOS Y TIMEOUTS
  static const int maxRetries = 3;
  static const Duration shortTimeout = Duration(seconds: 8);  // Health check
  static const Duration normalTimeout = Duration(seconds: 20); // Operaciones normales
  static const Duration longTimeout = Duration(seconds: 35);   // Login con cold start
  
  // 🔄 MÉTODO AUXILIAR: REINTENTO CON BACKOFF EXPONENCIAL
  static Future<T?> _retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxAttempts = maxRetries,
    String operationName = 'operación',
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        print('🔄 Intento $attempt/$maxAttempts para $operationName');
        final result = await operation();
        print('✅ $operationName exitosa en intento $attempt');
        return result;
      } catch (e) {
        final isLastAttempt = attempt == maxAttempts;
        
        if (isLastAttempt) {
          print('❌ $operationName falló después de $maxAttempts intentos: $e');
          rethrow;
        }
        
        // Backoff exponencial: 2s, 4s, 8s...
        final waitTime = Duration(seconds: 2 * attempt);
        print('⏳ Reintentando en ${waitTime.inSeconds}s... (Error: ${e.toString().substring(0, 50)})');
        await Future.delayed(waitTime);
      }
    }
    return null;
  }
  
  // 🏥 HEALTH CHECK: Verificar si el backend está activo
  static Future<Map<String, dynamic>> checkBackendHealth() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      print('🏥 Verificando salud del backend: $url');
      
      final startTime = DateTime.now();
      final response = await http.get(url).timeout(shortTimeout);
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      final isHealthy = response.statusCode == 200;
      
      return {
        'healthy': isHealthy,
        'statusCode': response.statusCode,
        'responseTime': responseTime,
        'message': isHealthy 
          ? '✅ Backend activo (${responseTime}ms)' 
          : '⚠️ Backend responde con error ${response.statusCode}',
      };
    } catch (e) {
      print('❌ Health check falló: $e');
      
      // Detectar tipo de error
      final isColdStart = e.toString().contains('TimeoutException');
      
      return {
        'healthy': false,
        'statusCode': 0,
        'responseTime': -1,
        'message': isColdStart 
          ? '❄️ Backend iniciando (cold start Render)...' 
          : '❌ Backend no disponible: $e',
        'coldStart': isColdStart,
      };
    }
  }
  
  // 🔑 LOGIN CON JWT - VERSIÓN ROBUSTA CON REINTENTOS
  static Future<Map<String, dynamic>?> login(String email, String matricula) async {
    return await _retryWithBackoff<Map<String, dynamic>>(
      () => _performLogin(email, matricula),
      operationName: 'login',
    );
  }
  
  // 🔐 IMPLEMENTACIÓN INTERNA DE LOGIN
  static Future<Map<String, dynamic>> _performLogin(String email, String matricula) async {
    final startTime = DateTime.now();
    
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      final body = {
        'correo': email,
        'matricula': matricula,
      };
      
      print('🔍 LOGIN REQUEST: $url');
      print('📧 Email: $email | 🎓 Matrícula: $matricula');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(
        longTimeout,
        onTimeout: () {
          throw Exception('TIMEOUT: El servidor tardó más de ${longTimeout.inSeconds}s en responder. Posible cold start de Render.');
        },
      );
      
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      print('📊 LOGIN RESPONSE: ${response.statusCode} (${responseTime}ms)');
      
      // Detectar si fue cold start (respuesta lenta)
      final wasColdStart = responseTime > 10000;
      if (wasColdStart) {
        print('❄️ Cold start detectado: ${responseTime}ms');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['token'] != null) {
          print('✅ Login exitoso');
          return {
            'success': true,
            'token': data['token'],
            'matricula': data['matricula'] ?? matricula,
            'responseTime': responseTime,
            'coldStart': wasColdStart,
          };
        } else {
          throw Exception('INVALID_RESPONSE: Respuesta del servidor sin token válido');
        }
      } else if (response.statusCode == 401) {
        // Credenciales incorrectas - NO reintentar
        throw Exception('CREDENTIALS_ERROR: ${response.body}');
      } else if (response.statusCode == 500) {
        // Error del servidor - SÍ reintentar
        throw Exception('SERVER_ERROR: Error interno del servidor (${response.statusCode})');
      } else {
        throw Exception('HTTP_ERROR: Status code ${response.statusCode}');
      }
      
    } catch (e) {
      final errorType = _classifyError(e);
      print('❌ LOGIN ERROR: $errorType - $e');
      
      // Si es error de credenciales, no reintentar
      if (errorType == 'CREDENTIALS_ERROR') {
        return {
          'success': false,
          'errorType': 'CREDENTIALS',
          'message': 'Credenciales incorrectas. Verifica tu email y matrícula.',
        };
      }
      
      // Para otros errores, propagar para que el retry maneje
      rethrow;
    }
  }
  
  // 🏷️ CLASIFICAR TIPO DE ERROR
  static String _classifyError(dynamic error) {
    final errorStr = error.toString();
    
    if (errorStr.contains('CREDENTIALS_ERROR')) return 'CREDENTIALS_ERROR';
    if (errorStr.contains('TIMEOUT')) return 'TIMEOUT_ERROR';
    if (errorStr.contains('SocketException') || errorStr.contains('NetworkException')) return 'NETWORK_ERROR';
    if (errorStr.contains('SERVER_ERROR')) return 'SERVER_ERROR';
    if (errorStr.contains('FormatException')) return 'PARSE_ERROR';
    
    return 'UNKNOWN_ERROR';
  }
  
  // 🎓 OBTENER DATOS DEL CARNET CON JWT
  static Future<CarnetModel?> getMyCarnet(String token) async {
    try {
      final url = Uri.parse('$baseUrl/me/carnet');
      
      print('🔍 GET CARNET REQUEST: $url');
      print('🔑 TOKEN: ${token.substring(0, 20)}...');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('📊 CARNET RESPONSE: ${response.statusCode}');
      print('📋 RESPONSE BODY: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return CarnetModel.fromJson(data['data']);
        }
      }
      
      return null;
    } catch (e) {
      print('❌ GET CARNET ERROR: $e');
      return null;
    }
  }
  
  // 🏥 OBTENER CITAS MÉDICAS - ENDPOINT REAL SASU
  static Future<List<CitaModel>> getCitas(String token) async {
    try {
      final url = Uri.parse('$baseUrl/me/citas'); // ✅ ENDPOINT CORRECTO
      
      print('🔍 GET CITAS REQUEST: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('📊 CITAS RESPONSE: ${response.statusCode}');
      print('📋 RESPONSE BODY: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> citasJson = data['data'];
          return citasJson.map((json) => CitaModel.fromJson(json)).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('❌ GET CITAS ERROR: $e');
      return [];
    }
  }

  // 🏥 OBTENER PROMOCIONES DE SALUD ACTIVAS - BACKEND REAL
  static Future<List<PromocionSaludModel>> getPromocionesSalud(String token, String matricula) async {
    try {
      // Endpoint del nuevo backend de promociones SASU
      final url = Uri.parse('$baseUrl/me/promociones');
      
      print('🔍 PROMOCIONES REQUEST: $url');
      print('🎓 MATRICULA: $matricula');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('📊 PROMOCIONES RESPONSE: ${response.statusCode}');
      print('📋 RESPONSE BODY: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Verificar formato de respuesta del backend
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> promocionesJson = responseData['data'];
          
          print('📦 ${promocionesJson.length} promociones recibidas del backend');
          
          // Convertir JSON a modelos
          final promociones = <PromocionSaludModel>[];
          
          for (var json in promocionesJson) {
            try {
              // Mapear formato del backend SASU al modelo existente
              final promocionData = {
                'id': json['id']?.toString() ?? '',
                'matricula': matricula,
                'link': json['link'] ?? '',
                'departamento': json['departamento'] ?? 'SASU',
                'categoria': json['categoria'] ?? 'General',
                'programa': json['titulo'] ?? json['programa'] ?? 'Sin título',
                'destinatario': 'Alumno',
                'autorizado': true,
                'createdAt': json['fecha_publicacion'] ?? json['created_at'] ?? DateTime.now().toIso8601String(),
                'createdBy': json['departamento'] ?? 'Sistema SASU',
                // Campos adicionales para compatibilidad
                'titulo': json['titulo'] ?? '',
                'descripcion': json['descripcion'] ?? '',
                'resumen': json['resumen'] ?? json['descripcion']?.substring(0, 150) ?? '',
                'imagen_url': json['imagen_url'],
                'fecha_inicio': json['fecha_inicio'],
                'fecha_fin': json['fecha_fin'],
                'destacado': json['destacado'] ?? false,
                'urgente': json['urgente'] ?? false,
                'prioridad': json['prioridad'] ?? 5,
                'es_especifica': json['matricula_target'] != null,
              };
              
              final promocion = PromocionSaludModel.fromJson(promocionData);
              promociones.add(promocion);
              
              print('   ✅ ${promocion.titulo} (${promocion.categoria})');
              
            } catch (e) {
              print('   ❌ Error parseando promoción: $e');
              print('   📄 JSON: $json');
            }
          }
          
          print('✅ PROMOCIONES FINALES: ${promociones.length}');
          return promociones;
          
        } else {
          print('❌ Formato de respuesta inválido: ${responseData}');
        }
        
      } else if (response.statusCode == 404) {
        print('❌ Endpoint de promociones no encontrado (404)');
        print('💡 Asegúrate de que el backend SASU está ejecutándose');
      } else if (response.statusCode == 401) {
        print('❌ No autorizado (401) - token inválido');
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
      }
      
      return [];
    } catch (e) {
      print('❌ GET PROMOCIONES ERROR: $e');
      return [];
    }
  }

  // � REGISTRAR CLICK EN PROMOCIÓN
  static Future<bool> registrarClickPromocion(String token, String promocionId) async {
    try {
      final url = Uri.parse('$baseUrl/me/promociones/$promocionId/click');
      
      print('🔍 REGISTRAR CLICK: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('📊 CLICK RESPONSE: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Click registrado: ${data['message']}');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ REGISTRAR CLICK ERROR: $e');
      return false;
    }
  }

  // 🗑️ MARCAR PROMOCIÓN COMO VISTA (DEPRECADO)
  static Future<bool> marcarPromocionVista(String token, String promocionId) async {
    // Este método está deprecado, usar registrarClickPromocion en su lugar
    return registrarClickPromocion(token, promocionId);
  }
}