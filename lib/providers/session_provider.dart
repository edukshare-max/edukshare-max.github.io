// 🔐 PROVIDER DE SESIÓN - SIN SQLITE, SOLO MEMORIA
// Estado global de la aplicación

import 'package:flutter/foundation.dart';
import '../models/carnet_model.dart';
import '../models/cita_model.dart';
import '../services/api_service.dart';

class SessionProvider extends ChangeNotifier {
  // Estados de la sesión
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _token;
  String? _error;
  CarnetModel? _carnet;
  List<CitaModel> _citas = [];

  // Getters
  bool get isAuthenticated => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get error => _error;
  CarnetModel? get carnet => _carnet;
  List<CitaModel> get citas => _citas;

  // Setters internos
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Método de login con SASU backend
  Future<bool> login(String correo, String matricula) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await ApiService.login(correo, matricula);
      
      if (result != null && result['success'] == true && result['token'] != null) {
        _token = result['token'];  // Corregido: 'token' en lugar de 'access_token'
        _isLoggedIn = true;
        
        // Cargar datos del carnet
        await _loadCarnetData();
        
        // Cargar citas
        await _loadCitasData();
        
        _setLoading(false);
        return true;
      } else {
        _setError('Credenciales inválidas');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: $e');
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
        notifyListeners(); // ¡IMPORTANTE! Notificar cambios a la UI
      } else {
        print('❌ No se pudo cargar el carnet');
      }
    } catch (e) {
      print('❌ Error cargando carnet: $e');
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
      
      notifyListeners();
    } catch (e) {
      print('❌ ERROR CARGANDO CITAS: $e');
      _citas = [];
      notifyListeners();
    }
  }

  // Método público para recargar citas
  Future<void> loadCitas() async {
    _setLoading(true);
    await _loadCitasData();
    _setLoading(false);
  }

  // Logout
  void logout() {
    _isLoggedIn = false;
    _token = null;
    _carnet = null;
    _citas = [];
    _error = null;
    notifyListeners();
  }
}