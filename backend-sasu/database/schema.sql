-- ============================================
-- ESQUEMA DE BASE DE DATOS PARA PROMOCIONES DE SALUD
-- Sistema SASU - Universidad Autónoma de Guerrero
-- ============================================

-- Tabla para categorías de promociones
CREATE TABLE IF NOT EXISTS categorias_promociones (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    color_hex VARCHAR(7) DEFAULT '#4F46E5',
    icono VARCHAR(50) DEFAULT '🏥',
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabla para departamentos de salud
CREATE TABLE IF NOT EXISTS departamentos_salud (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    descripcion TEXT,
    contacto_email VARCHAR(255),
    contacto_telefono VARCHAR(20),
    ubicacion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabla principal de promociones de salud
CREATE TABLE IF NOT EXISTS promociones_salud (
    id INT PRIMARY KEY AUTO_INCREMENT,
    titulo VARCHAR(255) NOT NULL,
    descripcion TEXT NOT NULL,
    resumen VARCHAR(500),
    link VARCHAR(500),
    imagen_url VARCHAR(500),
    
    -- Relaciones
    categoria_id INT NOT NULL,
    departamento_id INT NOT NULL,
    
    -- Targeting y filtros
    matricula_target VARCHAR(20) NULL, -- NULL = para todos los estudiantes
    carrera_target VARCHAR(100) NULL,  -- NULL = para todas las carreras
    semestre_target INT NULL,          -- NULL = para todos los semestres
    
    -- Control de fechas
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    fecha_publicacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Estados
    activo BOOLEAN DEFAULT TRUE,
    destacado BOOLEAN DEFAULT FALSE,
    urgente BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    vistas INT DEFAULT 0,
    clicks INT DEFAULT 0,
    prioridad INT DEFAULT 5, -- 1-10, 10 = máxima prioridad
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Índices y constraints
    INDEX idx_activo_fechas (activo, fecha_inicio, fecha_fin),
    INDEX idx_matricula_target (matricula_target),
    INDEX idx_categoria (categoria_id),
    INDEX idx_departamento (departamento_id),
    INDEX idx_prioridad (prioridad DESC),
    INDEX idx_destacado (destacado, activo),
    
    FOREIGN KEY (categoria_id) REFERENCES categorias_promociones(id) ON DELETE RESTRICT,
    FOREIGN KEY (departamento_id) REFERENCES departamentos_salud(id) ON DELETE RESTRICT,
    
    -- Validaciones
    CONSTRAINT chk_fechas CHECK (fecha_fin >= fecha_inicio),
    CONSTRAINT chk_prioridad CHECK (prioridad BETWEEN 1 AND 10)
);

-- Tabla para tracking de interacciones
CREATE TABLE IF NOT EXISTS promociones_interacciones (
    id INT PRIMARY KEY AUTO_INCREMENT,
    promocion_id INT NOT NULL,
    matricula VARCHAR(20) NOT NULL,
    tipo_interaccion ENUM('vista', 'click', 'compartir') NOT NULL,
    user_agent TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_promocion_matricula (promocion_id, matricula),
    INDEX idx_matricula_fecha (matricula, created_at),
    
    FOREIGN KEY (promocion_id) REFERENCES promociones_salud(id) ON DELETE CASCADE
);

-- ============================================
-- DATOS INICIALES
-- ============================================

-- Insertar categorías predefinidas
INSERT INTO categorias_promociones (nombre, descripcion, color_hex, icono) VALUES
('Consulta Médica', 'Servicios médicos generales y especialidades', '#3B82F6', '🏥'),
('Prevención', 'Programas de prevención y salud pública', '#10B981', '🛡️'),
('Emergencia', 'Servicios de urgencias y emergencias médicas', '#EF4444', '🚨'),
('Salud Mental', 'Apoyo psicológico y bienestar emocional', '#8B5CF6', '🧠'),
('Nutrición', 'Programas de alimentación y nutrición', '#F59E0B', '🥗'),
('Deportes', 'Actividades físicas y medicina deportiva', '#06B6D4', '⚽'),
('Información', 'Recursos informativos y educativos', '#6B7280', '📱');

-- Insertar departamentos
INSERT INTO departamentos_salud (nombre, descripcion, contacto_email, contacto_telefono, ubicacion) VALUES
('Consultorio Médico General', 'Atención médica primaria para estudiantes', 'medico@uagro.mx', '+52 744 445 1100', 'Edificio Central, Planta Baja'),
('Servicios Psicológicos', 'Apoyo psicológico y counseling estudiantil', 'psicologia@uagro.mx', '+52 744 445 1101', 'Centro de Bienestar Estudiantil'),
('Departamento de Nutrición', 'Programas de alimentación saludable', 'nutricion@uagro.mx', '+52 744 445 1102', 'Cafetería Central'),
('Medicina Deportiva', 'Atención médica para deportistas', 'deportes@uagro.mx', '+52 744 445 1103', 'Centro Deportivo UAGro'),
('Servicios de Emergencia', 'Atención de urgencias 24/7', 'emergencias@uagro.mx', '+52 744 445 1104', 'Clínica Universitaria'),
('Promoción de la Salud', 'Campañas educativas y preventivas', 'promocion@uagro.mx', '+52 744 445 1105', 'Rectoría, 2do Piso');

-- ============================================
-- PROMOCIONES DE EJEMPLO PARA MATRÍCULA 15662
-- ============================================

INSERT INTO promociones_salud (
    titulo, descripcion, resumen, link, imagen_url,
    categoria_id, departamento_id,
    matricula_target, fecha_inicio, fecha_fin,
    activo, destacado, prioridad
) VALUES 

-- Promoción específica para 15662
(
    'Consulta Médica Especializada - Estudiante 15662',
    'Estimado estudiante con matrícula 15662, tienes una consulta médica programada con el Dr. Martinez. Esta cita incluye revisión general, análisis de laboratorio pendientes y seguimiento de tu expediente médico. Es importante que asistas puntualmente y traigas tu carnet estudiantil.',
    'Consulta médica programada con el Dr. Martinez - Trae tu carnet estudiantil',
    'https://citas.uagro.mx/consulta/15662/dr-martinez',
    'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400',
    1, 1, -- Consulta Médica, Consultorio Médico General
    '15662', 
    CURDATE(), 
    DATE_ADD(CURDATE(), INTERVAL 30 DAY),
    TRUE, TRUE, 10
),

-- Promoción de prevención específica
(
    'Campaña de Vacunación - Registro Abierto',
    'La Universidad Autónoma de Guerrero invita a todos los estudiantes a participar en la campaña de vacunación contra la influenza estacional. El proceso es gratuito y se realizará en el consultorio médico. Estudiante 15662, tu registro está confirmado para el próximo lunes.',
    'Campaña de vacunación gratuita - Registro confirmado',
    'https://vacunacion.uagro.mx/registro/15662',
    'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=400',
    2, 6, -- Prevención, Promoción de la Salud
    '15662',
    CURDATE(),
    DATE_ADD(CURDATE(), INTERVAL 15 DAY),
    TRUE, TRUE, 9
),

-- Promoción general que aplica a 15662
(
    'Servicio de Nutrición - Evaluación Gratuita',
    'El Departamento de Nutrición ofrece evaluaciones nutricionales gratuitas para todos los estudiantes. Incluye análisis de composición corporal, plan alimentario personalizado y seguimiento mensual. Ideal para estudiantes que buscan mejorar su rendimiento académico a través de una mejor alimentación.',
    'Evaluación nutricional gratuita con plan personalizado',
    'https://nutricion.uagro.mx/evaluacion',
    'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400',
    5, 3, -- Nutrición, Departamento de Nutrición
    NULL, -- Aplica a todos los estudiantes
    CURDATE(),
    DATE_ADD(CURDATE(), INTERVAL 60 DAY),
    TRUE, FALSE, 7
),

-- Promoción de salud mental
(
    'Apoyo Psicológico - Sesiones Individuales',
    'Los Servicios Psicológicos de la UAGro ofrecen sesiones individuales de apoyo emocional y counseling académico. Nuestros psicólogos certificados brindan un espacio seguro y confidencial para estudiantes que enfrentan estrés, ansiedad o dificultades de adaptación universitaria.',
    'Sesiones de apoyo psicológico confidenciales y gratuitas',
    'https://psicologia.uagro.mx/citas',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400',
    4, 2, -- Salud Mental, Servicios Psicológicos
    NULL,
    CURDATE(),
    DATE_ADD(CURDATE(), INTERVAL 90 DAY),
    TRUE, FALSE, 8
),

-- Promoción de información urgente
(
    'Actualización de Expediente Médico - Acción Requerida',
    'Es importante mantener actualizado tu expediente médico universitario. Estudiantes que no han completado su información médica en los últimos 2 años deben agendar una cita para actualización. Esto es obligatorio para participar en actividades deportivas y viajes académicos.',
    'Actualización obligatoria de expediente médico',
    'https://expedientes.uagro.mx/actualizacion',
    'https://images.unsplash.com/photo-1504813184591-01572f98c85f?w=400',
    7, 1, -- Información, Consultorio Médico General
    NULL,
    CURDATE(),
    DATE_ADD(CURDATE(), INTERVAL 45 DAY),
    TRUE, FALSE, 6
);

-- ============================================
-- VISTAS PARA CONSULTAS OPTIMIZADAS
-- ============================================

-- Vista para promociones activas con información completa
CREATE VIEW v_promociones_activas AS
SELECT 
    p.id,
    p.titulo,
    p.descripcion,
    p.resumen,
    p.link,
    p.imagen_url,
    p.matricula_target,
    p.carrera_target,
    p.semestre_target,
    p.fecha_inicio,
    p.fecha_fin,
    p.destacado,
    p.urgente,
    p.vistas,
    p.clicks,
    p.prioridad,
    c.nombre AS categoria,
    c.color_hex AS categoria_color,
    c.icono AS categoria_icono,
    d.nombre AS departamento,
    d.contacto_email AS departamento_email,
    d.contacto_telefono AS departamento_telefono,
    p.created_at,
    p.updated_at
FROM promociones_salud p
JOIN categorias_promociones c ON p.categoria_id = c.id
JOIN departamentos_salud d ON p.departamento_id = d.id
WHERE p.activo = TRUE 
  AND c.activo = TRUE 
  AND d.activo = TRUE
  AND p.fecha_inicio <= CURDATE() 
  AND p.fecha_fin >= CURDATE();

-- Vista para promociones por matrícula
CREATE VIEW v_promociones_por_matricula AS
SELECT 
    v.*,
    CASE 
        WHEN v.matricula_target IS NOT NULL THEN 'específica'
        ELSE 'general'
    END AS tipo_promocion
FROM v_promociones_activas v;

-- ============================================
-- STORED PROCEDURES
-- ============================================

DELIMITER //

-- Procedure para obtener promociones de un estudiante
CREATE PROCEDURE GetPromocionesByMatricula(IN p_matricula VARCHAR(20))
BEGIN
    SELECT *
    FROM v_promociones_por_matricula
    WHERE matricula_target IS NULL 
       OR matricula_target = p_matricula
    ORDER BY 
        urgente DESC,
        destacado DESC,
        prioridad DESC,
        created_at DESC;
END //

-- Procedure para registrar interacción
CREATE PROCEDURE RegistrarInteraccion(
    IN p_promocion_id INT,
    IN p_matricula VARCHAR(20),
    IN p_tipo_interaccion VARCHAR(20),
    IN p_user_agent TEXT,
    IN p_ip_address VARCHAR(45)
)
BEGIN
    INSERT INTO promociones_interacciones 
    (promocion_id, matricula, tipo_interaccion, user_agent, ip_address)
    VALUES (p_promocion_id, p_matricula, p_tipo_interaccion, p_user_agent, p_ip_address);
    
    -- Actualizar contador en la promoción
    IF p_tipo_interaccion = 'vista' THEN
        UPDATE promociones_salud 
        SET vistas = vistas + 1 
        WHERE id = p_promocion_id;
    ELSEIF p_tipo_interaccion = 'click' THEN
        UPDATE promociones_salud 
        SET clicks = clicks + 1 
        WHERE id = p_promocion_id;
    END IF;
END //

DELIMITER ;

-- ============================================
-- ÍNDICES ADICIONALES PARA RENDIMIENTO
-- ============================================

CREATE INDEX idx_promociones_fecha_activo ON promociones_salud(fecha_inicio, fecha_fin, activo);
CREATE INDEX idx_promociones_target ON promociones_salud(matricula_target, carrera_target, activo);
CREATE INDEX idx_interacciones_stats ON promociones_interacciones(promocion_id, tipo_interaccion, created_at);