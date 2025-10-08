// 🏥 MODELO CITA MÉDICA - ESTRUCTURA BACKEND SASU
class CitaModel {
  final String id;
  final String matricula;
  final String inicio;
  final String fin;
  final String motivo;
  final String departamento;
  final String estado;
  final String createdAt;
  final String updatedAt;

  CitaModel({
    required this.id,
    required this.matricula,
    required this.inicio,
    required this.fin,
    required this.motivo,
    required this.departamento,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  // 🔄 PARSE DESDE JSON BACKEND SASU
  factory CitaModel.fromJson(Map<String, dynamic> json) {
    return CitaModel(
      id: json['id'] ?? '',
      matricula: json['matricula'] ?? '',
      inicio: json['inicio'] ?? '',
      fin: json['fin'] ?? '',
      motivo: json['motivo'] ?? '',
      departamento: json['departamento'] ?? '',
      estado: json['estado'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  // 📅 OBTENER FECHA FORMATEADA
  String get fechaFormateada {
    try {
      final datetime = DateTime.parse(inicio);
      return '${datetime.day.toString().padLeft(2, '0')}/${datetime.month.toString().padLeft(2, '0')}/${datetime.year}';
    } catch (e) {
      return 'Fecha no válida';
    }
  }

  // ⏰ OBTENER HORA INICIO
  String get horaInicio {
    try {
      final datetime = DateTime.parse(inicio);
      return '${datetime.hour.toString().padLeft(2, '0')}:${datetime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Hora no válida';
    }
  }

  // ⏰ OBTENER HORA FIN
  String get horaFin {
    try {
      final datetime = DateTime.parse(fin);
      return '${datetime.hour.toString().padLeft(2, '0')}:${datetime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Hora no válida';
    }
  }

  // 🕐 OBTENER RANGO DE HORARIO
  String get horario => '$horaInicio - $horaFin';

  // 🎨 COLOR SEGÚN ESTADO
  String get colorEstado {
    switch (estado.toLowerCase()) {
      case 'programada':
        return '#4CAF50'; // Verde
      case 'confirmada':
        return '#2196F3'; // Azul
      case 'cancelada':
        return '#F44336'; // Rojo
      case 'completada':
        return '#9E9E9E'; // Gris
      default:
        return '#FF9800'; // Naranja
    }
  }

  // 📄 PARA DEBUG
  @override
  String toString() {
    return 'CitaModel(id: $id, matricula: $matricula, inicio: $inicio, motivo: $motivo, departamento: $departamento, estado: $estado)';
  }

  // 📄 CONVERTIR A JSON (para futuras funcionalidades)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricula': matricula,
      'inicio': inicio,
      'fin': fin,
      'motivo': motivo,
      'departamento': departamento,
      'estado': estado,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}