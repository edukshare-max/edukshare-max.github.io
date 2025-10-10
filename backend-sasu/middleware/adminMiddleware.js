/**
 * Middleware de administración para el sistema SASU
 * Verifica permisos de administrador y roles específicos
 */
class AdminMiddleware {
  
  /**
   * Requiere que el usuario sea administrador
   */
  requireAdmin(req, res, next) {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'Autenticación requerida',
        message: 'Debes estar autenticado para acceder a este recurso'
      });
    }
    
    // Verificar rol de administrador
    const rolesAdmin = ['admin', 'administrador', 'super_admin', 'coordinador'];
    
    if (!req.user.rol || !rolesAdmin.includes(req.user.rol.toLowerCase())) {
      console.log(`[AdminMiddleware] Acceso denegado para ${req.user.matricula} con rol: ${req.user.rol}`);
      
      return res.status(403).json({
        success: false,
        error: 'Permisos insuficientes',
        message: 'No tienes permisos de administrador para realizar esta acción',
        required_role: 'admin',
        current_role: req.user.rol
      });
    }
    
    console.log(`[AdminMiddleware] Acceso admin concedido a ${req.user.matricula} (${req.user.rol})`);
    next();
  }
  
  /**
   * Requiere rol específico
   */
  requireRole(rolesPermitidos) {
    // Normalizar a array
    const roles = Array.isArray(rolesPermitidos) ? rolesPermitidos : [rolesPermitidos];
    
    return (req, res, next) => {
      if (!req.user) {
        return res.status(401).json({
          success: false,
          error: 'Autenticación requerida'
        });
      }
      
      if (!req.user.rol || !roles.includes(req.user.rol.toLowerCase())) {
        return res.status(403).json({
          success: false,
          error: 'Permisos insuficientes',
          message: `Rol requerido: ${roles.join(' o ')}`,
          required_roles: roles,
          current_role: req.user.rol
        });
      }
      
      next();
    };
  }
  
  /**
   * Permite acceso a administradores O al propio usuario
   * Útil para endpoints donde un usuario puede ver/editar sus propios datos
   */
  requireAdminOrSelf(req, res, next) {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'Autenticación requerida'
      });
    }
    
    // Verificar si es admin
    const rolesAdmin = ['admin', 'administrador', 'super_admin', 'coordinador'];
    const esAdmin = req.user.rol && rolesAdmin.includes(req.user.rol.toLowerCase());
    
    // Verificar si está accediendo a sus propios datos
    const matriculaTargetFromParams = req.params.matricula || req.params.usuario_matricula;
    const matriculaTargetFromBody = req.body.matricula;
    const esPropio = req.user.matricula === matriculaTargetFromParams || 
                     req.user.matricula === matriculaTargetFromBody;
    
    if (!esAdmin && !esPropio) {
      return res.status(403).json({
        success: false,
        error: 'Permisos insuficientes',
        message: 'Solo puedes acceder a tus propios datos o ser administrador'
      });
    }
    
    // Agregar flag para saber si es admin o acceso propio
    req.isAdminAccess = esAdmin;
    req.isSelfAccess = esPropio;
    
    next();
  }
  
  /**
   * Requiere permisos específicos (para sistemas más granulares)
   */
  requirePermission(permisoRequerido) {
    return (req, res, next) => {
      if (!req.user) {
        return res.status(401).json({
          success: false,
          error: 'Autenticación requerida'
        });
      }
      
      // Si el usuario tiene permisos definidos, verificarlos
      if (req.user.permisos && Array.isArray(req.user.permisos)) {
        if (!req.user.permisos.includes(permisoRequerido)) {
          return res.status(403).json({
            success: false,
            error: 'Permiso denegado',
            message: `Permiso requerido: ${permisoRequerido}`,
            required_permission: permisoRequerido,
            user_permissions: req.user.permisos
          });
        }
      } else {
        // Fallback: verificar por rol si no hay permisos específicos
        const rolesAdmin = ['admin', 'administrador', 'super_admin'];
        if (!req.user.rol || !rolesAdmin.includes(req.user.rol.toLowerCase())) {
          return res.status(403).json({
            success: false,
            error: 'Permisos insuficientes',
            message: 'No tienes permisos para realizar esta acción'
          });
        }
      }
      
      next();
    };
  }
  
  /**
   * Middleware para registrar acciones administrativas
   */
  logAdminAction(accion) {
    return (req, res, next) => {
      // Log detallado de acciones administrativas
      console.log(`[ADMIN ACTION] ${accion}`, {
        admin: req.user?.matricula,
        rol: req.user?.rol,
        ip: req.ip,
        userAgent: req.get('User-Agent'),
        timestamp: new Date().toISOString(),
        endpoint: `${req.method} ${req.originalUrl}`,
        body: req.method !== 'GET' ? req.body : undefined
      });
      
      // Agregar información de auditoría a la request
      req.adminAudit = {
        accion: accion,
        admin_matricula: req.user?.matricula,
        timestamp: new Date(),
        ip_address: req.ip
      };
      
      next();
    };
  }
  
  /**
   * Middleware para proteger acciones destructivas
   * Requiere confirmación adicional o rate limiting especial
   */
  requireDestructiveConfirmation(req, res, next) {
    // Para acciones destructivas como eliminar promociones
    const confirmacion = req.headers['x-confirm-action'];
    const expectedConfirmation = `DELETE_${req.params.promocion_id || 'UNKNOWN'}_${req.user?.matricula}`;
    
    if (confirmacion !== expectedConfirmation) {
      return res.status(400).json({
        success: false,
        error: 'Confirmación requerida',
        message: 'Esta acción destructiva requiere confirmación',
        required_header: 'X-Confirm-Action',
        expected_value: expectedConfirmation
      });
    }
    
    next();
  }
  
  /**
   * Middleware para limitar acceso por horario (ej: solo horario laboral)
   */
  requireBusinessHours(req, res, next) {
    const ahora = new Date();
    const hora = ahora.getHours();
    const diaSemana = ahora.getDay(); // 0 = domingo, 1 = lunes, etc.
    
    // Horario laboral: Lunes a Viernes, 8:00 AM a 6:00 PM
    const esHorarioLaboral = (diaSemana >= 1 && diaSemana <= 5) && (hora >= 8 && hora < 18);
    
    if (!esHorarioLaboral) {
      // Permitir a super admins trabajar fuera de horario
      const superAdmins = ['super_admin', 'coordinador'];
      if (!req.user?.rol || !superAdmins.includes(req.user.rol.toLowerCase())) {
        return res.status(403).json({
          success: false,
          error: 'Fuera de horario laboral',
          message: 'Las operaciones administrativas solo están permitidas en horario laboral (L-V, 8:00-18:00)',
          current_time: ahora.toISOString(),
          business_hours: 'Lunes a Viernes, 08:00-18:00'
        });
      }
    }
    
    next();
  }
}

module.exports = new AdminMiddleware();