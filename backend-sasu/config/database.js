const { Sequelize } = require('sequelize');
require('dotenv').config();

/**
 * Configuración de base de datos para SASU
 * Soporta MySQL, PostgreSQL y SQLite para desarrollo
 */

// Configuración por defecto
const config = {
  development: {
    dialect: 'sqlite',
    storage: './database/sasu_development.db',
    logging: console.log,
    define: {
      timestamps: true,
      underscored: false,
      createdAt: 'created_at',
      updatedAt: 'updated_at'
    }
  },
  
  test: {
    dialect: 'sqlite',
    storage: ':memory:',
    logging: false,
    define: {
      timestamps: true,
      underscored: false,
      createdAt: 'created_at',
      updatedAt: 'updated_at'
    }
  },
  
  production: {
    dialect: 'mysql',
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    database: process.env.DB_NAME || 'sasu_production',
    username: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    pool: {
      max: 20,
      min: 0,
      acquire: 30000,
      idle: 10000
    },
    logging: false,
    define: {
      timestamps: true,
      underscored: false,
      createdAt: 'created_at',
      updatedAt: 'updated_at'
    }
  }
};

// Detectar entorno
const environment = process.env.NODE_ENV || 'development';
const dbConfig = config[environment];

// Crear instancia de Sequelize
let sequelize;

if (process.env.DATABASE_URL) {
  // Usar URL de base de datos (para servicios cloud como Heroku)
  sequelize = new Sequelize(process.env.DATABASE_URL, {
    dialect: 'postgres',
    protocol: 'postgres',
    logging: environment === 'development' ? console.log : false,
    dialectOptions: {
      ssl: process.env.NODE_ENV === 'production' ? {
        require: true,
        rejectUnauthorized: false
      } : false
    },
    define: dbConfig.define
  });
} else {
  // Usar configuración manual
  sequelize = new Sequelize(dbConfig);
}

// Función para probar conexión
async function testConnection() {
  try {
    await sequelize.authenticate();
    console.log(`[Database] ✅ Conexión establecida (${environment})`);
    return true;
  } catch (error) {
    console.error('[Database] ❌ Error de conexión:', error);
    return false;
  }
}

// Función para sincronizar modelos
async function syncModels(options = {}) {
  try {
    await sequelize.sync(options);
    console.log('[Database] ✅ Modelos sincronizados');
    return true;
  } catch (error) {
    console.error('[Database] ❌ Error sincronizando modelos:', error);
    return false;
  }
}

// Función para cerrar conexión
async function closeConnection() {
  try {
    await sequelize.close();
    console.log('[Database] ✅ Conexión cerrada');
    return true;
  } catch (error) {
    console.error('[Database] ❌ Error cerrando conexión:', error);
    return false;
  }
}

module.exports = {
  sequelize,
  Sequelize,
  testConnection,
  syncModels,
  closeConnection,
  config,
  environment
};