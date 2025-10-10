const { body, param, query, validationResult } = require('express-validator');

/**
 * Middleware de validación para el sistema de promociones SASU
 * Utiliza express-validator para validar datos de entrada
 */
class ValidationMiddleware {
  
  /**
   * Maneja los errores de validación y devuelve respuesta formateada
   */
  handleValidationErrors(req, res, next) {
    const errors = validationResult(req);
    
    if (!errors.isEmpty()) {
      const formattedErrors = errors.array().map(error => ({
        field: error.path || error.param,
        message: error.msg,
        value: error.value,
        location: error.location
      }));
      
      console.log(`[Validation] Errores de validación en ${req.originalUrl}:`, formattedErrors);
      
      return res.status(400).json({
        success: false,
        error: 'Datos de entrada inválidos',
        message: 'Los datos proporcionados no cumplen con los requisitos',
        validation_errors: formattedErrors
      });
    }
    
    next();
  }
  
  /**
   * Validaciones para GET /me/promociones
   */
  get validatePromocionesMeQuery() {
    return [
      query('incluir_vencidas')
        .optional()
        .isBoolean()
        .withMessage('incluir_vencidas debe ser true o false'),
      
      query('limite')
        .optional()
        .isInt({ min: 1, max: 100 })
        .withMessage('limite debe ser un número entre 1 y 100'),
      
      query('categoria_id')
        .optional()
        .isInt({ min: 1 })
        .withMessage('categoria_id debe ser un número entero positivo'),
      
      query('departamento_id')
        .optional()
        .isInt({ min: 1 })
        .withMessage('departamento_id debe ser un número entero positivo'),
      
      this.handleValidationErrors
    ];
  }
  
  /**
   * Validación para parámetros de límite
   */
  get validateLimiteQuery() {
    return [
      query('limite')
        .optional()
        .isInt({ min: 1, max: 20 })
        .withMessage('limite debe ser un número entre 1 y 20'),
      
      this.handleValidationErrors
    ];
  }
  
  /**
   * Validación para ID de promoción en parámetros
   */
  get validatePromocionId() {
    return [
      param('promocion_id')
        .isInt({ min: 1 })
        .withMessage('promocion_id debe ser un número entero positivo'),
      
      this.handleValidationErrors
    ];
  }
  
  /**
   * Validaciones para crear nueva promoción
   */
  get validateCreatePromocion() {
    return [
      body('titulo')
        .trim()
        .notEmpty()
        .withMessage('título es obligatorio')
        .isLength({ min: 5, max: 255 })
        .withMessage('título debe tener entre 5 y 255 caracteres'),
      
      body('descripcion')
        .trim()
        .notEmpty()
        .withMessage('descripción es obligatoria')
        .isLength({ min: 10, max: 5000 })
        .withMessage('descripción debe tener entre 10 y 5000 caracteres'),
      
      body('resumen')
        .optional()
        .trim()
        .isLength({ max: 500 })
        .withMessage('resumen no puede exceder 500 caracteres'),
      
      body('link')
        .optional()
        .trim()
        .isURL({ protocols: ['http', 'https'], require_protocol: true })
        .withMessage('link debe ser una URL válida (http/https)'),
      
      body('imagen_url')
        .optional()
        .trim()
        .isURL({ protocols: ['http', 'https'], require_protocol: true })
        .withMessage('imagen_url debe ser una URL válida (http/https)'),
      
      body('categoria_id')
        .isInt({ min: 1 })
        .withMessage('categoria_id es obligatorio y debe ser un número entero positivo'),
      
      body('departamento_id')
        .isInt({ min: 1 })
        .withMessage('departamento_id es obligatorio y debe ser un número entero positivo'),
      
      body('matricula_target')
        .optional()
        .trim()
        .isLength({ min: 1, max: 20 })
        .withMessage('matricula_target debe tener entre 1 y 20 caracteres'),
      
      body('carrera_target')
        .optional()
        .trim()
        .isLength({ max: 100 })
        .withMessage('carrera_target no puede exceder 100 caracteres'),
      
      body('semestre_target')
        .optional()
        .isInt({ min: 1, max: 12 })
        .withMessage('semestre_target debe ser un número entre 1 y 12'),
      
      body('fecha_inicio')
        .isISO8601()
        .toDate()
        .withMessage('fecha_inicio debe ser una fecha válida (YYYY-MM-DD)')
        .custom((value) => {
          const hoy = new Date();
          hoy.setHours(0, 0, 0, 0);
          if (value < hoy) {
            throw new Error('fecha_inicio no puede ser anterior a hoy');
          }
          return true;
        }),
      
      body('fecha_fin')
        .isISO8601()
        .toDate()
        .withMessage('fecha_fin debe ser una fecha válida (YYYY-MM-DD)')
        .custom((value, { req }) => {
          if (value <= req.body.fecha_inicio) {
            throw new Error('fecha_fin debe ser posterior a fecha_inicio');
          }
          return true;
        }),
      
      body('destacado')
        .optional()
        .isBoolean()
        .withMessage('destacado debe ser true o false'),
      
      body('urgente')
        .optional()
        .isBoolean()
        .withMessage('urgente debe ser true o false'),
      
      body('prioridad')
        .optional()
        .isInt({ min: 1, max: 10 })
        .withMessage('prioridad debe ser un número entre 1 y 10'),
      
      this.handleValidationErrors
    ];
  }
  
  /**
   * Validaciones para actualizar promoción
   */
  get validateUpdatePromocion() {
    return [
      body('titulo')
        .optional()
        .trim()
        .isLength({ min: 5, max: 255 })
        .withMessage('título debe tener entre 5 y 255 caracteres'),
      
      body('descripcion')
        .optional()
        .trim()
        .isLength({ min: 10, max: 5000 })
        .withMessage('descripción debe tener entre 10 y 5000 caracteres'),
      
      body('resumen')
        .optional()
        .trim()
        .isLength({ max: 500 })
        .withMessage('resumen no puede exceder 500 caracteres'),
      
      body('link')
        .optional()
        .trim()
        .custom((value) => {
          if (value === '' || value === null) return true; // Permitir vacío
          if (!value.match(/^https?:\/\/.+/)) {
            throw new Error('link debe ser una URL válida (http/https)');
          }
          return true;
        }),
      
      body('imagen_url')
        .optional()
        .trim()
        .custom((value) => {
          if (value === '' || value === null) return true; // Permitir vacío
          if (!value.match(/^https?:\/\/.+/)) {
            throw new Error('imagen_url debe ser una URL válida (http/https)');
          }
          return true;
        }),
      
      body('categoria_id')
        .optional()
        .isInt({ min: 1 })
        .withMessage('categoria_id debe ser un número entero positivo'),
      
      body('departamento_id')
        .optional()
        .isInt({ min: 1 })
        .withMessage('departamento_id debe ser un número entero positivo'),
      
      body('matricula_target')
        .optional()
        .trim()
        .custom((value) => {
          if (value === '' || value === null) return true; // Permitir vacío
          if (value.length > 20) {
            throw new Error('matricula_target no puede exceder 20 caracteres');
          }
          return true;
        }),
      
      body('carrera_target')
        .optional()
        .trim()
        .isLength({ max: 100 })
        .withMessage('carrera_target no puede exceder 100 caracteres'),
      
      body('semestre_target')
        .optional()
        .custom((value) => {
          if (value === null || value === '') return true; // Permitir vacío
          if (!Number.isInteger(Number(value)) || value < 1 || value > 12) {
            throw new Error('semestre_target debe ser un número entre 1 y 12');
          }
          return true;
        }),
      
      body('fecha_inicio')
        .optional()
        .isISO8601()
        .toDate()
        .withMessage('fecha_inicio debe ser una fecha válida (YYYY-MM-DD)'),
      
      body('fecha_fin')
        .optional()
        .isISO8601()
        .toDate()
        .withMessage('fecha_fin debe ser una fecha válida (YYYY-MM-DD)')
        .custom((value, { req }) => {
          if (req.body.fecha_inicio && value <= new Date(req.body.fecha_inicio)) {
            throw new Error('fecha_fin debe ser posterior a fecha_inicio');
          }
          return true;
        }),
      
      body('activo')
        .optional()
        .isBoolean()
        .withMessage('activo debe ser true o false'),
      
      body('destacado')
        .optional()
        .isBoolean()
        .withMessage('destacado debe ser true o false'),
      
      body('urgente')
        .optional()
        .isBoolean()
        .withMessage('urgente debe ser true o false'),
      
      body('prioridad')
        .optional()
        .isInt({ min: 1, max: 10 })
        .withMessage('prioridad debe ser un número entre 1 y 10'),
      
      this.handleValidationErrors
    ];
  }
  
  /**
   * Validaciones para listar promociones (admin)
   */
  get validateAdminPromocionesList() {
    return [
      query('activo')
        .optional()
        .isBoolean()
        .withMessage('activo debe ser true o false'),
      
      query('categoria_id')
        .optional()
        .isInt({ min: 1 })
        .withMessage('categoria_id debe ser un número entero positivo'),
      
      query('departamento_id')
        .optional()
        .isInt({ min: 1 })
        .withMessage('departamento_id debe ser un número entero positivo'),
      
      query('fecha_desde')
        .optional()
        .isISO8601()
        .withMessage('fecha_desde debe ser una fecha válida (YYYY-MM-DD)'),
      
      query('fecha_hasta')
        .optional()
        .isISO8601()
        .withMessage('fecha_hasta debe ser una fecha válida (YYYY-MM-DD)')
        .custom((value, { req }) => {
          if (req.query.fecha_desde && value <= req.query.fecha_desde) {
            throw new Error('fecha_hasta debe ser posterior a fecha_desde');
          }
          return true;
        }),
      
      query('matricula_target')
        .optional()
        .trim()
        .isLength({ min: 1, max: 20 })
        .withMessage('matricula_target debe tener entre 1 y 20 caracteres'),
      
      query('page')
        .optional()
        .isInt({ min: 1 })
        .withMessage('page debe ser un número entero positivo'),
      
      query('limit')
        .optional()
        .isInt({ min: 1, max: 200 })
        .withMessage('limit debe ser un número entre 1 y 200'),
      
      query('order_by')
        .optional()
        .isIn(['id', 'titulo', 'created_at', 'updated_at', 'fecha_inicio', 'fecha_fin', 'prioridad'])
        .withMessage('order_by debe ser uno de: id, titulo, created_at, updated_at, fecha_inicio, fecha_fin, prioridad'),
      
      query('order_direction')
        .optional()
        .isIn(['ASC', 'DESC'])
        .withMessage('order_direction debe ser ASC o DESC'),
      
      this.handleValidationErrors
    ];
  }
  
  /**
   * Sanitización de entrada para prevenir XSS y injection
   */
  sanitizeInput(req, res, next) {
    // Sanitizar strings en body
    if (req.body) {
      Object.keys(req.body).forEach(key => {
        if (typeof req.body[key] === 'string') {
          // Trim whitespace
          req.body[key] = req.body[key].trim();
          
          // Escapar caracteres peligrosos básicos
          req.body[key] = req.body[key]
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#x27;')
            .replace(/\//g, '&#x2F;');
        }
      });
    }
    
    // Sanitizar query params
    if (req.query) {
      Object.keys(req.query).forEach(key => {
        if (typeof req.query[key] === 'string') {
          req.query[key] = req.query[key].trim();
        }
      });
    }
    
    next();
  }
  
  /**
   * Validación específica para archivos de imagen
   */
  validateImageFile(req, res, next) {
    if (!req.files || !req.files.imagen) {
      return next(); // No hay archivo, continuar
    }
    
    const imagen = req.files.imagen;
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    const maxSize = 5 * 1024 * 1024; // 5MB
    
    if (!allowedTypes.includes(imagen.mimetype)) {
      return res.status(400).json({
        success: false,
        error: 'Tipo de archivo inválido',
        message: 'Solo se permiten imágenes JPEG, PNG, GIF y WebP',
        allowed_types: allowedTypes
      });
    }
    
    if (imagen.size > maxSize) {
      return res.status(400).json({
        success: false,
        error: 'Archivo demasiado grande',
        message: 'La imagen no puede exceder 5MB',
        max_size: '5MB',
        received_size: `${Math.round(imagen.size / 1024 / 1024 * 100) / 100}MB`
      });
    }
    
    next();
  }
  
  /**
   * Validación de rango de fechas
   */
  validateDateRange(req, res, next) {
    const { fecha_inicio, fecha_fin } = req.body;
    
    if (fecha_inicio && fecha_fin) {
      const inicio = new Date(fecha_inicio);
      const fin = new Date(fecha_fin);
      const hoy = new Date();
      
      // Validar que las fechas no sean muy lejanas
      const unAnoEnMs = 365 * 24 * 60 * 60 * 1000;
      const dosAnosEnFuturo = new Date(hoy.getTime() + (2 * unAnoEnMs));
      
      if (fin > dosAnosEnFuturo) {
        return res.status(400).json({
          success: false,
          error: 'Fecha demasiado lejana',
          message: 'La fecha de fin no puede ser más de 2 años en el futuro'
        });
      }
      
      // Validar duración mínima y máxima
      const duracionMs = fin.getTime() - inicio.getTime();
      const unDiaEnMs = 24 * 60 * 60 * 1000;
      
      if (duracionMs < unDiaEnMs) {
        return res.status(400).json({
          success: false,
          error: 'Duración inválida',
          message: 'La promoción debe durar al menos 1 día'
        });
      }
    }
    
    next();
  }
}

module.exports = new ValidationMiddleware();