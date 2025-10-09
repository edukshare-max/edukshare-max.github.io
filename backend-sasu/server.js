const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// Importar rutas y middlewares
const promocionesRoutes = require('./routes/promociones');
const rateLimitMiddleware = require('./middleware/rateLimitMiddleware');
const { sequelize } = require('./config/database');

/**
 * Servidor principal del sistema SASU
 * Sistema de promociones de salud para la Universidad Autónoma de Guerrero
 */
class SASUServer {
  
  constructor() {
    this.app = express();
    this.port = process.env.PORT || 3000;
    this.initializeMiddlewares();
    this.initializeRoutes();
    this.initializeErrorHandling();
    this.initializeDatabase();
  }
  
  /**
   * Configura middlewares globales
   */
  initializeMiddlewares() {
    // Seguridad básica
    this.app.use(helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          styleSrc: ["'self'", "'unsafe-inline'", "https:"],
          scriptSrc: ["'self'", "https:"],
          imgSrc: ["'self'", "data:", "https:"],
          connectSrc: ["'self'", "https:"],
          fontSrc: ["'self'", "https:"],
          objectSrc: ["'none'"],
          mediaSrc: ["'self'", "https:"],
          frameSrc: ["'none'"],
        },
      },
      crossOriginEmbedderPolicy: false
    }));
    
    // CORS configurado para desarrollo y producción
    const corsOptions = {
      origin: this.getAllowedOrigins(),
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: [
        'Origin',
        'X-Requested-With',
        'Content-Type',
        'Accept',
        'Authorization',
        'X-Confirm-Action'
      ],
      credentials: true,
      maxAge: 86400 // 24 horas
    };
    
    this.app.use(cors(corsOptions));
    
    // Compresión de respuestas
    this.app.use(compression());
    
    // Logging de requests
    if (process.env.NODE_ENV === 'production') {
      this.app.use(morgan('combined'));
    } else {
      this.app.use(morgan('dev'));
    }
    
    // Parsing de body
    this.app.use(express.json({ limit: '10mb' }));
    this.app.use(express.urlencoded({ extended: true, limit: '10mb' }));
    
    // Rate limiting global
    this.app.use(rateLimitMiddleware.globalLimit);
    
    // Middleware para agregar headers útiles
    this.app.use((req, res, next) => {
      res.set({
        'X-API-Version': '1.0.0',
        'X-Powered-By': 'SASU-UAGro',
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'DENY',
        'X-XSS-Protection': '1; mode=block'
      });
      next();
    });
    
    // Middleware de información de request
    this.app.use((req, res, next) => {
      req.requestId = this.generateRequestId();
      req.startTime = Date.now();
      
      console.log(`[${req.requestId}] ${req.method} ${req.originalUrl} - IP: ${req.ip}`);
      next();
    });
  }
  
  /**
   * Configura rutas de la aplicación
   */
  initializeRoutes() {
    // Ruta de health check
    this.app.get('/health', (req, res) => {
      res.json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        system: 'SASU-UAGro',
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        environment: process.env.NODE_ENV || 'development'
      });
    });
    
    // Ruta raíz con información de la API
    this.app.get('/', (req, res) => {
      res.json({
        name: 'SASU API - Sistema de Promociones de Salud',
        description: 'API para el sistema de carnet digital de la Universidad Autónoma de Guerrero',
        version: '1.0.0',
        endpoints: {
          estudiantes: {
            promociones: 'GET /me/promociones',
            destacadas: 'GET /me/promociones/destacadas',
            registrar_click: 'POST /me/promociones/:id/click'
          },
          administradores: {
            listar: 'GET /admin/promociones',
            crear: 'POST /admin/promociones',
            actualizar: 'PUT /admin/promociones/:id',
            eliminar: 'DELETE /admin/promociones/:id'
          },
          publicos: {
            categorias: 'GET /public/promociones/categorias',
            departamentos: 'GET /public/promociones/departamentos',
            estadisticas: 'GET /public/promociones/stats'
          }
        },
        authentication: 'Bearer JWT Token required for protected routes',
        documentation: 'https://api-docs.uagro.mx/sasu',
        contact: {
          email: 'soporte@uagro.mx',
          phone: '+52 744 445 1100'
        }
      });
    });
    
    // Rutas de promociones
    this.app.use('/', promocionesRoutes);
    
    // Ruta para información de autenticación
    this.app.get('/auth/info', (req, res) => {
      res.json({
        message: 'Endpoint de autenticación',
        login_url: '/auth/login',
        refresh_url: '/auth/refresh',
        logout_url: '/auth/logout',
        required_fields: ['matricula', 'password'],
        token_type: 'Bearer JWT',
        token_expiry: '24 hours'
      });
    });
  }
  
  /**
   * Configura manejo de errores globales
   */
  initializeErrorHandling() {
    // Manejo de rutas no encontradas
    this.app.use('*', (req, res) => {
      res.status(404).json({
        success: false,
        error: 'Endpoint no encontrado',
        message: `La ruta ${req.method} ${req.originalUrl} no existe`,
        suggestion: 'Verifica la documentación de la API en /',
        available_routes: [
          'GET /',
          'GET /health',
          'GET /me/promociones',
          'GET /admin/promociones',
          'GET /public/promociones/stats'
        ]
      });
    });
    
    // Manejo de errores globales
    this.app.use((error, req, res, next) => {
      const requestId = req.requestId || 'unknown';
      
      console.error(`[${requestId}] Error no manejado:`, {
        error: error.message,
        stack: error.stack,
        url: req.originalUrl,
        method: req.method,
        ip: req.ip,
        userAgent: req.get('User-Agent')
      });
      
      // Error de validación de JSON
      if (error instanceof SyntaxError && error.status === 400 && 'body' in error) {
        return res.status(400).json({
          success: false,
          error: 'JSON inválido',
          message: 'El cuerpo de la petición contiene JSON malformado',
          request_id: requestId
        });
      }
      
      // Error de payload demasiado grande
      if (error.code === 'LIMIT_FILE_SIZE') {
        return res.status(413).json({
          success: false,
          error: 'Archivo demasiado grande',
          message: 'El archivo excede el tamaño máximo permitido',
          max_size: '10MB',
          request_id: requestId
        });
      }
      
      // Error genérico
      res.status(error.status || 500).json({
        success: false,
        error: 'Error interno del servidor',
        message: process.env.NODE_ENV === 'development' ? error.message : 'Algo salió mal',
        request_id: requestId,
        timestamp: new Date().toISOString()
      });
    });
  }
  
  /**
   * Inicializa conexión a base de datos
   */
  async initializeDatabase() {
    try {
      await sequelize.authenticate();
      console.log('[SASU] ✅ Conexión a base de datos establecida');
      
      // No sincronizar automáticamente si las tablas ya existen
      // Usar npm run seed para poblar datos
      // await sequelize.sync({ alter: false });
      console.log('[SASU] ✅ Base de datos lista');
      
    } catch (error) {
      console.error('[SASU] ❌ Error conectando a base de datos:', error);
      process.exit(1);
    }
  }
  
  /**
   * Obtiene orígenes permitidos para CORS
   */
  getAllowedOrigins() {
    const origins = [
      'http://localhost:3000',
      'http://localhost:5173',
      'http://localhost:8080',
      'http://localhost:8888',
      'https://carnet.uagro.mx',
      'https://sasu.uagro.mx'
    ];
    
    // Agregar orígenes desde variables de entorno
    if (process.env.ALLOWED_ORIGINS) {
      const envOrigins = process.env.ALLOWED_ORIGINS.split(',');
      origins.push(...envOrigins);
    }
    
    return origins;
  }
  
  /**
   * Genera ID único para cada request
   */
  generateRequestId() {
    return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  
  /**
   * Inicia el servidor
   */
  async start() {
    try {
      this.server = this.app.listen(this.port, () => {
        console.log(`
╔══════════════════════════════════════════════════════════════╗
║                     SASU SERVER INICIADO                     ║
╠══════════════════════════════════════════════════════════════╣
║ Puerto: ${this.port.toString().padEnd(53)} ║
║ Entorno: ${(process.env.NODE_ENV || 'development').padEnd(51)} ║
║ URL: http://localhost:${this.port.toString().padEnd(42)} ║
║                                                              ║
║ Endpoints principales:                                       ║
║ • GET  /                     - Información de la API        ║
║ • GET  /health               - Health check                 ║
║ • GET  /me/promociones       - Promociones del estudiante   ║
║ • POST /admin/promociones    - Crear promoción (admin)      ║
║                                                              ║
║ Universidad Autónoma de Guerrero                            ║
║ Sistema de Promociones de Salud                             ║
╚══════════════════════════════════════════════════════════════╝
        `);
      });
      
      // Manejo de cierre graceful
      this.setupGracefulShutdown();
      
    } catch (error) {
      console.error('[SASU] ❌ Error iniciando servidor:', error);
      process.exit(1);
    }
  }
  
  /**
   * Configura cierre graceful del servidor
   */
  setupGracefulShutdown() {
    const gracefulShutdown = async (signal) => {
      console.log(`\n[SASU] 🛑 Recibida señal ${signal}, cerrando servidor...`);
      
      if (this.server) {
        this.server.close(async () => {
          console.log('[SASU] ✅ Servidor HTTP cerrado');
          
          try {
            await sequelize.close();
            console.log('[SASU] ✅ Conexión a base de datos cerrada');
            
            await rateLimitMiddleware.cleanup();
            console.log('[SASU] ✅ Rate limiting limpiado');
            
            console.log('[SASU] 👋 Servidor cerrado gracefully');
            process.exit(0);
            
          } catch (error) {
            console.error('[SASU] ❌ Error en cierre graceful:', error);
            process.exit(1);
          }
        });
      } else {
        process.exit(0);
      }
    };
    
    // Escuchar señales de cierre
    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));
    
    // Manejo de errores no capturados
    process.on('unhandledRejection', (reason, promise) => {
      console.error('[SASU] ❌ Unhandled Rejection at:', promise, 'reason:', reason);
    });
    
    process.on('uncaughtException', (error) => {
      console.error('[SASU] ❌ Uncaught Exception:', error);
      process.exit(1);
    });
  }
}

// Crear y iniciar servidor si se ejecuta directamente
if (require.main === module) {
  const server = new SASUServer();
  server.start();
}

module.exports = SASUServer;