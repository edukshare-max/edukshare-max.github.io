// 🔐 PROVIDER DE SESIÓN - SIN SQLITE, SOLO MEMORIA
// Estado global de la aplicación

import 'package:flutter/foundation.dart';
import 'package:carnet_digital_uagro/models/carnet_model.dart';
import 'package:carnet_digital_uagro/models/cita_model.dart';
import 'package:carnet_digital_uagro/models/promocion_salud_model.dart';
import 'package:carnet_digital_uagro/services/api_service.dart';

class SessionProvider extends ChangeNotifier {
  // Estados de la sesión
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _token;
  String? _error;
  CarnetModel? _carnet;
  List<CitaModel> _citas = [];
  List<PromocionSaludModel> _promociones = [];

  // Getters
  bool get isAuthenticated => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get error => _error;
  CarnetModel? get carnet => _carnet;
  List<CitaModel> get citas => _citas;
  List<PromocionSaludModel> get promociones => _promociones;

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
        notifyListeners(); // ✅ Notificar que el login fue exitoso
        
        // Cargar datos del carnet
        await _loadCarnetData();
        
        // Cargar citas
        await _loadCitasData();
        
        // Cargar promociones de salud
        await loadPromociones();
        
        _setLoading(false); // ✅ Esto ya llama notifyListeners()
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
        print('🔄 Llamando notifyListeners() para carnet...');
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
      
      print('🔄 Llamando notifyListeners() para citas...');
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
    
    // Promociones demo de salud con nueva estructura SASU
    _promociones = [
      PromocionSaludModel(
        id: 'demo:promocion-1',
        matricula: '15662',
        link: 'https://www.gob.mx/salud/articulos/chequeos-medicos-preventivos',
        departamento: 'Consultorio médico',
        categoria: 'Promoción',
        programa: 'Licenciatura',
        destinatario: 'alumno',
        autorizado: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        createdBy: 'SASU',
      ),
      PromocionSaludModel(
        id: 'demo:promocion-2',
        matricula: '15662',
        link: 'https://www.gob.mx/salud/articulos/vacunacion-universitaria',
        departamento: 'Enfermería',
        categoria: 'Prevención',
        programa: 'Licenciatura',
        destinatario: 'alumno',
        autorizado: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        createdBy: 'SASU',
      ),
      PromocionSaludModel(
        id: 'demo:promocion-3',
        matricula: '15662',
        link: 'https://www.gob.mx/salud/articulos/nutricion-estudiantil',
        departamento: 'Nutrición',
        categoria: 'Promoción',
        programa: 'Licenciatura',
        destinatario: 'alumno',
        autorizado: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        createdBy: 'SASU',
      ),
    ];
    
    _isLoggedIn = true;
    _token = 'DEMO_TOKEN';
    notifyListeners();
  }

  // 🏥 CARGAR PROMOCIONES DE SALUD
  Future<void> loadPromociones() async {
    print('🔄 INICIANDO CARGA DE PROMOCIONES...');
    
    // En modo demo, no hacer llamada API - las promociones ya están cargadas
    if (_token == 'DEMO_TOKEN') {
      print('🎭 Modo DEMO - usando promociones precargadas');
      notifyListeners();
      return;
    }
    
    // Para login real, intentar siempre la API incluso si no hay carnet completo
    if (_token == null) {
      print('❌ No hay token - no se puede conectar a API');
      _agregarPromocionDebug();
      return;
    }
    
    _setLoading(true);
    try {
      // Usar matrícula del carnet si existe, sino intentar con 15662
      final matricula = _carnet?.matricula ?? '15662';
      print('🔍 Buscando promociones para matrícula: $matricula');
      print('🔑 Token disponible: ${_token!.substring(0, 10)}...');
      
      final promocionesApi = await ApiService.getPromocionesSalud(_token!, matricula);
      
      print('📊 API RESPONSE: ${promocionesApi.length} promociones');
      
      if (promocionesApi.isNotEmpty) {
        // Filtrar promociones activas/autorizadas  
        _promociones = promocionesApi.where((p) => p.autorizado).toList();
        print('✅ PROMOCIONES CARGADAS DESDE API: ${_promociones.length}');
        for (var p in _promociones) {
          print('   - ${p.titulo} (${p.id}, ${p.categoria}, ${p.departamento})');
        }
        
        // Si encontramos promociones reales, no agregar debug
        if (_promociones.isNotEmpty) {
          print('🎯 USANDO PROMOCIONES REALES DE LA API');
        } else {
          print('⚠️ Promociones filtradas resultaron vacías, agregando debug...');
          _agregarPromocionDebug();
        }
      } else {
        print('⚠️ API no devolvió promociones - endpoint no implementado en backend');
        print('📝 Nota: El backend SASU aún no tiene endpoints de promociones');
        _agregarPromocionDebug();
      }
      
      print('🎯 PROMOCIONES FINALES: ${_promociones.length}');
    } catch (e) {
      print('❌ Error cargando promociones: $e');
      print('� Todos los endpoints de promociones devuelven 404');
      print('🔧 El backend necesita implementar endpoints de promociones');
      _setError('Promociones no disponibles temporalmente');
      _agregarPromocionDebug();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
  
  void _agregarPromocionDebug() {
    print('🔧 Agregando promociones temporales (backend no tiene endpoint de promociones aún)...');
    _promociones = [
      PromocionSaludModel(
        id: 'temp-001',
        link: 'https://sasu.uagro.mx/consulta-general',
        departamento: 'Consultorio Médico',
        categoria: 'Consulta Médica',
        programa: 'Atención Médica Estudiantil',
        matricula: _carnet?.matricula ?? '15662',
        destinatario: 'alumno',
        autorizado: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        createdBy: 'Dr. Sistema SASU',
      ),
      PromocionSaludModel(
        id: 'temp-002',
        link: 'https://sasu.uagro.mx/prevencion-salud',
        departamento: 'Consultorio Médico',
        categoria: 'Prevención',
        programa: 'Campañas de Salud Preventiva',
        matricula: _carnet?.matricula ?? '15662',
        destinatario: 'alumno',
        autorizado: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        createdBy: 'Dr. Sistema SASU',
      ),
    ];
    print('✅ Promociones temporales agregadas: ${_promociones.length}');
    for (var p in _promociones) {
      print('   - ${p.titulo} (${p.departamento}, ${p.categoria})');
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