// 🎓 MODELO DE DATOS - CARNET ESTUDIANTE UAGRO
// Basado en respuestas reales del backend SASU

class CarnetModel {
  final String id;
  final String matricula;
  final String nombreCompleto;
  final String email;
  final String correo; // Campo adicional para compatibilidad
  final String carrera;
  final int semestre;  // Cambiar a int
  final String estado; // Agregar estado
  final String tipoSangre;
  final String curp;
  final String telefono;
  final String contactoEmergencia;
  final String seguroMedico;
  final String? fotoUrl;

  CarnetModel({
    required this.id,
    required this.matricula,
    required this.nombreCompleto,
    required this.email,
    required this.correo,
    required this.carrera,
    required this.semestre,
    required this.estado,
    required this.tipoSangre,
    required this.curp,
    required this.telefono,
    required this.contactoEmergencia,
    required this.seguroMedico,
    this.fotoUrl,
  });

  factory CarnetModel.fromJson(Map<String, dynamic> json) {
    print('🔍 PARSING CARNET DATA: $json');
    return CarnetModel(
      id: json['id'] ?? json['_id'] ?? 'carnet:${json['matricula']}',
      matricula: json['matricula'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? '',
      email: json['correo'] ?? '',
      correo: json['correo'] ?? '',
      carrera: json['programa'] ?? json['carrera'] ?? 'No especificada',
      semestre: 1, // Por defecto, no viene en datos SASU
      estado: json['categoria'] ?? 'Activo',
      tipoSangre: json['tipoSangre'] ?? '',
      curp: '', // No disponible en SASU
      telefono: json['emergenciaTelefono'] ?? '',
      contactoEmergencia: json['emergenciaContacto'] ?? '',
      seguroMedico: json['unidadMedica'] ?? json['usoSeguroUniversitario'] ?? '',
      fotoUrl: null, // No disponible en SASU
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricula': matricula,
      'nombreCompleto': nombreCompleto,
      'correo': correo,
      'email': email,
      'carrera': carrera,
      'semestre': semestre,
      'estado': estado,
      'tipo_sangre': tipoSangre,
      'curp': curp,
      'telefono': telefono,
      'contacto_emergencia': contactoEmergencia,
      'seguro_medico': seguroMedico,
      'foto_url': fotoUrl,
    };
  }
}