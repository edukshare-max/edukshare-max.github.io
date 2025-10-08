// 🎓 MODELO DE DATOS - CARNET ESTUDIANTE UAGRO - BACKEND SASU REAL
class CarnetModel {
  final String id;
  final String matricula;
  final String nombreCompleto;
  final String correo;
  final String programa;
  final String categoria;
  final String tipoSangre;
  final String emergenciaContacto;
  final String emergenciaTelefono;
  final String unidadMedica;
  final bool usoSeguroUniversitario;
  final String createdAt;
  final String updatedAt;

  CarnetModel({
    required this.id,
    required this.matricula,
    required this.nombreCompleto,
    required this.correo,
    required this.programa,
    required this.categoria,
    required this.tipoSangre,
    required this.emergenciaContacto,
    required this.emergenciaTelefono,
    required this.unidadMedica,
    required this.usoSeguroUniversitario,
    required this.createdAt,
    required this.updatedAt,
  });

  // 🔄 PARSE DESDE JSON BACKEND SASU REAL
  factory CarnetModel.fromJson(Map<String, dynamic> json) {
    print('🔍 PARSING CARNET DATA: $json');
    return CarnetModel(
      id: json['id'] ?? '',
      matricula: json['matricula'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? '',
      correo: json['correo'] ?? '',
      programa: json['programa'] ?? '',
      categoria: json['categoria'] ?? '',
      tipoSangre: json['tipoSangre'] ?? '',
      emergenciaContacto: json['emergenciaContacto'] ?? '',
      emergenciaTelefono: json['emergenciaTelefono'] ?? '',
      unidadMedica: json['unidadMedica'] ?? '',
      usoSeguroUniversitario: json['usoSeguroUniversitario'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  // 📄 GETTERS PARA COMPATIBILIDAD CON UI EXISTENTE
  String get carrera => programa;
  String get estado => categoria;
  String get telefono => emergenciaTelefono;
  String get contactoEmergencia => emergenciaContacto;
  String get seguroMedico => usoSeguroUniversitario ? unidadMedica : 'Sin seguro universitario';
  String get email => correo;

  // 📄 CONVERTIR A JSON (para futuras funcionalidades)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricula': matricula,
      'nombreCompleto': nombreCompleto,
      'correo': correo,
      'programa': programa,
      'categoria': categoria,
      'tipoSangre': tipoSangre,
      'emergenciaContacto': emergenciaContacto,
      'emergenciaTelefono': emergenciaTelefono,
      'unidadMedica': unidadMedica,
      'usoSeguroUniversitario': usoSeguroUniversitario,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // 📄 PARA DEBUG
  @override
  String toString() {
    return 'CarnetModel(id: $id, matricula: $matricula, nombreCompleto: $nombreCompleto, programa: $programa, categoria: $categoria)';
  }
}