const cosmosDB = require('../config/cosmosdb');

/**
 * Controlador de Promociones - Azure Cosmos DB
 * Lee promociones del contenedor promociones_salud
 */
class PromocionesController {
  
  /**
   * Obtener promociones para un estudiante por matrícula
   * GET /me/promociones
   */
  async getPromocionesByMatricula(req, res) {
    try {
      const matricula = req.user?.matricula || req.query.matricula;
      
      if (!matricula) {
        return res.status(400).json({
          success: false,
          message: 'Matrícula no proporcionada'
        });
      }

      console.log(`[Promociones] 🔍 Buscando promociones para matrícula: ${matricula}`);

      // Obtener promociones de Cosmos DB
      const promociones = await cosmosDB.getPromocionesByMatricula(matricula);

      // Mapear datos al formato esperado por Flutter
      const promocionesFormateadas = promociones.map(promo => ({
        id: promo.id,
        titulo: promo.programa || 'Sin título',
        descripcion: promo.link || '',
        categoria: promo.categoria || 'General',
        departamento: promo.departamento || 'SASU',
        link: promo.link || '',
        matricula: promo.matricula || null,
        destinatario: promo.destinatario || 'Alumno',
        autorizado: promo.autorizado || false,
        createdAt: promo.createdAt || new Date().toISOString(),
        createdBy: promo.createdBy || 'Sistema SASU',
        // Campos adicionales de Cosmos DB
        programa: promo.programa || '',
        es_especifica: !!promo.matricula, // Si tiene matrícula, es específica
        destacado: false,
        urgente: false,
        prioridad: 5
      }));

      console.log(`[Promociones] ✅ Encontradas ${promocionesFormateadas.length} promociones`);

      return res.status(200).json({
        success: true,
        data: promocionesFormateadas,
        count: promocionesFormateadas.length,
        matricula: matricula
      });

    } catch (error) {
      console.error('[Promociones] ❌ Error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error obteniendo promociones',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Registrar click en una promoción
   * POST /me/promociones/:id/click
   */
  async registrarClick(req, res) {
    try {
      const { id } = req.params;
      const matricula = req.user?.matricula;

      console.log(`[Promociones] 📊 Click registrado: ${id} por ${matricula}`);

      // Registrar en Cosmos DB (si tienes contenedor de analytics)
      await cosmosDB.registrarInteraccion(id, matricula, 'click');

      return res.status(200).json({
        success: true,
        message: 'Click registrado'
      });

    } catch (error) {
      console.error('[Promociones] ❌ Error registrando click:', error);
      return res.status(500).json({
        success: false,
        message: 'Error registrando click'
      });
    }
  }

  /**
   * Obtener todas las promociones (admin)
   * GET /admin/promociones
   */
  async getAllPromociones(req, res) {
    try {
      console.log('[Promociones] 🔍 Admin: Obteniendo todas las promociones');

      const promociones = await cosmosDB.getAllPromociones();

      return res.status(200).json({
        success: true,
        data: promociones,
        count: promociones.length
      });

    } catch (error) {
      console.error('[Promociones] ❌ Error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error obteniendo promociones'
      });
    }
  }

  /**
   * Obtener una promoción por ID
   * GET /promociones/:id
   */
  async getPromocionById(req, res) {
    try {
      const { id } = req.params;

      const promocion = await cosmosDB.getPromocionById(id);

      if (!promocion) {
        return res.status(404).json({
          success: false,
          message: 'Promoción no encontrada'
        });
      }

      return res.status(200).json({
        success: true,
        data: promocion
      });

    } catch (error) {
      console.error('[Promociones] ❌ Error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error obteniendo promoción'
      });
    }
  }

  /**
   * Obtener estadísticas de promociones
   * GET /public/promociones/stats
   */
  async getEstadisticas(req, res) {
    try {
      const stats = await cosmosDB.getEstadisticas();

      return res.status(200).json({
        success: true,
        data: stats
      });

    } catch (error) {
      console.error('[Promociones] ❌ Error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error obteniendo estadísticas'
      });
    }
  }

  /**
   * NOTA: Los métodos de crear, actualizar y eliminar NO están implementados
   * porque las promociones se gestionan desde otra aplicación.
   * Este backend es SOLO DE LECTURA.
   */

}

module.exports = new PromocionesController();
