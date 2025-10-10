# 🎯 INTEGRACIÓN FLUTTER + BACKEND SASU

## ✅ Estado Actual

### 🔧 Backend SASU (Node.js + Express)
- **Puerto:** http://localhost:3000
- **Estado:** ✅ Funcionando
- **Base de Datos:** SQLite con 12 promociones reales
- **Endpoints Activos:**
  - `GET /health` - Health check
  - `GET /public/promociones/stats` - Estadísticas públicas
  - `GET /public/promociones/categorias` - Categorías (7 activas)
  - `GET /public/promociones/departamentos` - Departamentos (6 activos)
  - `GET /me/promociones` - Promociones del estudiante (requiere JWT)
  - `POST /me/promociones/:id/click` - Registrar click

### 📱 Flutter Web App
- **Puerto:** http://localhost:8080
- **Estado:** ✅ Compilando/Ejecutando
- **Configuración:** Conectado a backend local
- **Cambios Realizados:**
  - ✅ `baseUrl` cambiado a `http://localhost:3000`
  - ✅ Login temporal implementado (verifica health check)
  - ✅ Endpoint `/me/promociones` configurado
  - ✅ Fallback a endpoints públicos si falla autenticación

---

## 🗂️ Datos en la Base de Datos

### Promociones para Matrícula 15662 (3 específicas):
1. **Consulta Médica Especializada** - Categoría: Consulta Médica
2. **Campaña de Vacunación - Registro Confirmado** - Categoría: Prevención
3. **Seguimiento Nutricional Personalizado** - Categoría: Nutrición

### Promociones Generales (7 para todos):
4. Servicio de Nutrición - Evaluación Gratuita
5. Apoyo Psicológico - Sesiones Individuales
6. Actualización de Expediente Médico
7. Programa de Actividad Física
8. Campaña de Donación de Sangre
9. Taller de Manejo del Estrés Académico
10. Servicio de Emergencias 24/7

### Promociones para Otras Matrículas (2):
11. Cita de Seguimiento - Estudiante 12345
12. Evaluación Psicológica Programada - Estudiante 67890

---

## 🚀 Cómo Usar el Sistema

### 1. Iniciar Backend SASU
```powershell
cd "c:\Users\gilbe\Documents\Carnet_digital _alumnos\backend-sasu"
node server.js
```

**Salida esperada:**
```
╔══════════════════════════════════════════════════════════════╗
║                     SASU SERVER INICIADO                     ║
╠══════════════════════════════════════════════════════════════╣
║ Puerto: 3000                                                  ║
║ Entorno: development                                         ║
║ URL: http://localhost:3000                                   ║
╚══════════════════════════════════════════════════════════════╝
```

### 2. Ejecutar Flutter
```powershell
cd "c:\Users\gilbe\Documents\Carnet_digital _alumnos"
flutter run -d edge --web-port=8080
```

**O compilar para producción:**
```powershell
flutter build web --release
```

### 3. Probar Login
- **Email:** `juan.perez@uagro.mx`
- **Matrícula:** `15662`

El sistema verificará que el backend esté disponible y generará un token temporal.

---

## 🔍 Endpoints para Probar

### Sin Autenticación (Públicos):
```bash
# Health Check
curl http://localhost:3000/health

# Estadísticas
curl http://localhost:3000/public/promociones/stats

# Categorías
curl http://localhost:3000/public/promociones/categorias

# Departamentos
curl http://localhost:3000/public/promociones/departamentos
```

### Con Autenticación (requiere JWT token):
```bash
# Obtener token mock desde Flutter al hacer login

# Promociones del estudiante
curl -H "Authorization: Bearer TOKEN_AQUI" http://localhost:3000/me/promociones

# Registrar click
curl -X POST -H "Authorization: Bearer TOKEN_AQUI" http://localhost:3000/me/promociones/1/click
```

---

## 📊 Flujo de Autenticación Actual

1. Usuario ingresa email y matrícula en Flutter
2. Flutter verifica `GET /health` del backend
3. Si backend está disponible:
   - Genera token temporal mock
   - Guarda matricula y email
   - Redirige a pantalla principal
4. Si backend no está disponible:
   - Intenta backend de producción
   - Si falla, muestra error

---

## 🎨 Características del Carrusel Netflix

El carrusel muestra promociones con:
- ✅ Categorías con colores (7 categorías con hex colors)
- ✅ Iconos emoji por categoría (🏥, 🛡️, 🚨, 🧠, 🥗, ⚽, ℹ️)
- ✅ Prioridad (1-10, default 5)
- ✅ Destacado (flag boolean)
- ✅ Urgente (flag boolean)
- ✅ Específicas para matrícula (es_especifica flag)
- ✅ Fechas de inicio/fin
- ✅ Tracking de vistas y clicks

---

## 🔐 Pendientes (TODO)

### Backend:
- [ ] Implementar endpoint `/auth/login` real con validación
- [ ] Agregar modelo Usuario a Sequelize
- [ ] Implementar JWT con secret seguro
- [ ] Agregar middleware de verificación de matrícula
- [ ] Implementar refresh token

### Flutter:
- [ ] Reemplazar token mock con JWT real
- [ ] Agregar manejo de token expirado
- [ ] Implementar logout
- [ ] Persistir sesión (SharedPreferences)
- [ ] Agregar pull-to-refresh en promociones

### Base de Datos:
- [ ] Migrar de SQLite a MySQL/PostgreSQL para producción
- [ ] Agregar más promociones reales
- [ ] Implementar sistema de notificaciones push
- [ ] Agregar analytics de promociones más vistas

---

## 🌐 Para Desplegar a Producción

### Backend:
1. Configurar MySQL/PostgreSQL
2. Actualizar `.env`:
   ```env
   NODE_ENV=production
   DB_HOST=tu-servidor.com
   DB_NAME=sasu_production
   DB_USER=usuario
   DB_PASSWORD=password_seguro
   JWT_SECRET=secret_muy_largo_y_aleatorio
   ```
3. Desplegar en Render/Heroku/Railway
4. Ejecutar `npm run seed` en producción

### Flutter:
1. Cambiar `baseUrl` a URL de producción
2. Compilar: `flutter build web --release`
3. Desplegar build/web en hosting (GitHub Pages, Netlify, Vercel)
4. Configurar CORS en backend para permitir dominio de producción

---

## 📝 Archivos Modificados

### Backend:
- ✅ `backend-sasu/server.js` - Servidor Express
- ✅ `backend-sasu/models/PromocionSalud.js` - Modelos Sequelize
- ✅ `backend-sasu/controllers/PromocionesController.js` - Lógica de negocio
- ✅ `backend-sasu/routes/promociones.js` - Rutas API
- ✅ `backend-sasu/middleware/authMiddleware.js` - Autenticación JWT
- ✅ `backend-sasu/middleware/rateLimitMiddleware.js` - Rate limiting
- ✅ `backend-sasu/database/schema.sql` - Esquema de base de datos
- ✅ `backend-sasu/scripts/seedData.js` - Datos de prueba

### Flutter:
- ✅ `lib/services/api_service.dart` - Conexión con backend
  - Cambiado baseUrl a localhost:3000
  - Login temporal con health check
  - Endpoint /me/promociones configurado
  - Fallback a endpoints públicos

---

## ✅ Verificación Final

**Checklist de Funcionamiento:**
- [x] Backend corriendo en puerto 3000
- [x] Base de datos con 12 promociones
- [x] Endpoints públicos funcionando
- [x] Flutter compilado sin errores
- [x] Flutter ejecutándose en puerto 8080
- [x] Conexión Flutter → Backend configurada
- [ ] Login funcional (mock temporal activo)
- [ ] Carrusel mostrando promociones reales

---

## 🆘 Troubleshooting

### "Backend no responde"
```bash
# Verificar que el servidor está corriendo
netstat -ano | findstr :3000

# Reiniciar servidor
cd backend-sasu
node server.js
```

### "No se ven las promociones"
1. Verificar que backend está corriendo
2. Abrir consola del navegador (F12)
3. Buscar logs de red (Network tab)
4. Verificar que `GET /me/promociones` retorna 200

### "Error de compilación Flutter"
```bash
# Limpiar cache
flutter clean
flutter pub get
flutter build web --release
```

---

**Creado:** 2025-10-09  
**Última actualización:** 2025-10-09  
**Estado:** ✅ Backend funcionando, Flutter conectado