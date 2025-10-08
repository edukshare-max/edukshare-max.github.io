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

  // Cargar citas médicas
  Future<void> _loadCitasData() async {
    if (_token == null) return;

    try {
      print('🔍 Cargando citas médicas...');
      final data = await ApiService.getCitas(_token!);
      if (data != null && data.isNotEmpty) {
        _citas = data;
        print('✅ Citas cargadas: ${_citas.length} citas');
      } else {
        print('ℹ️ No hay citas en el backend, generando citas de demostración...');
        // Generar citas de demostración para la presentación
        _citas = _generateDemoCitas();
        print('✅ Citas de demostración generadas: ${_citas.length} citas');
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error cargando citas: $e');
      print('ℹ️ Generando citas de demostración...');
      _citas = _generateDemoCitas();
      notifyListeners();
    }
  }

  // Generar citas de demostración para la presentación
  List<CitaModel> _generateDemoCitas() {
    final now = DateTime.now();
    return [
      CitaModel(
        id: 'cita_001',
        matricula: _carnet?.matricula ?? '15662',
        fecha: now.add(const Duration(days: 3)),
        hora: '10:00',
        tipo: 'Consulta General',
        servicio: 'Medicina General',
        doctor: 'Dr. María González',
        estado: 'CONFIRMADA',
        motivo: 'Revisión general de salud',
        lugar: 'Consultorio 1 - Centro Médico UAGro',
        notas: 'Traer estudios previos si los tiene',
      ),
      CitaModel(
        id: 'cita_002',
        matricula: _carnet?.matricula ?? '15662',
        fecha: now.add(const Duration(days: 7)),
        hora: '14:30',
        tipo: 'Especialidad',
        servicio: 'Odontología',
        doctor: 'Dr. Carlos Ramírez',
        estado: 'PENDIENTE',
        motivo: 'Limpieza dental',
        lugar: 'Consultorio Dental - UAGro',
        notas: 'Confirmar asistencia 24 horas antes',
      ),
      CitaModel(
        id: 'cita_003',
        matricula: _carnet?.matricula ?? '15662',
        fecha: now.subtract(const Duration(days: 2)),
        hora: '09:00',
        tipo: 'Consulta General',
        servicio: 'Medicina General',
        doctor: 'Dra. Ana Martínez',
        estado: 'COMPLETADA',
        motivo: 'Seguimiento de alergias',
        lugar: 'Consultorio 3 - Centro Médico UAGro',
        notas: 'Revisión completada exitosamente',
      ),
    ];
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