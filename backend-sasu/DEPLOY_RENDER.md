# 🚀 Guía de Despliegue en Render

Esta guía te ayudará a desplegar el backend SASU en Render.

## 📋 Requisitos Previos

1. ✅ Cuenta en [Render](https://render.com) (gratis)
2. ✅ Repositorio Git con el código del backend
3. ✅ Código del backend en la carpeta `backend-sasu/`

## 🎯 Paso 1: Preparar el Repositorio

### 1.1 Verificar archivos necesarios

Asegúrate de tener estos archivos en `backend-sasu/`:

```
backend-sasu/
├── render.yaml          # ✅ Configuración de Render
├── package.json         # ✅ Dependencias Node.js
├── server.js            # ✅ Servidor principal
├── .env.example         # ✅ Variables de entorno de ejemplo
└── config/
    └── database.js      # ✅ Configuración de base de datos
```

### 1.2 Subir cambios a GitHub

```bash
# En la carpeta raíz del proyecto
git add backend-sasu/
git commit -m "feat: Backend SASU listo para despliegue en Render"
git push origin desarrollo-mejoras
```

## 🌐 Paso 2: Crear Servicio Web en Render

### Opción A: Usando Blueprint (Automático) 🎉

1. **Ir a Render Dashboard**: https://dashboard.render.com
2. **Click en "New +"** → **"Blueprint"**
3. **Conectar tu repositorio** de GitHub
4. **Buscar `render.yaml`** en el directorio `backend-sasu/`
5. **Configurar variables de entorno**:
   - `JWT_SECRET`: Click en "Generate" para crear una clave secreta
   - `NODE_ENV`: production
   - `PORT`: 3000
   - `CORS_ORIGIN`: https://edukshare-max.github.io,http://localhost:3000

6. **Click en "Apply"** - Render creará:
   - ✅ Servicio web (backend Node.js)
   - ✅ Base de datos PostgreSQL
   - ✅ Conexión automática entre ambos

### Opción B: Manual (Paso a paso)

#### 2.1 Crear Base de Datos PostgreSQL

1. Click en **"New +"** → **"PostgreSQL"**
2. **Configuración**:
   - Name: `sasu-db`
   - Database: `sasu_production`
   - User: `sasu_admin`
   - Region: `Oregon (US West)` o el más cercano
   - Plan: **Free**

3. Click en **"Create Database"**
4. **Copiar el "Internal Database URL"** (lo usaremos después)

#### 2.2 Crear Servicio Web

1. Click en **"New +"** → **"Web Service"**
2. **Conectar repositorio**:
   - Selecciona tu repositorio de GitHub
   - Branch: `desarrollo-mejoras`
   - Root Directory: `backend-sasu`

3. **Configuración básica**:
   - Name: `carnet-alumnos-backend-sasu`
   - Region: `Oregon (US West)`
   - Branch: `desarrollo-mejoras`
   - Runtime: **Node**
   - Build Command: `npm install`
   - Start Command: `npm start`
   - Plan: **Free**

4. **Variables de entorno** (Environment Variables):

   Click en "Advanced" y agrega:

   ```bash
   NODE_ENV=production
   PORT=3000
   DATABASE_URL=<PEGAR_URL_DE_POSTGRESQL>
   JWT_SECRET=<GENERAR_CLAVE_SEGURA>
   JWT_EXPIRATION=7d
   CORS_ORIGIN=https://edukshare-max.github.io,http://localhost:3000
   RATE_LIMIT_WINDOW_MS=900000
   RATE_LIMIT_MAX_REQUESTS=100
   ```

5. Click en **"Create Web Service"**

## 🔧 Paso 3: Configurar Base de Datos

Una vez desplegado el servicio, necesitas inicializar la base de datos:

### 3.1 Conectarse al Shell de Render

1. En el dashboard de tu servicio web
2. Click en **"Shell"** (terminal en línea)
3. Ejecutar:

```bash
# Instalar dependencias (si no se instalaron)
npm install

# Ejecutar script de seed para crear tablas y datos
npm run seed
```

### 3.2 Verificar datos

```bash
# En el shell de Render
node -e "
const { sequelize } = require('./config/database');
(async () => {
  try {
    await sequelize.authenticate();
    const result = await sequelize.query('SELECT COUNT(*) FROM promociones_salud');
    console.log('Promociones:', result[0][0].count);
  } catch (e) {
    console.error(e);
  }
})();
"
```

## ✅ Paso 4: Verificar Despliegue

### 4.1 Probar endpoints

Tu backend estará disponible en: `https://carnet-alumnos-backend-sasu.onrender.com`

Probar endpoints:

```bash
# Health check
curl https://carnet-alumnos-backend-sasu.onrender.com/health

# Login (ejemplo)
curl -X POST https://carnet-alumnos-backend-sasu.onrender.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"matricula":"15662","password":"test123"}'

# Obtener promociones (con token JWT)
curl https://carnet-alumnos-backend-sasu.onrender.com/me/promociones \
  -H "Authorization: Bearer TU_TOKEN_JWT"
```

### 4.2 Ver logs

En el dashboard de Render:
1. Selecciona tu servicio
2. Click en **"Logs"**
3. Verifica que no haya errores

## 🔄 Paso 5: Actualizar Flutter App

Ahora que el backend está en Render, actualiza la URL en tu app Flutter:

1. **Editar `lib/services/api_service.dart`**:

```dart
final String baseUrl = 'https://carnet-alumnos-backend-sasu.onrender.com';
```

2. **Recompilar Flutter**:

```bash
cd "C:\Users\gilbe\Documents\Carnet_digital _alumnos"
flutter build web --release
```

3. **Desplegar a GitHub Pages**:

```bash
# Copiar build a raíz del repo
cp -r build/web/* .

# Commit y push
git add .
git commit -m "chore: Actualizar URL del backend a Render"
git push origin desarrollo-mejoras
```

## 🐛 Solución de Problemas

### Error: "Application failed to respond"

**Causa**: El backend no está escuchando en el puerto correcto.

**Solución**: Verifica que `server.js` use `process.env.PORT`:

```javascript
const PORT = process.env.PORT || 3000;
```

### Error: "Database connection failed"

**Causa**: `DATABASE_URL` no está configurada o es incorrecta.

**Solución**: 
1. Ve a tu servicio en Render
2. Click en "Environment"
3. Verifica que `DATABASE_URL` esté configurada con la URL de PostgreSQL

### Error: "CORS policy"

**Causa**: El origen de tu Flutter app no está permitido.

**Solución**: Agrega tu URL de GitHub Pages a `CORS_ORIGIN`:

```
CORS_ORIGIN=https://edukshare-max.github.io,http://localhost:3000
```

### Promociones no aparecen

**Causa**: La base de datos no tiene datos.

**Solución**: Ejecuta el seed desde el Shell de Render:

```bash
npm run seed
```

## 📊 Monitoreo

### Ver estado del servicio

```bash
# Health check
curl https://carnet-alumnos-backend-sasu.onrender.com/health

# Estadísticas (si está implementado)
curl https://carnet-alumnos-backend-sasu.onrender.com/api/v1/stats
```

### Logs en tiempo real

En el dashboard de Render → **Logs** → **Live Logs**

## 💰 Consideraciones del Plan Free

⚠️ **Importante**: El plan Free de Render tiene limitaciones:

- ✅ **Gratis para siempre**
- 🐌 **Spin down después de 15 minutos de inactividad** (primera petición tarda ~30 segundos)
- 💾 **PostgreSQL Free**: 1 GB de almacenamiento
- 🔄 **Auto-deploys**: Cada push a GitHub
- 📦 **750 horas/mes**: Suficiente para desarrollo

### Para evitar spin down:

1. Usar un servicio de ping (cada 10 minutos): https://uptimerobot.com
2. O cambiar a plan Starter ($7/mes) para instancia siempre activa

## 🎉 ¡Listo!

Tu backend SASU ahora está desplegado en Render y listo para usar con tu app de Flutter.

**URLs importantes**:
- 🌐 Backend: `https://carnet-alumnos-backend-sasu.onrender.com`
- 📊 Dashboard: https://dashboard.render.com
- 📚 Docs Render: https://render.com/docs

## 📞 Soporte

Si tienes problemas:
1. Revisa los logs en Render
2. Verifica las variables de entorno
3. Consulta la documentación: `backend-sasu/README.md`
