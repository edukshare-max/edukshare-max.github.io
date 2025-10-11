// 🔐 PROVIDER DE SESIÓN - CON CACHÉ Y MANEJO ROBUSTO DE ERRORES
// Estado global de la aplicación con persistencia local

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:carnet_digital_uagro/models/carnet_model.dart';
import 'package:carnet_digital_uagro/models/cita_model.dart';
import 'package:carnet_digital_uagro/models/promocion_salud_model.dart';
import 'package:carnet_digital_uagro/models/vacuna_model.dart';
import 'package:carnet_digital_uagro/services/api_service.dart';

class SessionProvider extends ChangeNotifier {
  // Estados de la sesión
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _token;
  String? _error;
  String? _errorType; // NUEVO: Tipo específico de error
  CarnetModel? _carnet;
  List<CitaModel> _citas = [];
  List<PromocionSaludModel> _promociones = [];
  List<VacunaModel> _vacunas = [];
  
  // Estado del backend
  bool _backendHealthy = true;
  String? _backendMessage;
  int? _backendResponseTime;

  // Getters
  bool get isAuthenticated => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get error => _error;
  String? get errorType => _errorType;
  CarnetModel? get carnet => _carnet;
  List<CitaModel> get citas => _citas;
  List<PromocionSaludModel> get promociones => _promociones;
  List<VacunaModel> get vacunas => _vacunas;
  bool get backendHealthy => _backendHealthy;
  String? get backendMessage => _backendMessage;
  int? get backendResponseTime => _backendResponseTime;

  // 🔧 KEYS PARA SHARED PREFERENCES
  static const String _keyToken = 'auth_token';
  static const String _keyCarnet = 'cached_carnet';
  static const String _keyLoginTime = 'login_timestamp';

  // Setters internos
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error, [String? type]) {
    _error = error;
    _errorType = type;
    notifyListeners();
  }
  
  void _setBackendStatus(bool healthy, String? message, int? responseTime) {
    _backendHealthy = healthy;
    _backendMessage = message;
    _backendResponseTime = responseTime;
    notifyListeners();
  }

  // 💾 RESTAURAR SESIÓN DESDE CACHÉ (llamar al iniciar app)
  Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedToken = prefs.getString(_keyToken);
      final cachedCarnetJson = prefs.getString(_keyCarnet);
      final loginTimestamp = prefs.getInt(_keyLoginTime);
      
      if (cachedToken == null || cachedCarnetJson == null || loginTimestamp == null) {
        print('📭 No hay sesión guardada');
        return false;
      }
      
      // Verificar que el token no tenga más de 7 días
      final loginDate = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
      final daysSinceLogin = DateTime.now().difference(loginDate).inDays;
      
      if (daysSinceLogin > 7) {
        print('⏰ Sesión expirada (${daysSinceLogin} días)');
        await clearCache();
        return false;
      }
      
      // Restaurar datos
      _token = cachedToken;
      _carnet = CarnetModel.fromJson(jsonDecode(cachedCarnetJson));
      _isLoggedIn = true;
      
      print('✅ Sesión restaurada: ${_carnet?.nombreCompleto}');
      print('🕐 Login hace $daysSinceLogin día(s)');
      
      // Cargar datos frescos en background
      _loadCarnetData();
      _loadCitasData();
      _loadVacunasData();
      loadPromociones(notifyWhenDone: false);
      
      notifyListeners();
      return true;
      
    } catch (e) {
      print('❌ Error restaurando sesión: $e');
      await clearCache();
      return false;
    }
  }
  
  // 💾 GUARDAR SESIÓN EN CACHÉ
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_token != null && _carnet != null) {
        await prefs.setString(_keyToken, _token!);
        await prefs.setString(_keyCarnet, jsonEncode(_carnet!.toJson()));
        await prefs.setInt(_keyLoginTime, DateTime.now().millisecondsSinceEpoch);
        print('💾 Sesión guardada en caché');
      }
    } catch (e) {
      print('❌ Error guardando sesión: $e');
    }
  }
  
  // 🗑️ LIMPIAR CACHÉ
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyCarnet);
      await prefs.remove(_keyLoginTime);
      print('🗑️ Caché limpiada');
    } catch (e) {
      print('❌ Error limpiando caché: $e');
    }
  }

  // 🏥 VERIFICAR SALUD DEL BACKEND (llamar antes de login)
  Future<void> checkBackend() async {
    try {
      final health = await ApiService.checkBackendHealth();
      _setBackendStatus(
        health['healthy'] ?? false,
        health['message'],
        health['responseTime'],
      );
    } catch (e) {
      _setBackendStatus(false, 'Error verificando backend', -1);
    }
  }

  // 🔑 MÉTODO DE LOGIN CON REINTENTOS Y CACHÉ
  Future<bool> login(String correo, String matricula) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await ApiService.login(correo, matricula);
      
      if (result != null && result['success'] == true && result['token'] != null) {
        _token = result['token'];
        _isLoggedIn = true;
        
        // Mostrar info de cold start si aplica
        if (result['coldStart'] == true) {
          print('❄️ Login completado después de cold start (${result['responseTime']}ms)');
        }
        
        // Cargar todos los datos SIN notificar en cada paso
        await _loadCarnetData();
        await _loadCitasData();
        await _loadVacunasData();
        await loadPromociones(notifyWhenDone: false);
        
        // Guardar sesión en caché
        await _saveSession();
        
        // SOLO UNA notificación al final con todos los datos cargados
        _setLoading(false);
        return true;
        
      } else if (result != null && result['errorType'] == 'CREDENTIALS') {
        // Error de credenciales - mensaje específico
        _setError(result['message'] ?? 'Credenciales incorrectas', 'CREDENTIALS');
        _setLoading(false);
        return false;
        
      } else {
        // Error genérico
        _setError('Error en el servidor. Intente nuevamente.', 'SERVER');
        _setLoading(false);
        return false;
      }
      
    } catch (e) {
      // El sistema de reintentos agotó los intentos
      final errorStr = e.toString();
      
      if (errorStr.contains('TIMEOUT')) {
        _setError(
          'El servidor tardó demasiado en responder. Puede estar iniciando, intente en 30 segundos.',
          'TIMEOUT'
        );
      } else if (errorStr.contains('SocketException') || errorStr.contains('NetworkException')) {
        _setError(
          'Sin conexión a internet. Verifique su red.',
          'NETWORK'
        );
      } else {
        _setError(
          'Error de conexión después de múltiples intentos. Intente más tarde.',
          'CONNECTION'
        );
      }
      
      _setLoading(false);
      return false;
    }
  }

  // Cargar datos del carnet desde SASU
  Future<void> _loadCarnetData() async {
    if (_token == null) return;

    try {
      print('🔍 Cargando datos del carnet...');
      final carnet = await ApiService.getMyCarnet(_token!);
      if (carnet != null) {
        _carnet = carnet;
        print('✅ Carnet cargado: ${carnet.nombreCompleto}');
        // NO llamar notifyListeners() aquí - se llamará al final del login
      } else {
        print('❌ No se pudo cargar el carnet');
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('INVALID_TOKEN')) {
        print('🚫 Token inválido detectado - cerrando sesión automáticamente');
        await clearCache();
        logout();
      } else {
        print('❌ Error cargando carnet: $e');
      }
    }
  }

  // 🏥 CARGAR CITAS MÉDICAS - BACKEND REAL SASU
  Future<void> _loadCitasData() async {
    if (_token == null) return;

    try {
      print('🔍 Cargando citas médicas desde SASU backend...');
      final data = await ApiService.getCitas(_token!);
      
      if (data != null && data.isNotEmpty) {
        _citas = data;
        print('✅ CITAS REALES CARGADAS: ${_citas.length} citas');
        
        // Debug: mostrar primera cita
        if (_citas.isNotEmpty) {
          print('📋 PRIMERA CITA REAL: ${_citas.first}');
        }
      } else {
        print('⚠️ NO HAY CITAS DISPONIBLES EN EL BACKEND SASU');
        _citas = [];
      }
      
      // NO llamar notifyListeners() aquí - se llamará al final del login
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('INVALID_TOKEN')) {
        print('🚫 Token inválido detectado - cerrando sesión automáticamente');
        await clearCache();
        logout();
      } else {
        print('❌ ERROR CARGANDO CITAS: $e');
        _citas = [];
      }
    }
  }

  // Método público para recargar citas
  Future<void> loadCitas() async {
    _setLoading(true);
    await _loadCitasData();
    _setLoading(false);
  }

  // 💉 CARGAR VACUNAS - BACKEND REAL SASU
  Future<void> _loadVacunasData() async {
    if (_token == null) return;

    try {
      print('🔍 Cargando vacunas desde SASU backend...');
      final data = await ApiService.getVacunas(_token!);
      
      if (data.isNotEmpty) {
        _vacunas = data;
        print('✅ VACUNAS REALES CARGADAS: ${_vacunas.length} registros');
        
        // Debug: mostrar primera vacuna
        if (_vacunas.isNotEmpty) {
          print('💉 PRIMERA VACUNA: ${_vacunas.first}');
        }
      } else {
        print('⚠️ NO HAY VACUNAS DISPONIBLES EN EL BACKEND SASU');
        _vacunas = [];
      }
      
      // NO llamar notifyListeners() aquí - se llamará al final del login
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('INVALID_TOKEN')) {
        print('🚫 Token inválido detectado - cerrando sesión automáticamente');
        await clearCache();
        logout();
      } else {
        print('❌ ERROR CARGANDO VACUNAS: $e');
        _vacunas = [];
      }
    }
  }

  // Método público para recargar vacunas
  Future<void> loadVacunas() async {
    _setLoading(true);
    await _loadVacunasData();
    _setLoading(false);
  }

  // Método DEMO para mostrar diseño sin login
  void loadDemoData() {
    _carnet = CarnetModel(
      id: 'demo-001',
      matricula: 'DEMO-2024',
      nombreCompleto: 'Juan Pérez García',
      correo: 'juan.perez@uagro.mx',
      edad: 21,
      sexo: 'Masculino',
      programa: 'Ingeniería en Computación',
      categoria: 'Licenciatura',
      tipoSangre: 'O+',
      unidadMedica: 'IMSS - Unidad 01',
      numeroAfiliacion: '1234567890',
      usoSeguroUniversitario: 'Sí',
      donante: 'Sí',
      enfermedadCronica: '',
      alergias: '',
      discapacidad: 'No',
      tipoDiscapacidad: '',
      emergenciaContacto: 'María García López',
      emergenciaTelefono: '7441234567',
      expedienteNotas: 'Estudiante regular con buen desempeño académico.',
      expedienteAdjuntos: '',
    );
    
    _citas = [
      CitaModel(
        id: '1',
        matricula: 'DEMO-2024',
        inicio: '2025-10-15T10:00:00',
        fin: '2025-10-15T10:30:00',
        motivo: 'Consulta General',
        departamento: 'Medicina General',
        estado: 'Pendiente',
        createdAt: '2025-10-09T12:00:00',
        updatedAt: '2025-10-09T12:00:00',
      ),
      CitaModel(
        id: '2',
        matricula: 'DEMO-2024',
        inicio: '2025-10-20T14:30:00',
        fin: '2025-10-20T15:00:00',
        motivo: 'Revisión de Resultados',
        departamento: 'Laboratorio',
        estado: 'Confirmada',
        createdAt: '2025-10-09T12:00:00',
        updatedAt: '2025-10-09T12:00:00',
      ),
    ];
    
    // Promociones: se cargan dinámicamente desde Cosmos DB
    _promociones = [];
    
    _isLoggedIn = true;
    _token = 'DEMO_TOKEN';
    notifyListeners();
  }

  // 📢 CARGAR PROMOCIONES DE SALUD DESDE COSMOS DB
  // Filtrado por destinatario:
  // - "general": Para todos los usuarios
  // - "alumno": Para todos los alumnos (sin matrícula específica)
  // - matrícula específica: Solo para ese alumno
  Future<void> loadPromociones({bool notifyWhenDone = true}) async {
    print('📢 ============================================');
    print('📢 CARGANDO PROMOCIONES DE SALUD');
    print('📢 ============================================');
    
    // En modo demo, cargar promociones desde API
    if (_token == 'DEMO_TOKEN') {
      print('⚠️ Modo DEMO - cargando desde API...');
      // Continuar con la carga normal
    }
    
    // Validar autenticación
    if (_token == null || _token!.isEmpty) {
      print('❌ Sin token de autenticación');
      _promociones = [];
      notifyListeners();
      return;
    }
    
    // Validar que tengamos matrícula
    if (_carnet == null || _carnet!.matricula.isEmpty) {
      print('❌ Sin matrícula en el carnet');
      _promociones = [];
      notifyListeners();
      return;
    }
    
    final matricula = _carnet!.matricula;
    print('🎓 Matrícula: $matricula');
    
    _setLoading(true);
    
    try {
      // Llamar al backend para obtener promociones
      print('🔄 Consultando backend: /me/promociones');
      final promocionesApi = await ApiService.getPromocionesSalud(_token!, matricula);
      
      print('📊 Total recibido del backend: ${promocionesApi.length} promociones');
      
      if (promocionesApi.isEmpty) {
        print('ℹ️ No hay promociones disponibles');
        _promociones = [];
      } else {
        // Debug: Mostrar todas las promociones recibidas
        print('📋 PROMOCIONES RECIBIDAS DEL BACKEND:');
        for (var p in promocionesApi) {
          print('   - ID: ${p.id}');
          print('     Destinatario: "${p.destinatario}"');
          print('     Matrícula: "${p.matricula ?? ""}"');
          print('     Autorizado: ${p.autorizado}');
          print('     Categoría: ${p.categoria}');
        }
        
        // Filtrar promociones autorizadas
        final autorizadas = promocionesApi.where((p) => p.autorizado == true).toList();
        
        print('✅ Promociones autorizadas: ${autorizadas.length}');
        
        // Filtrar por destinatario según la lógica de Cosmos DB:
        // 1. destinatario="general" → Para TODOS los usuarios (SIEMPRE)
        // 2. destinatario="alumno" + matricula="" → Para TODOS los alumnos
        // 3. destinatario="alumno" + matricula="15662" → SOLO para esa matrícula
        
        print('🔍 FILTRANDO PROMOCIONES PARA MATRÍCULA: $matricula');
        
        _promociones = autorizadas.where((p) {
          final destinatarioLower = p.destinatario.toLowerCase().trim();
          final matriculaPromo = p.matricula?.trim() ?? '';
          
          print('🔎 Evaluando promoción ${p.id}:');
          print('   Destinatario: "$destinatarioLower"');
          print('   Matrícula promo: "$matriculaPromo"');
          
          // Caso 1: Promoción GENERAL (para todos) - SIEMPRE SE INCLUYE
          if (destinatarioLower == 'general') {
            print('   ✅ INCLUIDA: Es GENERAL (para todos los usuarios)');
            return true;
          }
          
          // Caso 2: destinatario="alumno"
          if (destinatarioLower == 'alumno') {
            // Si tiene matrícula específica, verificar que coincida
            if (matriculaPromo.isNotEmpty) {
              if (matriculaPromo == matricula) {
                print('   ✅ INCLUIDA: ALUMNO ESPECÍFICO (matrícula coincide: $matricula)');
                return true;
              } else {
                print('   ❌ EXCLUIDA: Es para otro alumno ($matriculaPromo ≠ $matricula)');
                return false;
              }
            } else {
              // Sin matrícula = para todos los alumnos
              print('   ✅ INCLUIDA: Para TODOS LOS ALUMNOS (sin matrícula específica)');
              return true;
            }
          }
          
          // No aplica para este usuario
          print('   ❌ EXCLUIDA: Destinatario "$destinatarioLower" no reconocido');
          return false;
        }).toList();
        
        print('🎯 Promociones filtradas para mostrar: ${_promociones.length}');
      }
      
    } catch (e, stackTrace) {
      print('❌ ERROR al cargar promociones: $e');
      print('Stack: $stackTrace');
      _promociones = [];
    } finally {
      _setLoading(false);
      if (notifyWhenDone) {
        notifyListeners();
      }
      print('📢 ============================================');
    }
  }

  // 🗑️ MARCAR PROMOCIÓN COMO VISTA
  Future<void> marcarPromocionVista(String promocionId) async {
    if (_token == null) return;
    
    try {
      final success = await ApiService.marcarPromocionVista(_token!, promocionId);
      if (success) {
        _promociones.removeWhere((p) => p.id == promocionId);
        notifyListeners();
        print('✅ Promoción $promocionId marcada como vista');
      }
    } catch (e) {
      print('❌ Error marcando promoción vista: $e');
    }
  }

  // Logout
  void logout() {
    _isLoggedIn = false;
    _token = null;
    _carnet = null;
    _citas = [];
    _promociones = [];
    _error = null;
    notifyListeners();
  }
}