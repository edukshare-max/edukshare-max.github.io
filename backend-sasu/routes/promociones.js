const express = require('express');
const PromocionesController = require('../controllers/PromocionesCosmosController');
const authMiddleware = require('../middleware/authMiddleware');
const adminMiddleware = require('../middleware/adminMiddleware');
const rateLimitMiddleware = require('../middleware/rateLimitMiddleware');
const validationMiddleware = require('../middleware/validationMiddleware');

const router = express.Router();

/**
 * Rutas para el sistema de Promociones de Salud
 * Sistema SASU - Universidad Autónoma de Guerrero
 * 
 * Estructura de rutas:
 * - /me/promociones - Endpoints para estudiantes autenticados
 * - /admin/promociones - Endpoints administrativos
 * - /public/promociones - Endpoints públicos (metadatos)
 */

// ============================================
// MIDDLEWARE GLOBALES
// ============================================

// Aplicar rate limiting a todas las rutas de promociones
router.use(rateLimitMiddleware.promociones);

// Middleware de logging para debugging
router.use((req, res, next) => {
  console.log(`[Promociones API] ${req.method} ${req.originalUrl} - IP: ${req.ip} - User-Agent: ${req.get('User-Agent')?.substring(0, 100)}`);
  next();
});

// ============================================
// RUTAS PARA ESTUDIANTES (/me/promociones)
// ============================================

/**
 * GET /me/promociones
 * Obtiene todas las promociones activas para el estudiante autenticado
 * Requiere: Autenticación JWT válida
 * Query params opcionales:
 * - incluir_vencidas: boolean (default: false)
 * - limite: number (default: 20, max: 100)
 * - categoria_id: number
 * - departamento_id: number
 */
router.get('/me/promociones', 
  authMiddleware.verifyToken,
  validationMiddleware.validatePromocionesMeQuery,
  PromocionesController.getPromocionesByMatricula
);

/**
 * GET /me/promociones/destacadas
 * Obtiene promociones destacadas para el carrusel principal
 * Requiere: Autenticación JWT válida
 * Query params opcionales:
 * - limite: number (default: 10, max: 20)
 */
router.get('/me/promociones/destacadas',
  authMiddleware.verifyToken,
  validationMiddleware.validateLimiteQuery,
  PromocionesController.getPromocionesDestacadas
);

/**
 * POST /me/promociones/:promocion_id/click
 * Registra un click en una promoción específica
 * Requiere: Autenticación JWT válida
 * Params: promocion_id (number)
 */
router.post('/me/promociones/:promocion_id/click',
  authMiddleware.verifyToken,
  validationMiddleware.validatePromocionId,
  rateLimitMiddleware.clicks, // Rate limiting específico para clicks
  PromocionesController.registrarClick
);

/**
 * GET /me/promociones/:promocion_id/estadisticas
 * Obtiene estadísticas básicas de una promoción
 * Requiere: Autenticación JWT válida
 * Params: promocion_id (number)
 */
router.get('/me/promociones/:promocion_id/estadisticas',
  authMiddleware.verifyToken,
  validationMiddleware.validatePromocionId,
  PromocionesController.getEstadisticasPromocion
);

// ============================================
// RUTAS ADMINISTRATIVAS (/admin/promociones)
// ============================================

/**
 * GET /admin/promociones
 * Lista todas las promociones con filtros avanzados
 * Requiere: Autenticación JWT + permisos de administrador
 * Query params opcionales:
 * - activo: boolean
 * - categoria_id: number
 * - departamento_id: number
 * - fecha_desde: date (YYYY-MM-DD)
 * - fecha_hasta: date (YYYY-MM-DD)
 * - matricula_target: string
 * - page: number (default: 1)
 * - limit: number (default: 50, max: 200)
 * - order_by: string (default: created_at)
 * - order_direction: ASC|DESC (default: DESC)
 */
router.get('/admin/promociones',
  authMiddleware.verifyToken,
  adminMiddleware.requireAdmin,
  validationMiddleware.validateAdminPromocionesList,
  PromocionesController.getAllPromociones
);

/**
 * POST /admin/promociones
 * Crea una nueva promoción
 * Requiere: Autenticación JWT + permisos de administrador
 * Body: Objeto PromocionSalud (ver schema de validación)
 */
router.post('/admin/promociones',
  authMiddleware.verifyToken,
  adminMiddleware.requireAdmin,
  validationMiddleware.validateCreatePromocion,
  PromocionesController.createPromocion
);

/**
 * GET /admin/promociones/:promocion_id
 * Obtiene una promoción específica con todos los detalles
 * Requiere: Autenticación JWT + permisos de administrador
 * Params: promocion_id (number)
 */
router.get('/admin/promociones/:promocion_id',
  authMiddleware.verifyToken,
  adminMiddleware.requireAdmin,
  validationMiddleware.validatePromocionId,
  async (req, res) => {
    try {
      const { promocion_id } = req.params;
      const { PromocionSalud, CategoriaPromocion, DepartamentoSalud } = require('../models/PromocionSalud');
      
      const promocion = await PromocionSalud.findByPk(promocion_id, {
        include: [
          { model: CategoriaPromocion, as: 'categoria' },
          { model: DepartamentoSalud, as: 'departamento' }
        ]
      });
      
      if (!promocion) {
        return res.status(404).json({
          success: false,
          error: 'Promoción no encontrada'
        });
      }
      
      res.json({
        success: true,
        data: promocion
      });
      
    } catch (error) {
      console.error('[Promociones API] Error obteniendo promoción:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }
);

/**
 * PUT /admin/promociones/:promocion_id
 * Actualiza una promoción existente
 * Requiere: Autenticación JWT + permisos de administrador
 * Params: promocion_id (number)
 * Body: Objeto con campos a actualizar
 */
router.put('/admin/promociones/:promocion_id',
  authMiddleware.verifyToken,
  adminMiddleware.requireAdmin,
  validationMiddleware.validatePromocionId,
  validationMiddleware.validateUpdatePromocion,
  PromocionesController.updatePromocion
);

/**
 * DELETE /admin/promociones/:promocion_id
 * Elimina (desactiva) una promoción
 * Requiere: Autenticación JWT + permisos de administrador
 * Params: promocion_id (number)
 * Query params opcionales:
 * - eliminar_permanente: boolean (default: false)
 */
router.delete('/admin/promociones/:promocion_id',
  authMiddleware.verifyToken,
  adminMiddleware.requireAdmin,
  validationMiddleware.validatePromocionId,
  PromocionesController.deletePromocion
);

// ============================================
// RUTAS PÚBLICAS (/public/promociones)
// ============================================

/**
 * GET /public/promociones/categorias
 * Obtiene todas las categorías activas
 * No requiere autenticación
 */
router.get('/public/promociones/categorias',
  rateLimitMiddleware.publicEndpoints,
  PromocionesController.getCategorias
);

/**
 * GET /public/promociones/departamentos
 * Obtiene todos los departamentos activos
 * No requiere autenticación
 */
router.get('/public/promociones/departamentos',
  rateLimitMiddleware.publicEndpoints,
  PromocionesController.getDepartamentos
);

/**
 * GET /public/promociones/stats
 * Obtiene estadísticas generales del sistema de promociones
 * No requiere autenticación
 */
router.get('/public/promociones/stats',
  rateLimitMiddleware.publicEndpoints,
  async (req, res) => {
    try {
      const { PromocionSalud, CategoriaPromocion, DepartamentoSalud } = require('../models/PromocionSalud');
      const { Op } = require('sequelize');
      
      const hoy = new Date();
      
      const [
        totalPromociones,
        promocionesActivas,
        promocionesDestacadas,
        totalCategorias,
        totalDepartamentos
      ] = await Promise.all([
        PromocionSalud.count(),
        PromocionSalud.count({
          where: {
            activo: true,
            fecha_inicio: { [Op.lte]: hoy },
            fecha_fin: { [Op.gte]: hoy }
          }
        }),
        PromocionSalud.count({
          where: {
            activo: true,
            destacado: true,
            fecha_inicio: { [Op.lte]: hoy },
            fecha_fin: { [Op.gte]: hoy }
          }
        }),
        CategoriaPromocion.count({ where: { activo: true } }),
        DepartamentoSalud.count({ where: { activo: true } })
      ]);
      
      res.json({
        success: true,
        data: {
          total_promociones: totalPromociones,
          promociones_activas: promocionesActivas,
          promociones_destacadas: promocionesDestacadas,
          total_categorias: totalCategorias,
          total_departamentos: totalDepartamentos,
          ultima_actualizacion: new Date().toISOString()
        }
      });
      
    } catch (error) {
      console.error('[Promociones API] Error obteniendo estadísticas:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }
);

// ============================================
// MIDDLEWARE DE MANEJO DE ERRORES
// ============================================

// Manejo de errores 404 para rutas no encontradas
router.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint no encontrado',
    message: `La ruta ${req.method} ${req.originalUrl} no existe`,
    endpoints_disponibles: {
      estudiantes: [
        'GET /me/promociones',
        'GET /me/promociones/destacadas',
        'POST /me/promociones/:id/click',
        'GET /me/promociones/:id/estadisticas'
      ],
      administradores: [
        'GET /admin/promociones',
        'POST /admin/promociones',
        'GET /admin/promociones/:id',
        'PUT /admin/promociones/:id',
        'DELETE /admin/promociones/:id'
      ],
      publicos: [
        'GET /public/promociones/categorias',
        'GET /public/promociones/departamentos',
        'GET /public/promociones/stats'
      ]
    }
  });
});

// Middleware global de manejo de errores
router.use((error, req, res, next) => {
  console.error('[Promociones API] Error no manejado:', error);
  
  // Error de validación de Sequelize
  if (error.name === 'SequelizeValidationError') {
    return res.status(400).json({
      success: false,
      error: 'Error de validación',
      message: 'Los datos proporcionados no son válidos',
      details: error.errors?.map(e => ({
        field: e.path,
        message: e.message,
        value: e.value
      }))
    });
  }
  
  // Error de constraint de base de datos
  if (error.name === 'SequelizeForeignKeyConstraintError') {
    return res.status(400).json({
      success: false,
      error: 'Error de referencia',
      message: 'La referencia especificada no existe o no es válida'
    });
  }
  
  // Error de token JWT
  if (error.name === 'JsonWebTokenError') {
    return res.status(401).json({
      success: false,
      error: 'Token inválido',
      message: 'El token de autenticación no es válido'
    });
  }
  
  // Error genérico
  res.status(500).json({
    success: false,
    error: 'Error interno del servidor',
    message: 'Ocurrió un error inesperado',
    details: process.env.NODE_ENV === 'development' ? error.message : undefined
  });
});

module.exports = router;