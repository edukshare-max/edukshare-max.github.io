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
    return CarnetModel(
      id: json['_id'] ?? json['id'] ?? '',
      matricula: json['matricula'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? json['nombre_completo'] ?? '',
      email: json['correo'] ?? json['email'] ?? '',
      correo: json['correo'] ?? json['email'] ?? '',
      carrera: json['carrera'] ?? '',
      semestre: int.tryParse(json['semestre']?.toString() ?? '1') ?? 1,
      estado: json['estado'] ?? 'Activo',
      tipoSangre: json['tipo_sangre'] ?? json['tipoSangre'] ?? '',
      curp: json['curp'] ?? '',
      telefono: json['telefono'] ?? '',
      contactoEmergencia: json['contacto_emergencia'] ?? json['contactoEmergencia'] ?? '',
      seguroMedico: json['seguro_medico'] ?? json['seguroMedico'] ?? '',
      fotoUrl: json['foto_url'] ?? json['fotoUrl'],
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