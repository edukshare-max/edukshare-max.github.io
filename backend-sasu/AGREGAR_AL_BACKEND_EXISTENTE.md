# 📝 CÓDIGO PARA AGREGAR AL BACKEND EXISTENTE EN RENDER

## 🎯 Objetivo

Agregar el endpoint `/me/promociones` al backend que ya tienes en Render (https://carnet-alumnos-nodes.onrender.com).

---

## 📦 1. Instalar dependencia de Azure Cosmos DB

En tu backend de Render, agrega al `package.json`:

```json
"dependencies": {
  "@azure/cosmos": "^4.0.0",
  // ... tus otras dependencias existentes
}
```

---

## 📄 2. Crear archivo `cosmosdb.js` (configuración)

**Ubicación**: Donde tengas tus otros archivos de configuración (ej: `/config/cosmosdb.js`)

```javascript
const { CosmosClient } = require('@azure/cosmos');

// Configuración
const config = {
  endpoint: process.env.COSMOS_ENDPOINT || '',
  key: process.env.COSMOS_KEY || '',
  databaseId: process.env.COSMOS_DATABASE_ID || 'sasu_database',
  containerId: process.env.COSMOS_CONTAINER_ID || 'promociones_salud'
};

let container = null;

async function initCosmosDB() {
  if (!config.endpoint || !config.key) {
    throw new Error('Faltan credenciales de Cosmos DB');
  }

  const cosmosClient = new CosmosClient({
    endpoint: config.endpoint,
    key: config.key
  });

  const database = cosmosClient.database(config.databaseId);
  container = database.container(config.containerId);
  
  await container.read(); // Verificar conexión
  console.log('[Cosmos DB] ✅ Conectado a promociones_salud');
  
  return container;
}

async function getPromocionesByMatricula(matricula) {
  if (!container) await initCosmosDB();

  const querySpec = {
    query: `
      SELECT * FROM c 
      WHERE c.autorizado = true 
      AND (c.matricula = @matricula OR NOT IS_DEFINED(c.matricula) OR c.matricula = null OR c.matricula = "")
      ORDER BY c.createdAt DESC
    `,
    parameters: [{ name: '@matricula', value: matricula.toString() }]
  };

  const { resources } = await container.items.query(querySpec).fetchAll();
  return resources;
}

module.exports = { initCosmosDB, getPromocionesByMatricula };
```

---

## 📄 3. Agregar ruta en tu archivo de rutas

**Donde tengas las rutas de `/me/carnet` y `/me/citas`**, agrega esta ruta:

```javascript
const cosmosDB = require('./config/cosmosdb'); // Ajusta la ruta según tu estructura

// ... tus otras rutas existentes ...

// Ruta para obtener promociones
router.get('/me/promociones', authMiddleware, async (req, res) => {
  try {
    const matricula = req.user?.matricula || req.query.matricula;
    
    if (!matricula) {
      return res.status(400).json({
        success: false,
        message: 'Matrícula no proporcionada'
      });
    }

    console.log(`[Promociones] 🔍 Buscando para matrícula: ${matricula}`);

    // Obtener de Cosmos DB
    const promociones = await cosmosDB.getPromocionesByMatricula(matricula);

    // Mapear al formato esperado por Flutter
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
      programa: promo.programa || '',
      es_especifica: !!promo.matricula
    }));

    console.log(`[Promociones] ✅ Encontradas ${promocionesFormateadas.length}`);

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
});

// Endpoint para registrar clicks (opcional)
router.post('/me/promociones/:id/click', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const matricula = req.user?.matricula;
    
    console.log(`[Promociones] 📊 Click: ${id} por ${matricula}`);
    
    return res.status(200).json({
      success: true,
      message: 'Click registrado'
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error registrando click'
    });
  }
});
```

---

## ⚙️ 4. Agregar variables de entorno en Render

En tu servicio de Render (https://dashboard.render.com):

1. Ve a tu servicio: **carnet-alumnos-nodes**
2. Click en **"Environment"**
3. Agrega estas variables:

```
COSMOS_ENDPOINT=https://tu-cuenta.documents.azure.com:443/
COSMOS_KEY=tu-primary-key-de-cosmos-db
COSMOS_DATABASE_ID=sasu_database
COSMOS_CONTAINER_ID=promociones_salud
```

---

## 🔄 5. Desplegar cambios

Después de agregar el código:

```bash
git add .
git commit -m "feat: Agregar endpoint /me/promociones con Cosmos DB"
git push
```

Render detectará el push y desplegará automáticamente.

---

## ✅ 6. Verificar que funciona

```bash
# 1. Login (ya funciona en tu backend)
curl -X POST https://carnet-alumnos-nodes.onrender.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"matricula":"15662","password":"tu-password"}'

# Respuesta: { "token": "eyJhbG..." }

# 2. Obtener promociones (NUEVO ENDPOINT)
curl https://carnet-alumnos-nodes.onrender.com/me/promociones \
  -H "Authorization: Bearer TU_TOKEN_JWT"

# Respuesta esperada:
{
  "success": true,
  "data": [
    {
      "id": "promocion:...",
      "titulo": "Licenciatura",
      "categoria": "Promoción",
      "departamento": "Atención estudiantil",
      "link": "https://...",
      "matricula": "15662"
    }
  ],
  "count": 1,
  "matricula": "15662"
}
```

---

## 📁 Resumen de archivos a modificar

1. **`package.json`** - Agregar dependencia `@azure/cosmos`
2. **`config/cosmosdb.js`** (o donde tengas configs) - Nuevo archivo
3. **Tu archivo de rutas** (donde está `/me/carnet` y `/me/citas`) - Agregar ruta `/me/promociones`
4. **Variables de entorno en Render** - Agregar `COSMOS_*`

---

## 🎯 Resultado final

Tu backend en Render tendrá:

- ✅ `/auth/login` (ya existe)
- ✅ `/me/carnet` (ya existe)  
- ✅ `/me/citas` (ya existe)
- ✅ `/me/promociones` ← **NUEVO**

Y tu app Flutter ya funcionará porque el `api_service.dart` ya apunta a `https://carnet-alumnos-nodes.onrender.com`.

---

## 📞 Preguntas

¿Necesitas ayuda para agregar este código a tu backend existente en Render?
