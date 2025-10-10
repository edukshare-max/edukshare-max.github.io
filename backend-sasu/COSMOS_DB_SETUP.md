# 🔵 CONFIGURACIÓN DE AZURE COSMOS DB EN RENDER

## 📋 Requisitos Previos

1. ✅ Cuenta de Azure Cosmos DB con el contenedor `promociones_salud`
2. ✅ Endpoint de Cosmos DB (ej: `https://tu-cuenta.documents.azure.com:443/`)
3. ✅ Primary Key o Secondary Key de Cosmos DB

---

## 🔑 Obtener Credenciales de Cosmos DB

### Opción 1: Desde Azure Portal

1. Ve al **Azure Portal**: https://portal.azure.com
2. Navega a tu **Cosmos DB Account**
3. En el menú izquierdo, click en **"Keys"**
4. Copia:
   - **URI** (COSMOS_ENDPOINT)
   - **PRIMARY KEY** o **SECONDARY KEY** (COSMOS_KEY)

### Opción 2: Desde Azure CLI

```bash
# Login
az login

# Obtener endpoint
az cosmosdb show --name TU-CUENTA --resource-group TU-GRUPO --query documentEndpoint

# Obtener key
az cosmosdb keys list --name TU-CUENTA --resource-group TU-GRUPO --query primaryMasterKey
```

---

## ⚙️ Configurar Variables de Entorno en Render

### Paso 1: Ir a tu Servicio en Render

1. Dashboard: https://dashboard.render.com
2. Selecciona tu servicio: `carnet-alumnos-backend-sasu`
3. Click en **"Environment"** (pestaña superior)

### Paso 2: Agregar Variables de Cosmos DB

Click en **"Add Environment Variable"** y agrega:

#### COSMOS_ENDPOINT
```
Key: COSMOS_ENDPOINT
Value: https://tu-cuenta.documents.azure.com:443/
```

#### COSMOS_KEY
```
Key: COSMOS_KEY
Value: TU_PRIMARY_O_SECONDARY_KEY_AQUI
```

#### COSMOS_DATABASE_ID
```
Key: COSMOS_DATABASE_ID
Value: sasu_database
```
*(O el nombre de tu base de datos en Cosmos DB)*

#### COSMOS_CONTAINER_ID
```
Key: COSMOS_CONTAINER_ID
Value: promociones_salud
```

### Paso 3: Guardar y Reiniciar

1. Click en **"Save Changes"**
2. El servicio se reiniciará automáticamente
3. Verifica los logs para confirmar conexión exitosa

---

## ✅ Verificar Conexión

Una vez desplegado, verifica que el backend se conectó correctamente:

### 1. Check Logs

En Render Dashboard → Tu Servicio → **Logs**

Deberías ver:
```
[SASU] 🔄 Iniciando conexión a Azure Cosmos DB...
[Cosmos DB] 🔄 Conectando a Azure Cosmos DB...
[Cosmos DB] 📊 Database: sasu_database
[Cosmos DB] 📦 Container: promociones_salud
[Cosmos DB] ✅ Conexión establecida exitosamente
[SASU] ✅ Conexión a Cosmos DB establecida
[SASU] ℹ️  Backend configurado en modo SOLO LECTURA
```

### 2. Test Health Check

```bash
curl https://tu-servicio.onrender.com/health
```

Respuesta esperada:
```json
{
  "status": "ok",
  "timestamp": "2025-10-09T...",
  "environment": "production"
}
```

### 3. Test Promociones Endpoint

```bash
# Login primero para obtener token JWT
curl -X POST https://tu-servicio.onrender.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"matricula":"15662","password":"tu-password"}'

# Usar el token para obtener promociones
curl https://tu-servicio.onrender.com/me/promociones \
  -H "Authorization: Bearer TU_TOKEN_JWT"
```

Respuesta esperada:
```json
{
  "success": true,
  "data": [
    {
      "id": "promocion:...",
      "titulo": "...",
      "categoria": "Promoción",
      "departamento": "Atención estudiantil",
      ...
    }
  ],
  "count": 2,
  "matricula": "15662"
}
```

---

## 🐛 Solución de Problemas

### Error: "Faltan credenciales de Cosmos DB"

**Causa**: No están configuradas `COSMOS_ENDPOINT` o `COSMOS_KEY`

**Solución**:
1. Ve a Environment Variables en Render
2. Verifica que ambas variables estén configuradas
3. Asegúrate de NO tener espacios al inicio/final
4. Reinicia el servicio

### Error: "Unauthorized" o 401 al conectar

**Causa**: La `COSMOS_KEY` es incorrecta o expiró

**Solución**:
1. Regenera la key en Azure Portal
2. Actualiza `COSMOS_KEY` en Render
3. Reinicia el servicio

### Error: "Database not found"

**Causa**: El nombre de la base de datos o contenedor es incorrecto

**Solución**:
1. Verifica el nombre exacto en Azure Portal
2. Actualiza `COSMOS_DATABASE_ID` y `COSMOS_CONTAINER_ID`
3. Asegúrate de que el contenedor existe

### No aparecen promociones

**Causa 1**: No hay datos en el contenedor
**Solución**: Agrega promociones desde la app de administración

**Causa 2**: El query no encuentra promociones para esa matrícula
**Solución**: 
- Verifica que haya promociones con `matricula = "15662"` O
- Promociones generales (sin campo `matricula` o `matricula = null`)

---

## 🔒 Seguridad de Credenciales

### ⚠️ NUNCA:
- ❌ Subir credenciales al repositorio Git
- ❌ Compartir las keys en mensajes públicos
- ❌ Usar Primary Key si Secondary Key es suficiente
- ❌ Dejar las keys en archivos locales `.env`

### ✅ SIEMPRE:
- ✅ Usar variables de entorno en Render
- ✅ Rotar las keys periódicamente
- ✅ Usar permisos de solo lectura si es posible
- ✅ Mantener `.env` en `.gitignore`

---

## 📊 Resumen de Variables

| Variable | Dónde obtenerla | Ejemplo |
|----------|----------------|---------|
| `COSMOS_ENDPOINT` | Azure Portal → Keys → URI | `https://sasu-db.documents.azure.com:443/` |
| `COSMOS_KEY` | Azure Portal → Keys → Primary Key | `xYz123...` |
| `COSMOS_DATABASE_ID` | Nombre de tu BD en Cosmos | `sasu_database` |
| `COSMOS_CONTAINER_ID` | Nombre del contenedor | `promociones_salud` |

---

## 🎯 Flujo Completo

```
┌─────────────────────────────────────┐
│  APP DE ADMINISTRACIÓN              │
│  Crea/edita promociones             │
└────────────┬────────────────────────┘
             │
             │ INSERT/UPDATE
             ↓
┌─────────────────────────────────────┐
│  AZURE COSMOS DB                    │
│  Container: promociones_salud       │
│  - Promoción 1 (matricula: 15662)   │
│  - Promoción 2 (general)            │
│  - Promoción 3 (matricula: 20123)   │
└────────────┬────────────────────────┘
             │
             │ SELECT (solo lectura)
             ↓
┌─────────────────────────────────────┐
│  BACKEND EN RENDER                  │
│  - Lee promociones de Cosmos DB     │
│  - Filtra por matrícula             │
│  - Sirve API REST                   │
└────────────┬────────────────────────┘
             │
             │ HTTP/JSON
             ↓
┌─────────────────────────────────────┐
│  FLUTTER APP                        │
│  Muestra promociones al usuario     │
└─────────────────────────────────────┘
```

---

## 📞 Necesitas Ayuda?

Si tienes problemas con la configuración:
1. Verifica los logs en Render
2. Confirma que las credenciales son correctas en Azure
3. Asegúrate de que el contenedor existe y tiene datos
4. Revisa que el backend tenga acceso de red a Cosmos DB
