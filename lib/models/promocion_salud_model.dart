// 🏥 PROMOCION SALUD MODEL - Estructura para promociones médicas
// Integración con estructura real de SASU Backend

class PromocionSaludModel {
  final String id;
  final String matricula;
  final String? link;
  final String departamento;
  final String categoria;
  final String programa;
  final String destinatario;
  final bool autorizado;
  final DateTime createdAt;
  final String createdBy;
  
  // Campos adicionales del backend SASU
  final String? titulo;
  final String? descripcionCompleta;
  final String? resumen;
  final String? imagenUrl;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool destacado;
  final bool urgente;
  final int prioridad;
  final bool esEspecifica;

  PromocionSaludModel({
    required this.id,
    required this.matricula,
    this.link,
    required this.departamento,
    required this.categoria,
    required this.programa,
    required this.destinatario,
    required this.autorizado,
    required this.createdAt,
    required this.createdBy,
    this.titulo,
    this.descripcionCompleta,
    this.resumen,
    this.imagenUrl,
    this.fechaInicio,
    this.fechaFin,
    this.destacado = false,
    this.urgente = false,
    this.prioridad = 5,
    this.esEspecifica = false,
  });

  factory PromocionSaludModel.fromJson(Map<String, dynamic> json) {
    return PromocionSaludModel(
      id: json['id']?.toString() ?? '',
      matricula: json['matricula']?.toString() ?? '',
      link: json['link'],
      departamento: json['departamento'] ?? 'SASU',
      categoria: json['categoria'] ?? 'General',
      programa: json['programa'] ?? json['titulo'] ?? 'Sin título',
      destinatario: json['destinatario'] ?? 'Alumno',
      autorizado: json['autorizado'] ?? true,
      createdAt: _parseDate(json['createdAt'] ?? json['fecha_publicacion'] ?? json['created_at']),
      createdBy: json['createdBy'] ?? json['departamento'] ?? 'Sistema SASU',
      titulo: json['titulo'],
      descripcionCompleta: json['descripcion'],
      resumen: json['resumen'] ?? json['descripcion'],
      imagenUrl: json['imagen_url'],
      fechaInicio: _parseDate(json['fecha_inicio']),
      fechaFin: _parseDate(json['fecha_fin']),
      destacado: json['destacado'] ?? false,
      urgente: json['urgente'] ?? false,
      prioridad: json['prioridad'] ?? 5,
      esEspecifica: json['es_especifica'] ?? false,
    );
  }
  
  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    try {
      return DateTime.parse(date.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricula': matricula,
      'link': link,
      'departamento': departamento,
      'categoria': categoria,
      'programa': programa,
      'destinatario': destinatario,
      'autorizado': autorizado,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'titulo': titulo,
      'descripcion': descripcionCompleta,
      'resumen': resumen,
      'imagen_url': imagenUrl,
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'destacado': destacado,
      'urgente': urgente,
      'prioridad': prioridad,
      'es_especifica': esEspecifica,
    };
  }

  // Getter para título a mostrar (usa titulo si existe, sino genera uno)
  String get tituloDisplay {
    if (titulo != null && titulo!.isNotEmpty) {
      return titulo!;
    }
    
    // Fallback a título dinámico
    String emoji = '📋';
    switch (categoria.toLowerCase()) {
      case 'promoción':
      case 'promocion':
        emoji = '🏥';
        break;
      case 'prevención':
      case 'prevencion':
        emoji = '🛡️';
        break;
      case 'urgente':
      case 'salud mental':
        emoji = '🚨';
        break;
      case 'vacunación':
      case 'vacunacion':
        emoji = '💉';
        break;
    }
    
    return '$emoji $programa';
  }

  // Getter para descripción a mostrar
  String get descripcion {
    // Si hay descripción completa, usarla
    if (descripcionCompleta != null && descripcionCompleta!.isNotEmpty) {
      return descripcionCompleta!;
    }
    
    // Si hay resumen, usarlo
    if (resumen != null && resumen!.isNotEmpty) {
      return resumen!;
    }
    
    // Fallback a descripción dinámica
    if (link != null && link!.isNotEmpty) {
      return 'Información importante de $departamento. Toca para más detalles.';
    }
    return 'Comunicado de $departamento para estudiantes.';
  }

  // Getter para color basado en categoría
  String get colorTema {
    switch (categoria.toLowerCase()) {
      case 'promoción':
      case 'promocion':
        return '#0175C2'; // Azul UAGro
      case 'prevención':
      case 'prevencion':
        return '#28A745'; // Verde
      case 'urgente':
        return '#DC3545'; // Rojo
      default:
        return '#6C757D'; // Gris
    }
  }

  // Getter para tipo de promoción (para compatibilidad)
  String get tipoPromocion {
    return categoria.toLowerCase();
  }

  // Verificar si está activa (autorizada y para alumnos)
  bool get activa {
    return autorizado && destinatario.toLowerCase() == 'alumno';
  }

  // Getter para icono según el tipo
  String get iconoTipo {
    switch (categoria.toLowerCase()) {
      case 'promoción':
      case 'promocion':
        return '🏥';
      case 'prevención':
      case 'prevencion':
        return '🛡️';
      case 'urgente':
        return '🚨';
      default:
        return '📋';
    }
  }

  // Para compatibilidad con el código existente
  bool get haExpirado => false; // Las promociones de SASU no expiran automáticamente
  
  int get diasRestantes => 30; // Valor por defecto para compatibilidad
}