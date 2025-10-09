const jwt = require('jsonwebtoken');
// const { Usuario } = require('../models/Usuario'); // Comentado temporalmente

/**
 * Middleware de autenticación para el sistema SASU
 * Verifica tokens JWT y extrae información del usuario
 */
class AuthMiddleware {
  
  /**
   * Verifica que el token JWT sea válido y extrae la información del usuario
   */
  async verifyToken(req, res, next) {
    try {
      // Obtener token del header Authorization
      const authHeader = req.headers.authorization;
      
      if (!authHeader) {
        return res.status(401).json({
          success: false,
          error: 'Token requerido',
          message: 'Se requiere autenticación para acceder a este recurso'
        });
      }
      
      // Verificar formato "Bearer <token>"
      const tokenParts = authHeader.split(' ');
      if (tokenParts.length !== 2 || tokenParts[0] !== 'Bearer') {
        return res.status(401).json({
          success: false,
          error: 'Formato de token inválido',
          message: 'El token debe tener el formato: Bearer <token>'
        });
      }
      
      const token = tokenParts[1];
      
      // Verificar y decodificar el token
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret_key');
      
      // Log para debugging
      console.log(`[AuthMiddleware] Token válido para usuario: ${decoded.matricula || decoded.id}`);
      
      // Verificar que el token contenga la información mínima requerida
      if (!decoded.matricula && !decoded.id) {
        return res.status(401).json({
          success: false,
          error: 'Token inválido',
          message: 'El token no contiene información de usuario válida'
        });
      }
      
      // Opcional: Verificar que el usuario sigue existiendo en la base de datos
      if (process.env.VERIFY_USER_EXISTS === 'true') {
        const usuario = await Usuario.findOne({
          where: {
            [decoded.matricula ? 'matricula' : 'id']: decoded.matricula || decoded.id,
            activo: true
          }
        });
        
        if (!usuario) {
          return res.status(401).json({
            success: false,
            error: 'Usuario no encontrado',
            message: 'El usuario asociado al token no existe o está inactivo'
          });
        }
        
        // Agregar información completa del usuario
        req.user = {
          id: usuario.id,
          matricula: usuario.matricula,
          nombre: usuario.nombre,
          email: usuario.email,
          rol: usuario.rol || 'estudiante',
          carrera: usuario.carrera,
          semestre: usuario.semestre,
          activo: usuario.activo
        };
      } else {
        // Usar solo la información del token (más rápido)
        req.user = {
          id: decoded.id,
          matricula: decoded.matricula,
          nombre: decoded.nombre,
          email: decoded.email,
          rol: decoded.rol || 'estudiante',
          carrera: decoded.carrera,
          semestre: decoded.semestre
        };
      }
      
      // Agregar metadata del token
      req.tokenInfo = {
        iat: decoded.iat,
        exp: decoded.exp,
        timeToExpire: decoded.exp ? (decoded.exp * 1000) - Date.now() : null
      };
      
      next();
      
    } catch (error) {
      console.error('[AuthMiddleware] Error verificando token:', error);
      
      // Manejar diferentes tipos de errores JWT
      if (error.name === 'TokenExpiredError') {
        return res.status(401).json({
          success: false,
          error: 'Token expirado',
          message: 'El token de autenticación ha expirado',
          expired_at: error.expiredAt
        });
      }
      
      if (error.name === 'JsonWebTokenError') {
        return res.status(401).json({
          success: false,
          error: 'Token inválido',
          message: 'El token de autenticación no es válido'
        });
      }
      
      if (error.name === 'NotBeforeError') {
        return res.status(401).json({
          success: false,
          error: 'Token no activo',
          message: 'El token aún no es válido',
          not_before: error.date
        });
      }
      
      // Error genérico
      return res.status(500).json({
        success: false,
        error: 'Error de autenticación',
        message: 'Error interno verificando autenticación'
      });
    }
  }
  
  /**
   * Middleware opcional que permite tanto usuarios autenticados como anónimos
   * Útil para endpoints que pueden personalizar contenido si hay autenticación
   */
  async optionalAuth(req, res, next) {
    try {
      const authHeader = req.headers.authorization;
      
      if (!authHeader) {
        // No hay token, continuar como usuario anónimo
        req.user = null;
        req.tokenInfo = null;
        return next();
      }
      
      // Hay token, intentar verificarlo
      await this.verifyToken(req, res, next);
      
    } catch (error) {
      // Si hay error en el token opcional, continuar como anónimo
      console.log('[AuthMiddleware] Token opcional inválido, continuando como anónimo');
      req.user = null;
      req.tokenInfo = null;
      next();
    }
  }
  
  /**
   * Verifica que el usuario tenga una matrícula específica
   * Útil para endpoints que solo deben ser accesibles por un usuario específico
   */
  requireMatricula(matriculaRequerida) {
    return (req, res, next) => {
      if (!req.user) {
        return res.status(401).json({
          success: false,
          error: 'Autenticación requerida'
        });
      }
      
      if (req.user.matricula !== matriculaRequerida) {
        return res.status(403).json({
          success: false,
          error: 'Acceso denegado',
          message: 'No tienes permisos para acceder a este recurso'
        });
      }
      
      next();
    };
  }
  
  /**
   * Verifica que el usuario esté activo
   */
  requireActiveUser(req, res, next) {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'Autenticación requerida'
      });
    }
    
    if (req.user.activo === false) {
      return res.status(403).json({
        success: false,
        error: 'Usuario inactivo',
        message: 'Tu cuenta está desactivada. Contacta al administrador.'
      });
    }
    
    next();
  }
  
  /**
   * Middleware para validar que el token no esté próximo a expirar
   * Útil para operaciones críticas
   */
  requireFreshToken(horasMinimas = 1) {
    return (req, res, next) => {
      if (!req.tokenInfo || !req.tokenInfo.timeToExpire) {
        return next(); // Si no hay info de expiración, continuar
      }
      
      const horasRestantes = req.tokenInfo.timeToExpire / (1000 * 60 * 60);
      
      if (horasRestantes < horasMinimas) {
        return res.status(401).json({
          success: false,
          error: 'Token próximo a expirar',
          message: `El token expira en menos de ${horasMinimas} hora(s). Renueva tu sesión.`,
          hours_remaining: Math.round(horasRestantes * 100) / 100
        });
      }
      
      next();
    };
  }
  
  /**
   * Genera un nuevo token JWT para un usuario
   */
  generateToken(user, expiresIn = '24h') {
    const payload = {
      id: user.id,
      matricula: user.matricula,
      nombre: user.nombre,
      email: user.email,
      rol: user.rol || 'estudiante',
      carrera: user.carrera,
      semestre: user.semestre
    };
    
    return jwt.sign(payload, process.env.JWT_SECRET || 'fallback_secret_key', {
      expiresIn: expiresIn,
      issuer: 'sasu-uagro',
      audience: 'carnet-digital'
    });
  }
  
  /**
   * Refresca un token existente (útil para renovación automática)
   */
  refreshToken(req, res, next) {
    try {
      if (!req.user) {
        return res.status(401).json({
          success: false,
          error: 'Usuario no autenticado'
        });
      }
      
      // Generar nuevo token
      const newToken = this.generateToken(req.user);
      
      // Agregar el nuevo token a la respuesta
      res.locals.newToken = newToken;
      
      next();
      
    } catch (error) {
      console.error('[AuthMiddleware] Error refrescando token:', error);
      res.status(500).json({
        success: false,
        error: 'Error refrescando token'
      });
    }
  }
}

module.exports = new AuthMiddleware();