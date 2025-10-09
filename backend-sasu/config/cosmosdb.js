const { CosmosClient } = require('@azure/cosmos');
require('dotenv').config();

/**
 * Configuración de Azure Cosmos DB para SASU
 * Contenedor: promociones_salud
 */

// Configuración de conexión
const config = {
  endpoint: process.env.COSMOS_ENDPOINT || '',
  key: process.env.COSMOS_KEY || '',
  databaseId: process.env.COSMOS_DATABASE_ID || 'sasu_database',
  containerId: process.env.COSMOS_CONTAINER_ID || 'promociones_salud'
};

// Crear cliente de Cosmos DB
let cosmosClient = null;
let database = null;
let container = null;

/**
 * Inicializar conexión a Cosmos DB
 */
async function initCosmosDB() {
  try {
    if (!config.endpoint || !config.key) {
      throw new Error('Faltan credenciales de Cosmos DB (COSMOS_ENDPOINT y COSMOS_KEY)');
    }

    console.log('[Cosmos DB] 🔄 Conectando a Azure Cosmos DB...');
    console.log(`[Cosmos DB] 📊 Database: ${config.databaseId}`);
    console.log(`[Cosmos DB] 📦 Container: ${config.containerId}`);

    cosmosClient = new CosmosClient({
      endpoint: config.endpoint,
      key: config.key
    });

    // Obtener referencia a la base de datos y contenedor
    database = cosmosClient.database(config.databaseId);
    container = database.container(config.containerId);

    // Verificar conexión
    await container.read();
    console.log('[Cosmos DB] ✅ Conexión establecida exitosamente');

    return { client: cosmosClient, database, container };
  } catch (error) {
    console.error('[Cosmos DB] ❌ Error conectando:', error.message);
    throw error;
  }
}

/**
 * Obtener todas las promociones
 */
async function getAllPromociones() {
  try {
    if (!container) {
      await initCosmosDB();
    }

    const querySpec = {
      query: 'SELECT * FROM c WHERE c.autorizado = true ORDER BY c.createdAt DESC'
    };

    const { resources } = await container.items.query(querySpec).fetchAll();
    return resources;
  } catch (error) {
    console.error('[Cosmos DB] ❌ Error obteniendo promociones:', error.message);
    throw error;
  }
}

/**
 * Obtener promociones por matrícula
 * Devuelve:
 * - Promociones específicas para la matrícula
 * - Promociones generales (sin matrícula específica)
 */
async function getPromocionesByMatricula(matricula) {
  try {
    if (!container) {
      await initCosmosDB();
    }

    // Query para obtener promociones de la matrícula específica O sin matrícula (generales)
    const querySpec = {
      query: `
        SELECT * FROM c 
        WHERE c.autorizado = true 
        AND (c.matricula = @matricula OR NOT IS_DEFINED(c.matricula) OR c.matricula = null OR c.matricula = "")
        ORDER BY c.createdAt DESC
      `,
      parameters: [
        {
          name: '@matricula',
          value: matricula.toString()
        }
      ]
    };

    const { resources } = await container.items.query(querySpec).fetchAll();
    
    console.log(`[Cosmos DB] ✅ Encontradas ${resources.length} promociones para matrícula ${matricula}`);
    
    return resources;
  } catch (error) {
    console.error('[Cosmos DB] ❌ Error obteniendo promociones por matrícula:', error.message);
    throw error;
  }
}

/**
 * Obtener una promoción por ID
 */
async function getPromocionById(id) {
  try {
    if (!container) {
      await initCosmosDB();
    }

    const querySpec = {
      query: 'SELECT * FROM c WHERE c.id = @id',
      parameters: [
        {
          name: '@id',
          value: id
        }
      ]
    };

    const { resources } = await container.items.query(querySpec).fetchAll();
    return resources.length > 0 ? resources[0] : null;
  } catch (error) {
    console.error('[Cosmos DB] ❌ Error obteniendo promoción por ID:', error.message);
    throw error;
  }
}

/**
 * Registrar interacción (click, view, etc.)
 * Opcional: Si quieres trackear clicks en las promociones
 */
async function registrarInteraccion(promocionId, matricula, tipo = 'click') {
  try {
    // Si tienes un contenedor separado para interacciones, úsalo aquí
    // Por ahora solo logueamos
    console.log(`[Cosmos DB] 📊 Interacción registrada: ${tipo} en ${promocionId} por ${matricula}`);
    return true;
  } catch (error) {
    console.error('[Cosmos DB] ❌ Error registrando interacción:', error.message);
    return false;
  }
}

/**
 * Obtener estadísticas de promociones
 */
async function getEstadisticas() {
  try {
    if (!container) {
      await initCosmosDB();
    }

    // Contar total de promociones
    const countQuery = {
      query: 'SELECT VALUE COUNT(1) FROM c WHERE c.autorizado = true'
    };
    const { resources: countResult } = await container.items.query(countQuery).fetchAll();
    const total = countResult[0] || 0;

    // Contar por categoría
    const categoryQuery = {
      query: 'SELECT c.categoria, COUNT(1) as count FROM c WHERE c.autorizado = true GROUP BY c.categoria'
    };
    const { resources: categoryResult } = await container.items.query(categoryQuery).fetchAll();

    return {
      total,
      porCategoria: categoryResult
    };
  } catch (error) {
    console.error('[Cosmos DB] ❌ Error obteniendo estadísticas:', error.message);
    throw error;
  }
}

/**
 * Cerrar conexión (opcional, Cosmos DB maneja conexiones automáticamente)
 */
async function closeConnection() {
  // Cosmos DB Client no requiere cierre explícito
  console.log('[Cosmos DB] ℹ️  Conexión cerrada');
}

module.exports = {
  initCosmosDB,
  getAllPromociones,
  getPromocionesByMatricula,
  getPromocionById,
  registrarInteraccion,
  getEstadisticas,
  closeConnection,
  config
};
