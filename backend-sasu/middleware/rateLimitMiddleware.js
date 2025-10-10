const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');
const redis = require('redis');

/**
 * Middleware de rate limiting para diferentes endpoints
 * Sistema SASU - Control de uso de API
 */
class RateLimitMiddleware {
  
  constructor() {
    // Configurar Redis si está disponible (opcional)
    this.redisClient = null;
    this.initRedis();
  }
  
  async initRedis() {
    try {
      if (process.env.REDIS_URL || process.env.REDIS_HOST) {
        this.redisClient = redis.createClient({
          url: process.env.REDIS_URL || `redis://${process.env.REDIS_HOST || 'localhost'}:${process.env.REDIS_PORT || 6379}`
        });
        
        await this.redisClient.connect();
        console.log('[RateLimit] Redis conectado para rate limiting');
      }
    } catch (error) {
      console.log('[RateLimit] Redis no disponible, usando memoria local');
      this.redisClient = null;
    }
  }
  
  /**
   * Crea store para rate limiting (Redis o memoria)
   */
  createStore() {
    if (this.redisClient) {
      return new RedisStore({
        sendCommand: (...args) => this.redisClient.sendCommand(args),
      });
    }
    return undefined; // Usar store en memoria por defecto
  }
  
  /**
   * Rate limiting general para promociones
   * 100 requests por 15 minutos por IP
   */
  get promociones() {
    return rateLimit({
      windowMs: 15 * 60 * 1000, // 15 minutos
      max: 100, // 100 requests por ventana
      store: this.createStore(),
      message: {
        success: false,
        error: 'Demasiadas solicitudes',
        message: 'Has excedido el límite de solicitudes. Intenta de nuevo en 15 minutos.',
        retry_after: '15 minutos'
      },
      standardHeaders: true,
      legacyHeaders: false,
      // Excluir del rate limiting a super admins
      skip: (req) => {
        return req.user?.rol === 'super_admin';
      },
      keyGenerator: (req) => {
        // Rate limit por IP + usuario si está autenticado
        if (req.user?.matricula) {
          return `promociones:${req.ip}:${req.user.matricula}`;
        }
        return `promociones:${req.ip}`;
      }
    });
  }
  
  /**
   * Rate limiting específico para clicks
   * 20 clicks por minuto por usuario
   */
  get clicks() {
    return rateLimit({
      windowMs: 60 * 1000, // 1 minuto
      max: 20, // 20 clicks por minuto
      store: this.createStore(),
      message: {
        success: false,
        error: 'Demasiados clicks',
        message: 'Has hecho demasiados clicks muy rápido. Espera un momento.',
        retry_after: '1 minuto'
      },
      standardHeaders: true,
      legacyHeaders: false,
      keyGenerator: (req) => {
        // Rate limit por usuario autenticado
        if (req.user?.matricula) {
          return `clicks:${req.user.matricula}`;
        }
        return `clicks:${req.ip}`;
      }
    });
  }
  
  /**
   * Rate limiting para endpoints públicos
   * 50 requests por 10 minutos por IP
   */
  get publicEndpoints() {
    return rateLimit({
      windowMs: 10 * 60 * 1000, // 10 minutos
      max: 50, // 50 requests por ventana
      store: this.createStore(),
      message: {
        success: false,
        error: 'Límite excedido',
        message: 'Demasiadas solicitudes a endpoints públicos. Intenta de nuevo en 10 minutos.',
        retry_after: '10 minutos'
      },
      standardHeaders: true,
      legacyHeaders: false,
      keyGenerator: (req) => `public:${req.ip}`
    });
  }
  
  /**
   * Rate limiting para operaciones administrativas
   * 200 requests por hora por administrador
   */
  get adminOperations() {
    return rateLimit({
      windowMs: 60 * 60 * 1000, // 1 hora
      max: 200, // 200 requests por hora
      store: this.createStore(),
      message: {
        success: false,
        error: 'Límite administrativo excedido',
        message: 'Has excedido el límite de operaciones administrativas por hora.',
        retry_after: '1 hora'
      },
      standardHeaders: true,
      legacyHeaders: false,
      // Solo aplicar a usuarios autenticados
      skip: (req) => !req.user?.matricula,
      keyGenerator: (req) => `admin:${req.user.matricula}`
    });
  }
  
  /**
   * Rate limiting estricto para creación de promociones
   * 10 creaciones por hora por administrador
   */
  get createPromocion() {
    return rateLimit({
      windowMs: 60 * 60 * 1000, // 1 hora
      max: 10, // 10 creaciones por hora
      store: this.createStore(),
      message: {
        success: false,
        error: 'Límite de creación excedido',
        message: 'No puedes crear más de 10 promociones por hora.',
        retry_after: '1 hora'
      },
      standardHeaders: true,
      legacyHeaders: false,
      keyGenerator: (req) => `create_promocion:${req.user?.matricula || req.ip}`
    });
  }
  
  /**
   * Rate limiting para operaciones destructivas
   * 5 eliminaciones por hora por administrador
   */
  get destructiveOperations() {
    return rateLimit({
      windowMs: 60 * 60 * 1000, // 1 hora
      max: 5, // 5 eliminaciones por hora
      store: this.createStore(),
      message: {
        success: false,
        error: 'Límite de eliminaciones excedido',
        message: 'No puedes eliminar más de 5 elementos por hora por seguridad.',
        retry_after: '1 hora'
      },
      standardHeaders: true,
      legacyHeaders: false,
      keyGenerator: (req) => `destructive:${req.user?.matricula || req.ip}`
    });
  }
  
  /**
   * Rate limiting global por IP
   * 1000 requests por hora por IP
   */
  get globalLimit() {
    return rateLimit({
      windowMs: 60 * 60 * 1000, // 1 hora
      max: 1000, // 1000 requests por hora
      store: this.createStore(),
      message: {
        success: false,
        error: 'Límite global excedido',
        message: 'Has excedido el límite global de solicitudes por hora.',
        retry_after: '1 hora'
      },
      standardHeaders: true,
      legacyHeaders: false,
      keyGenerator: (req) => `global:${req.ip}`,
      // Headers adicionales para debugging
      onLimitReached: (req, res) => {
        console.log(`[RateLimit] Límite global alcanzado para IP: ${req.ip}`);
      }
    });
  }
  
  /**
   * Rate limiting dinámico basado en el rol del usuario
   */
  dynamicLimit(baseLimits = { estudiante: 50, admin: 200, super_admin: 1000 }) {
    return (req, res, next) => {
      const userRole = req.user?.rol || 'estudiante';
      const limit = baseLimits[userRole] || baseLimits.estudiante;
      
      const dynamicRateLimit = rateLimit({
        windowMs: 15 * 60 * 1000, // 15 minutos
        max: limit,
        store: this.createStore(),
        message: {
          success: false,
          error: 'Límite excedido',
          message: `Límite de ${limit} solicitudes por 15 minutos excedido para rol ${userRole}.`,
          retry_after: '15 minutos',
          user_role: userRole,
          limit: limit
        },
        keyGenerator: (req) => `dynamic:${req.user?.matricula || req.ip}:${userRole}`
      });
      
      dynamicRateLimit(req, res, next);
    };
  }
  
  /**
   * Middleware para saltarse rate limiting en desarrollo
   */
  get developmentBypass() {
    return (req, res, next) => {
      if (process.env.NODE_ENV === 'development' && process.env.BYPASS_RATE_LIMIT === 'true') {
        console.log('[RateLimit] Bypass activado para desarrollo');
        return next();
      }
      
      // En producción, aplicar rate limiting normal
      this.globalLimit(req, res, next);
    };
  }
  
  /**
   * Rate limiting específico para búsquedas
   * Previene spam de búsquedas
   */
  get searchLimit() {
    return rateLimit({
      windowMs: 60 * 1000, // 1 minuto
      max: 30, // 30 búsquedas por minuto
      store: this.createStore(),
      message: {
        success: false,
        error: 'Demasiadas búsquedas',
        message: 'Has hecho demasiadas búsquedas muy rápido. Espera un momento.',
        retry_after: '1 minuto'
      },
      keyGenerator: (req) => `search:${req.user?.matricula || req.ip}`,
      // Solo contar búsquedas que devuelven resultados
      skip: (req) => {
        return req.method !== 'GET' || !req.query.q;
      }
    });
  }
  
  /**
   * Cleanup de Redis al cerrar la aplicación
   */
  async cleanup() {
    if (this.redisClient) {
      await this.redisClient.quit();
      console.log('[RateLimit] Redis desconectado');
    }
  }
}

module.exports = new RateLimitMiddleware();