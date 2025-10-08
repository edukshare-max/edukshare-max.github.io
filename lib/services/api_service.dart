// 🌐 SERVICIO API SASU - OPTIMIZADO Y FUNCIONAL
// Basado en endpoints reales que funcionan

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/carnet_model.dart';
import '../models/cita_model.dart';

class ApiService {
  static const String baseUrl = 'https://carnet-alumnos-nodes.onrender.com';
  
  // 🔑 LOGIN CON JWT
  static Future<Map<String, dynamic>?> login(String email, String matricula) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      
      // IMPORTANTE: Backend SASU espera 'correo', NO 'email'
      final body = {
        'correo': email,
        'matricula': matricula,
      };
      
      print('🔍 LOGIN REQUEST: $url');
      print('📦 BODY: $body');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      print('📊 LOGIN RESPONSE: ${response.statusCode}');
      print('📋 RESPONSE BODY: ${response.body}');
      
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
  
  // 🏥 OBTENER CITAS MÉDICAS
  static Future<List<CitaModel>> getCitas(String token) async {
    try {
      final url = Uri.parse('$baseUrl/citas');
      
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
}