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
      
      if (result != null && result['access_token'] != null) {
        _token = result['access_token'];
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
      final carnet = await ApiService.getMyCarnet(_token!);
      if (carnet != null) {
        _carnet = carnet;
      }
    } catch (e) {
      print('Error cargando carnet: $e');
    }
  }

  // Cargar citas médicas
  Future<void> _loadCitasData() async {
    if (_token == null) return;

    try {
      final data = await ApiService.getCitas(_token!);
      if (data != null && data is List) {
        _citas = data.map((item) => CitaModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      print('Error cargando citas: $e');
      _citas = []; // Lista vacía en caso de error
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