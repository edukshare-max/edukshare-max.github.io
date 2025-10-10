// 🌐 SERVICIO API SASU - OPTIMIZADO Y FUNCIONAL
// Basado en endpoints reales que funcionan

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carnet_digital_uagro/models/carnet_model.dart';
import 'package:carnet_digital_uagro/models/cita_model.dart';
import 'package:carnet_digital_uagro/models/promocion_salud_model.dart';

class ApiService {
  // � BACKEND PRODUCCIÓN EN RENDER
  static const String baseUrl = 'https://carnet-alumnos-nodes.onrender.com';
  // static const String baseUrl = 'http://localhost:3000'; // Para pruebas locales
  
  // 🔑 LOGIN CON JWT (TEMPORAL - Backend SASU aún no tiene /auth/login)
  static Future<Map<String, dynamic>?> login(String email, String matricula) async {
    try {
      // TEMPORAL: Verificar si el backend está disponible
      final healthUrl = Uri.parse('$baseUrl/health');
      
      print('🔍 VERIFICANDO BACKEND: $healthUrl');
      
      try {
        final healthResponse = await http.get(healthUrl).timeout(
          const Duration(seconds: 5),
        );
        
        if (healthResponse.statusCode == 200) {
          print('✅ Backend SASU disponible');
          
          // TEMPORAL: Generar token mock para pruebas locales
          // TODO: Implementar endpoint /auth/login en el backend
          final mockToken = 'mock_token_${matricula}_${DateTime.now().millisecondsSinceEpoch}';
          
          return {
            'success': true,
            'token': mockToken,
            'matricula': matricula,
            'email': email,
            'message': 'Login temporal exitoso',
          };
        }
      } catch (e) {
        print('⚠️ Backend SASU no disponible, intentando backend producción...');
      }
      
      // Intentar con backend de producción
      final prodUrl = Uri.parse('https://carnet-alumnos-nodes.onrender.com/auth/login');
      
      final body = {
        'correo': email,
        'matricula': matricula,
      };
      
      print('🔍 LOGIN REQUEST PROD: $prodUrl');
      
      final response = await http.post(
        prodUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      
      print('📊 LOGIN RESPONSE: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['token'] != null) {
          return {
            'success': true,
            'token': data['token'],
            'matricula': data['matricula'] ?? matricula,
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Credenciales incorrectas',
      };
    } catch (e) {
      print('❌ LOGIN ERROR: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
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