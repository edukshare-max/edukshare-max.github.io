const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

/**
 * Modelo para Categorías de Promociones
 * Administra las diferentes categorías de promociones de salud
 */
const CategoriaPromocion = sequelize.define('CategoriaPromocion', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  nombre: {
    type: DataTypes.STRING(100),
    allowNull: false,
    unique: true,
    validate: {
      notEmpty: true,
      len: [2, 100]
    }
  },
  descripcion: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  color_hex: {
    type: DataTypes.STRING(7),
    defaultValue: '#4F46E5',
    validate: {
      is: /^#[0-9A-F]{6}$/i
    }
  },
  icono: {
    type: DataTypes.STRING(50),
    defaultValue: '🏥'
  },
  activo: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  }
}, {
  tableName: 'categorias_promociones',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  indexes: [
    {
      fields: ['activo']
    },
    {
      fields: ['nombre']
    }
  ]
});

/**
 * Modelo para Departamentos de Salud
 * Gestiona los departamentos que publican promociones
 */
const DepartamentoSalud = sequelize.define('DepartamentoSalud', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  nombre: {
    type: DataTypes.STRING(150),
    allowNull: false,
    unique: true,
    validate: {
      notEmpty: true,
      len: [3, 150]
    }
  },
  descripcion: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  contacto_email: {
    type: DataTypes.STRING(255),
    allowNull: true,
    validate: {
      isEmail: true
    }
  },
  contacto_telefono: {
    type: DataTypes.STRING(20),
    allowNull: true,
    validate: {
      is: /^[\+]?[\s\d\-\(\)]+$/
    }
  },
  ubicacion: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  activo: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  }
}, {
  tableName: 'departamentos_salud',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  indexes: [
    {
      fields: ['activo']
    },
    {
      fields: ['nombre']
    }
  ]
});

/**
 * Modelo principal para Promociones de Salud
 * Gestiona todas las promociones del sistema SASU
 */
const PromocionSalud = sequelize.define('PromocionSalud', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  titulo: {
    type: DataTypes.STRING(255),
    allowNull: false,
    validate: {
      notEmpty: true,
      len: [5, 255]
    }
  },
  descripcion: {
    type: DataTypes.TEXT,
    allowNull: false,
    validate: {
      notEmpty: true,
      len: [10, 5000]
    }
  },
  resumen: {
    type: DataTypes.STRING(500),
    allowNull: true,
    validate: {
      len: [0, 500]
    }
  },
  link: {
    type: DataTypes.STRING(500),
    allowNull: true,
    validate: {
      isUrl: {
        protocols: ['http', 'https'],
        require_protocol: true
      }
    }
  },
  imagen_url: {
    type: DataTypes.STRING(500),
    allowNull: true,
    validate: {
      isUrl: {
        protocols: ['http', 'https'],
        require_protocol: true
      }
    }
  },
  
  // Relaciones
  categoria_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: CategoriaPromocion,
      key: 'id'
    }
  },
  departamento_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: DepartamentoSalud,
      key: 'id'
    }
  },
  
  // Targeting y filtros
  matricula_target: {
    type: DataTypes.STRING(20),
    allowNull: true,
    validate: {
      len: [0, 20]
    }
  },
  carrera_target: {
    type: DataTypes.STRING(100),
    allowNull: true,
    validate: {
      len: [0, 100]
    }
  },
  semestre_target: {
    type: DataTypes.INTEGER,
    allowNull: true,
    validate: {
      min: 1,
      max: 12
    }
  },
  
  // Control de fechas
  fecha_inicio: {
    type: DataTypes.DATEONLY,
    allowNull: false,
    validate: {
      isDate: true,
      isAfter: '2020-01-01'
    }
  },
  fecha_fin: {
    type: DataTypes.DATEONLY,
    allowNull: false,
    validate: {
      isDate: true,
      isAfterStartDate(value) {
        if (value <= this.fecha_inicio) {
          throw new Error('La fecha de fin debe ser posterior a la fecha de inicio');
        }
      }
    }
  },
  fecha_publicacion: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  
  // Estados
  activo: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  destacado: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  urgente: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  
  // Metadata
  vistas: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    validate: {
      min: 0
    }
  },
  clicks: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    validate: {
      min: 0
    }
  },
  prioridad: {
    type: DataTypes.INTEGER,
    defaultValue: 5,
    validate: {
      min: 1,
      max: 10
    }
  }
}, {
  tableName: 'promociones_salud',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  indexes: [
    {
      fields: ['activo', 'fecha_inicio', 'fecha_fin']
    },
    {
      fields: ['matricula_target']
    },
    {
      fields: ['categoria_id']
    },
    {
      fields: ['departamento_id']
    },
    {
      fields: ['prioridad'],
      order: [['prioridad', 'DESC']]
    },
    {
      fields: ['destacado', 'activo']
    },
    {
      fields: ['urgente', 'activo']
    }
  ],
  scopes: {
    // Scope para promociones activas
    activas: {
      where: {
        activo: true,
        fecha_inicio: {
          [sequelize.Sequelize.Op.lte]: new Date()
        },
        fecha_fin: {
          [sequelize.Sequelize.Op.gte]: new Date()
        }
      }
    },
    
    // Scope para promociones destacadas
    destacadas: {
      where: {
        destacado: true,
        activo: true
      }
    },
    
    // Scope para promociones urgentes
    urgentes: {
      where: {
        urgente: true,
        activo: true
      }
    },
    
    // Scope para promociones por matrícula
    porMatricula: (matricula) => ({
      where: {
        [sequelize.Sequelize.Op.or]: [
          { matricula_target: null },
          { matricula_target: matricula }
        ]
      }
    })
  }
});

/**
 * Modelo para tracking de interacciones
 * Registra vistas, clicks y compartidos de promociones
 */
const PromocionInteraccion = sequelize.define('PromocionInteraccion', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  promocion_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: PromocionSalud,
      key: 'id'
    }
  },
  matricula: {
    type: DataTypes.STRING(20),
    allowNull: false,
    validate: {
      notEmpty: true,
      len: [1, 20]
    }
  },
  tipo_interaccion: {
    type: DataTypes.ENUM('vista', 'click', 'compartir'),
    allowNull: false
  },
  user_agent: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  ip_address: {
    type: DataTypes.STRING(45),
    allowNull: true,
    validate: {
      isIP: true
    }
  }
}, {
  tableName: 'promociones_interacciones',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false,
  indexes: [
    {
      fields: ['promocion_id', 'matricula']
    },
    {
      fields: ['matricula', 'created_at']
    },
    {
      fields: ['tipo_interaccion']
    }
  ]
});

// ============================================
// DEFINICIÓN DE RELACIONES
// ============================================

// PromocionSalud pertenece a CategoriaPromocion
PromocionSalud.belongsTo(CategoriaPromocion, {
  foreignKey: 'categoria_id',
  as: 'categoria'
});

// PromocionSalud pertenece a DepartamentoSalud
PromocionSalud.belongsTo(DepartamentoSalud, {
  foreignKey: 'departamento_id',
  as: 'departamento'
});

// CategoriaPromocion tiene muchas PromocionSalud
CategoriaPromocion.hasMany(PromocionSalud, {
  foreignKey: 'categoria_id',
  as: 'promociones'
});

// DepartamentoSalud tiene muchas PromocionSalud
DepartamentoSalud.hasMany(PromocionSalud, {
  foreignKey: 'departamento_id',
  as: 'promociones'
});

// PromocionSalud tiene muchas PromocionInteraccion
PromocionSalud.hasMany(PromocionInteraccion, {
  foreignKey: 'promocion_id',
  as: 'interacciones'
});

// PromocionInteraccion pertenece a PromocionSalud
PromocionInteraccion.belongsTo(PromocionSalud, {
  foreignKey: 'promocion_id',
  as: 'promocion'
});

// ============================================
// MÉTODOS DE INSTANCIA
// ============================================

PromocionSalud.prototype.estaActiva = function() {
  const hoy = new Date();
  const fechaInicio = new Date(this.fecha_inicio);
  const fechaFin = new Date(this.fecha_fin);
  
  return this.activo && 
         fechaInicio <= hoy && 
         fechaFin >= hoy;
};

PromocionSalud.prototype.esParaMatricula = function(matricula) {
  return !this.matricula_target || this.matricula_target === matricula;
};

PromocionSalud.prototype.incrementarVistas = async function() {
  this.vistas += 1;
  await this.save();
};

PromocionSalud.prototype.incrementarClicks = async function() {
  this.clicks += 1;
  await this.save();
};

PromocionSalud.prototype.registrarInteraccion = async function(matricula, tipo, userAgent = null, ipAddress = null) {
  await PromocionInteraccion.create({
    promocion_id: this.id,
    matricula: matricula,
    tipo_interaccion: tipo,
    user_agent: userAgent,
    ip_address: ipAddress
  });
  
  // Actualizar contadores
  if (tipo === 'vista') {
    await this.incrementarVistas();
  } else if (tipo === 'click') {
    await this.incrementarClicks();
  }
};

// ============================================
// MÉTODOS ESTÁTICOS
// ============================================

PromocionSalud.obtenerPorMatricula = async function(matricula, includeRelations = true) {
  const hoy = new Date();
  
  const options = {
    where: {
      activo: true,
      fecha_inicio: {
        [sequelize.Sequelize.Op.lte]: hoy
      },
      fecha_fin: {
        [sequelize.Sequelize.Op.gte]: hoy
      },
      [sequelize.Sequelize.Op.or]: [
        { matricula_target: null },
        { matricula_target: matricula }
      ]
    },
    order: [
      ['urgente', 'DESC'],
      ['destacado', 'DESC'],
      ['prioridad', 'DESC'],
      ['created_at', 'DESC']
    ]
  };
  
  if (includeRelations) {
    options.include = [
      {
        model: CategoriaPromocion,
        as: 'categoria',
        where: { activo: true }
      },
      {
        model: DepartamentoSalud,
        as: 'departamento',
        where: { activo: true }
      }
    ];
  }
  
  return await this.findAll(options);
};

PromocionSalud.obtenerDestacadas = async function(limite = 5) {
  const hoy = new Date();
  
  return await this.findAll({
    where: {
      activo: true,
      destacado: true,
      fecha_inicio: {
        [sequelize.Sequelize.Op.lte]: hoy
      },
      fecha_fin: {
        [sequelize.Sequelize.Op.gte]: hoy
      }
    },
    include: [
      {
        model: CategoriaPromocion,
        as: 'categoria',
        where: { activo: true }
      },
      {
        model: DepartamentoSalud,
        as: 'departamento',
        where: { activo: true }
      }
    ],
    order: [
      ['prioridad', 'DESC'],
      ['created_at', 'DESC']
    ],
    limit: limite
  });
};

PromocionSalud.obtenerEstadisticas = async function(promocionId) {
  const [vistas, clicks, compartidos] = await Promise.all([
    PromocionInteraccion.count({
      where: {
        promocion_id: promocionId,
        tipo_interaccion: 'vista'
      }
    }),
    PromocionInteraccion.count({
      where: {
        promocion_id: promocionId,
        tipo_interaccion: 'click'
      }
    }),
    PromocionInteraccion.count({
      where: {
        promocion_id: promocionId,
        tipo_interaccion: 'compartir'
      }
    })
  ]);
  
  return {
    vistas,
    clicks,
    compartidos,
    ctr: vistas > 0 ? (clicks / vistas * 100).toFixed(2) : 0
  };
};

// ============================================
// HOOKS DEL MODELO
// ============================================

PromocionSalud.addHook('beforeValidate', (promocion) => {
  // Asegurar que las fechas sean válidas
  if (promocion.fecha_inicio && promocion.fecha_fin) {
    const inicio = new Date(promocion.fecha_inicio);
    const fin = new Date(promocion.fecha_fin);
    
    if (fin <= inicio) {
      throw new Error('La fecha de fin debe ser posterior a la fecha de inicio');
    }
  }
  
  // Limpiar y validar URLs
  if (promocion.link) {
    promocion.link = promocion.link.trim();
  }
  
  if (promocion.imagen_url) {
    promocion.imagen_url = promocion.imagen_url.trim();
  }
});

PromocionSalud.addHook('afterCreate', (promocion) => {
  console.log(`Nueva promoción creada: ${promocion.titulo} (ID: ${promocion.id})`);
});

PromocionSalud.addHook('afterUpdate', (promocion) => {
  console.log(`Promoción actualizada: ${promocion.titulo} (ID: ${promocion.id})`);
});

module.exports = {
  PromocionSalud,
  CategoriaPromocion,
  DepartamentoSalud,
  PromocionInteraccion
};