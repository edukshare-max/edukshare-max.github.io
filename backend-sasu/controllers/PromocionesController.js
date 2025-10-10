const { PromocionSalud, CategoriaPromocion, DepartamentoSalud, PromocionInteraccion } = require('../models/PromocionSalud');
const { Op } = require('sequelize');
const jwt = require('jsonwebtoken');

/**
 * Controlador para manejo de Promociones de Salud
 * Sistema SASU - Universidad Autónoma de Guerrero
 */
class PromocionesController {

  /**
   * Obtiene todas las promociones activas para una matrícula específica
   * Incluye promociones generales y específicas para el estudiante
   */
  async getPromocionesByMatricula(req, res) {
    try {
      const { matricula } = req.user; // Obtenido del token JWT
      const { incluir_vencidas = false, limite = 20, categoria_id, departamento_id } = req.query;
      
      console.log(`[PromocionesController] Obteniendo promociones para matrícula: ${matricula}`);
      
      // Construir condiciones de búsqueda
      const whereConditions = {
        activo: true,
        [Op.or]: [
          { matricula_target: null }, // Promociones generales
          { matricula_target: matricula } // Promociones específicas
        ]
      };
      
      // Filtrar por fechas si no se incluyen vencidas
      if (!incluir_vencidas) {
        const hoy = new Date();
        whereConditions.fecha_inicio = { [Op.lte]: hoy };
        whereConditions.fecha_fin = { [Op.gte]: hoy };
      }
      
      // Filtros opcionales
      if (categoria_id) {
        whereConditions.categoria_id = categoria_id;
      }
      
      if (departamento_id) {
        whereConditions.departamento_id = departamento_id;
      }
      
      // Ejecutar consulta
      const promociones = await PromocionSalud.findAll({
        where: whereConditions,
        include: [
          {
            model: CategoriaPromocion,
            as: 'categoria',
            where: { activo: true },
            attributes: ['id', 'nombre', 'descripcion', 'color_hex', 'icono']
          },
          {
            model: DepartamentoSalud,
            as: 'departamento',
            where: { activo: true },
            attributes: ['id', 'nombre', 'descripcion', 'contacto_email', 'contacto_telefono', 'ubicacion']
          }
        ],
        order: [
          ['urgente', 'DESC'],
          ['destacado', 'DESC'],
          ['prioridad', 'DESC'],
          ['created_at', 'DESC']
        ],
        limit: parseInt(limite)
      });
      
      // Registrar vista para cada promoción (sin esperar)
      promociones.forEach(promocion => {
        promocion.registrarInteraccion(
          matricula, 
          'vista', 
          req.get('User-Agent'), 
          req.ip
        ).catch(err => {
          console.error(`Error registrando vista para promoción ${promocion.id}:`, err);
        });
      });
      
      // Formatear respuesta para Flutter
      const promocionesFormateadas = promociones.map(promocion => ({
        id: promocion.id,
        titulo: promocion.titulo,
        descripcion: promocion.descripcion,
        resumen: promocion.resumen || promocion.descripcion.substring(0, 150) + '...',
        link: promocion.link,
        imagen_url: promocion.imagen_url,
        categoria: promocion.categoria.nombre,
        categoria_color: promocion.categoria.color_hex,
        categoria_icono: promocion.categoria.icono,
        departamento: promocion.departamento.nombre,
        departamento_contacto: {
          email: promocion.departamento.contacto_email,
          telefono: promocion.departamento.contacto_telefono,
          ubicacion: promocion.departamento.ubicacion
        },
        fecha_inicio: promocion.fecha_inicio,
        fecha_fin: promocion.fecha_fin,
        destacado: promocion.destacado,
        urgente: promocion.urgente,
        prioridad: promocion.prioridad,
        vistas: promocion.vistas,
        clicks: promocion.clicks,
        es_especifica: promocion.matricula_target === matricula,
        tiempo_restante_dias: Math.ceil((new Date(promocion.fecha_fin) - new Date()) / (1000 * 60 * 60 * 24)),
        created_at: promocion.created_at,
        updated_at: promocion.updated_at
      }));
      
      console.log(`[PromocionesController] Encontradas ${promocionesFormateadas.length} promociones para ${matricula}`);
      
      res.json({
        success: true,
        data: promocionesFormateadas,
        meta: {
          total: promocionesFormateadas.length,
          matricula: matricula,
          incluir_vencidas: incluir_vencidas,
          timestamp: new Date().toISOString()
        }
      });
      
    } catch (error) {
      console.error('[PromocionesController] Error obteniendo promociones:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor',
        message: 'No se pudieron obtener las promociones',
        details: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
  
  /**
   * Registra un click en una promoción específica
   */
  async registrarClick(req, res) {
    try {
      const { promocion_id } = req.params;
      const { matricula } = req.user;
      
      console.log(`[PromocionesController] Registrando click en promoción ${promocion_id} por ${matricula}`);
      
      // Verificar que la promoción existe y está activa
      const promocion = await PromocionSalud.findOne({
        where: {
          id: promocion_id,
          activo: true
        }
      });
      
      if (!promocion) {
        return res.status(404).json({
          success: false,
          error: 'Promoción no encontrada',
          message: 'La promoción solicitada no existe o no está activa'
        });
      }
      
      // Verificar que la promoción es aplicable para esta matrícula
      if (promocion.matricula_target && promocion.matricula_target !== matricula) {
        return res.status(403).json({
          success: false,
          error: 'Acceso denegado',
          message: 'Esta promoción no está dirigida a tu matrícula'
        });
      }
      
      // Registrar la interacción
      await promocion.registrarInteraccion(
        matricula,
        'click',
        req.get('User-Agent'),
        req.ip
      );
      
      res.json({
        success: true,
        message: 'Click registrado correctamente',
        data: {
          promocion_id: promocion.id,
          titulo: promocion.titulo,
          link: promocion.link,
          clicks_totales: promocion.clicks + 1
        }
      });
      
    } catch (error) {
      console.error('[PromocionesController] Error registrando click:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor',
        message: 'No se pudo registrar el click'
      });
    }
  }
  
  /**
   * Obtiene promociones destacadas (para carrusel principal)
   */
  async getPromocionesDestacadas(req, res) {
    try {
      const { matricula } = req.user;
      const { limite = 10 } = req.query;
      
      console.log(`[PromocionesController] Obteniendo promociones destacadas para ${matricula}`);
      
      const promociones = await PromocionSalud.obtenerDestacadas(parseInt(limite));
      
      // Filtrar por matrícula si es aplicable
      const promocionesFiltradas = promociones.filter(promocion => 
        !promocion.matricula_target || promocion.matricula_target === matricula
      );
      
      const promocionesFormateadas = promocionesFiltradas.map(promocion => ({
        id: promocion.id,
        titulo: promocion.titulo,
        resumen: promocion.resumen || promocion.descripcion.substring(0, 100) + '...',
        link: promocion.link,
        imagen_url: promocion.imagen_url,
        categoria: promocion.categoria.nombre,
        categoria_color: promocion.categoria.color_hex,
        categoria_icono: promocion.categoria.icono,
        departamento: promocion.departamento.nombre,
        urgente: promocion.urgente,
        prioridad: promocion.prioridad,
        es_especifica: promocion.matricula_target === matricula
      }));
      
      res.json({
        success: true,
        data: promocionesFormateadas,
        meta: {
          total: promocionesFormateadas.length,
          tipo: 'destacadas',
          matricula: matricula
        }
      });
      
    } catch (error) {
      console.error('[PromocionesController] Error obteniendo destacadas:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }
  
  /**
   * Obtiene estadísticas de una promoción
   */
  async getEstadisticasPromocion(req, res) {
    try {
      const { promocion_id } = req.params;
      
      const estadisticas = await PromocionSalud.obtenerEstadisticas(promocion_id);
      
      res.json({
        success: true,
        data: estadisticas
      });
      
    } catch (error) {
      console.error('[PromocionesController] Error obteniendo estadísticas:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }
  
  // ============================================
  // MÉTODOS ADMINISTRATIVOS
  // ============================================
  
  /**
   * Crea una nueva promoción (solo administradores)
   */
  async createPromocion(req, res) {
    try {
      const {
        titulo, descripcion, resumen, link, imagen_url,
        categoria_id, departamento_id,
        matricula_target, carrera_target, semestre_target,
        fecha_inicio, fecha_fin,
        destacado = false, urgente = false, prioridad = 5
      } = req.body;
      
      console.log(`[PromocionesController] Creando nueva promoción: ${titulo}`);
      
      // Validaciones básicas
      if (!titulo || !descripcion || !categoria_id || !departamento_id || !fecha_inicio || !fecha_fin) {
        return res.status(400).json({
          success: false,
          error: 'Datos incompletos',
          message: 'Título, descripción, categoría, departamento y fechas son obligatorios'
        });
      }
      
      // Verificar que la categoría y departamento existen
      const [categoria, departamento] = await Promise.all([
        CategoriaPromocion.findByPk(categoria_id),
        DepartamentoSalud.findByPk(departamento_id)
      ]);
      
      if (!categoria || !departamento) {
        return res.status(400).json({
          success: false,
          error: 'Referencias inválidas',
          message: 'La categoría o departamento especificado no existe'
        });
      }
      
      // Crear la promoción
      const promocion = await PromocionSalud.create({
        titulo, descripcion, resumen, link, imagen_url,
        categoria_id, departamento_id,
        matricula_target, carrera_target, semestre_target,
        fecha_inicio, fecha_fin,
        destacado, urgente, prioridad,
        activo: true
      });
      
      // Obtener la promoción completa con relaciones
      const promocionCompleta = await PromocionSalud.findByPk(promocion.id, {
        include: [
          { model: CategoriaPromocion, as: 'categoria' },
          { model: DepartamentoSalud, as: 'departamento' }
        ]
      });
      
      console.log(`[PromocionesController] Promoción creada exitosamente: ID ${promocion.id}`);
      
      res.status(201).json({
        success: true,
        message: 'Promoción creada exitosamente',
        data: promocionCompleta
      });
      
    } catch (error) {
      console.error('[PromocionesController] Error creando promoción:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor',
        message: 'No se pudo crear la promoción',
        details: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
  
  /**
   * Actualiza una promoción existente (solo administradores)
   */
  async updatePromocion(req, res) {
    try {
      const { promocion_id } = req.params;
      const actualizaciones = req.body;
      
      console.log(`[PromocionesController] Actualizando promoción ${promocion_id}`);
      
      // Buscar la promoción
      const promocion = await PromocionSalud.findByPk(promocion_id);
      
      if (!promocion) {
        return res.status(404).json({
          success: false,
          error: 'Promoción no encontrada'
        });
      }
      
      // Validar referencias si se están actualizando
      if (actualizaciones.categoria_id || actualizaciones.departamento_id) {
        const validaciones = [];
        
        if (actualizaciones.categoria_id) {
          validaciones.push(CategoriaPromocion.findByPk(actualizaciones.categoria_id));
        }
        
        if (actualizaciones.departamento_id) {
          validaciones.push(DepartamentoSalud.findByPk(actualizaciones.departamento_id));
        }
        
        const resultados = await Promise.all(validaciones);
        
        if (resultados.some(resultado => !resultado)) {
          return res.status(400).json({
            success: false,
            error: 'Referencias inválidas',
            message: 'La categoría o departamento especificado no existe'
          });
        }
      }
      
      // Actualizar la promoción
      await promocion.update(actualizaciones);
      
      // Obtener la promoción actualizada con relaciones
      const promocionActualizada = await PromocionSalud.findByPk(promocion_id, {
        include: [
          { model: CategoriaPromocion, as: 'categoria' },
          { model: DepartamentoSalud, as: 'departamento' }
        ]
      });
      
      res.json({
        success: true,
        message: 'Promoción actualizada exitosamente',
        data: promocionActualizada
      });
      
    } catch (error) {
      console.error('[PromocionesController] Error actualizando promoción:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }
  
  /**
   * Elimina (desactiva) una promoción (solo administradores)
   */
  async deletePromocion(req, res) {
    try {
      const { promocion_id } = req.params;
      const { eliminar_permanente = false } = req.query;
      
      console.log(`[PromocionesController] ${eliminar_permanente ? 'Eliminando permanentemente' : 'Desactivando'} promoción ${promocion_id}`);
      
      const promocion = await PromocionSalud.findByPk(promocion_id);
      
      if (!promocion) {
        return res.status(404).json({
          success: false,
          error: 'Promoción no encontrada'
        });
      }
      
      if (eliminar_permanente === 'true') {
        // Eliminar permanentemente (también elimina interacciones por CASCADE)
        await promocion.destroy();
        
        res.json({
          success: true,
          message: 'Promoción eliminada permanentemente'
        });
      } else {
        // Solo desactivar
        await promocion.update({ activo: false });
        
        res.json({
          success: true,
          message: 'Promoción desactivada exitosamente',
          data: promocion
        });
      }
      
    } catch (error) {
      console.error('[PromocionesController] Error eliminando promoción:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }
  
  /**
   * Lista todas las promociones con filtros (solo administradores)
   */
  async getAllPromociones(req, res) {
    try {
      const {
        activo, categoria_id, departamento_id,
        fecha_desde, fecha_hasta,
        matricula_target,
        page = 1, limit = 50,
        order_by = 'created_at',
        order_direction = 'DESC'
      } = req.query;
      
      // Construir condiciones
      const whereConditions = {};
      
      if (activo !== undefined) {
        whereConditions.activo = activo === 'true';
      }
      
      if (categoria_id) {
        whereConditions.categoria_id = categoria_id;
      }
      
      if (departamento_id) {
        whereConditions.departamento_id = departamento_id;
      }
      
      if (matricula_target) {
        whereConditions.matricula_target = matricula_target;
      }
      
      if (fecha_desde || fecha_hasta) {
        whereConditions.fecha_inicio = {};
        if (fecha_desde) whereConditions.fecha_inicio[Op.gte] = fecha_desde;
        if (fecha_hasta) whereConditions.fecha_inicio[Op.lte] = fecha_hasta;
      }
      
      // Calcular offset
      const offset = (parseInt(page) - 1) * parseInt(limit);
      
      // Ejecutar consulta
      const { count, rows: promociones } = await PromocionSalud.findAndCountAll({
        where: whereConditions,
        include: [
          { model: CategoriaPromocion, as: 'categoria' },
          { model: DepartamentoSalud, as: 'departamento' }
        ],
        order: [[order_by, order_direction.toUpperCase()]],
        limit: parseInt(limit),
        offset: offset
      });
      
      res.json({
        success: true,
        data: promociones,
        meta: {
          total: count,
          page: parseInt(page),
          limit: parseInt(limit),
          total_pages: Math.ceil(count / parseInt(limit))
        }
      });
      
    } catch (error) {
      console.error('[PromocionesController] Error listando promociones:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }
  
  /**
   * Obtiene categorías disponibles
   */
  async getCategorias(req, res) {
    try {
      const categorias = await CategoriaPromocion.findAll({
        where: { activo: true },
        order: [['nombre', 'ASC']]
      });
      
      res.json({
        success: true,
        data: categorias
      });
      
    } catch (error) {
      console.error('[PromocionesController] Error obteniendo categorías:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }
  
  /**
   * Obtiene departamentos disponibles
   */
  async getDepartamentos(req, res) {
    try {
      const departamentos = await DepartamentoSalud.findAll({
        where: { activo: true },
        order: [['nombre', 'ASC']]
      });
      
      res.json({
        success: true,
        data: departamentos
      });
      
    } catch (error) {
      console.error('[PromocionesController] Error obteniendo departamentos:', error);
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor'
      });
    }
  }
}

module.exports = new PromocionesController();