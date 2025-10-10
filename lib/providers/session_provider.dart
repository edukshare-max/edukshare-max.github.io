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
        
        // Cargar todos los datos SIN notificar en cada paso
        await _loadCarnetData();
        await _loadCitasData();
        await loadPromociones(notifyWhenDone: false);
        
        // SOLO UNA notificación al final con todos los datos cargados
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
        // NO llamar notifyListeners() aquí - se llamará al final del login
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
      
      // NO llamar notifyListeners() aquí - se llamará al final del login
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
        // Filtrar promociones autorizadas
        final autorizadas = promocionesApi.where((p) => p.autorizado == true).toList();
        
        print('✅ Promociones autorizadas: ${autorizadas.length}');
        
        // Filtrar por destinatario según la lógica de Cosmos DB:
        // 1. destinatario="general" → Para TODOS los usuarios
        // 2. destinatario="alumno" + matricula="" → Para TODOS los alumnos
        // 3. destinatario="alumno" + matricula="15662" → SOLO para esa matrícula
        _promociones = autorizadas.where((p) {
          // Caso 1: Promoción GENERAL (para todos)
          if (p.destinatario.toLowerCase() == 'general') {
            print('   ✓ GENERAL: ${p.categoria} - ${p.departamento}');
            return true;
          }
          
          // Caso 2: destinatario="alumno"
          if (p.destinatario.toLowerCase() == 'alumno') {
            // Si tiene matrícula específica, verificar que coincida
            if (p.matricula != null && p.matricula!.isNotEmpty) {
              if (p.matricula == matricula) {
                print('   ✓ ALUMNO ESPECÍFICO [$matricula]: ${p.categoria} - ${p.departamento}');
                return true;
              } else {
                // Es para otro alumno
                return false;
              }
            } else {
              // Sin matrícula = para todos los alumnos
              print('   ✓ TODOS LOS ALUMNOS: ${p.categoria} - ${p.departamento}');
              return true;
            }
          }
          
          // No aplica para este usuario
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