# 🎯 PASOS PARA DESPLEGAR EN RENDER

## ✅ Código Subido a GitHub

El código del backend ya está en GitHub:
- Repository: `edukshare-max/edukshare-max.github.io`
- Branch: `desarrollo-mejoras`
- Path: `backend-sasu/`

Commit: `5143c1f` - "Backend SASU completo listo para despliegue en Render"

---

## 🚀 OPCIÓN 1: Despliegue Automático con Blueprint (RECOMENDADO)

### Paso 1: Acceder a Render
1. Ve a: https://dashboard.render.com
2. Inicia sesión o crea una cuenta (gratis)

### Paso 2: Crear Blueprint
1. Click en **"New +"** (botón azul arriba derecha)
2. Selecciona **"Blueprint"**
3. Conecta tu cuenta de GitHub si aún no lo has hecho

### Paso 3: Seleccionar Repositorio
1. Busca y selecciona: `edukshare-max.github.io`
2. Branch: `desarrollo-mejoras`
3. Render detectará automáticamente `backend-sasu/render.yaml`

### Paso 4: Revisar Configuración
Render mostrará lo que va a crear:
- ✅ **Web Service**: `carnet-alumnos-backend-sasu` (Node.js)
- ✅ **PostgreSQL Database**: `sasu-db` (Free tier)
- ✅ Variables de entorno automáticas

### Paso 5: Configurar Variables de Entorno Adicionales
Antes de hacer click en "Apply", agrega:

```
CORS_ORIGIN=https://edukshare-max.github.io,http://localhost:3000
```

### Paso 6: Apply
1. Click en **"Apply"**
2. Render comenzará a:
   - Crear la base de datos PostgreSQL
   - Instalar dependencias (`npm install`)
   - Iniciar el servidor (`npm start`)
   - Conectar ambos servicios

### Paso 7: Esperar Despliegue
- ⏳ Tarda aproximadamente **3-5 minutos**
- Verás logs en tiempo real
- Estado final: ✅ "Live"

### Paso 8: Obtener URL
Una vez desplegado:
1. Copia la URL que aparece (algo como: `https://carnet-alumnos-backend-sasu.onrender.com`)
2. Guarda esta URL, la necesitarás para Flutter

### Paso 9: Inicializar Base de Datos
1. En tu servicio desplegado, click en **"Shell"** (pestaña arriba)
2. Ejecuta:
```bash
npm run seed
```
3. Deberías ver:
```
🌱 Iniciando población de datos...
✅ Modelos sincronizados
✅ Categorías pobladas (7)
✅ Departamentos poblados (6)
✅ Promociones pobladas (12)
```

### Paso 10: Verificar
Prueba tu backend:
```bash
# Health check (copia la URL de tu servicio)
https://TU-SERVICIO.onrender.com/health
```

Deberías ver:
```json
{
  "status": "ok",
  "timestamp": "2025-10-09T...",
  "environment": "production"
}
```

---

## 🔄 OPCIÓN 2: Despliegue Manual (Si prefieres control total)

Si prefieres configurar manualmente, sigue la guía completa:
📖 `backend-sasu/DEPLOY_RENDER.md` - Sección "Opción B: Manual"

---

## 📱 Actualizar Flutter App

Una vez que tengas tu backend funcionando en Render:

### 1. Actualizar URL en Flutter
Edita `lib/services/api_service.dart`:

```dart
// Cambiar de:
final String baseUrl = 'https://carnet-alumnos-nodes.onrender.com';

// A (usa TU URL de Render):
final String baseUrl = 'https://carnet-alumnos-backend-sasu.onrender.com';
```

### 2. Recompilar Flutter Web
```bash
cd "C:\Users\gilbe\Documents\Carnet_digital _alumnos"
flutter build web --release
```

### 3. Iniciar servidor local para probar
```bash
cd build\web
python -m http.server 3000
```

### 4. Probar en navegador
Abre: http://localhost:3000

Login con:
- Matrícula: `15662`
- Password: `test123` (o la que uses)

Deberías ver **3 promociones reales**:
- 🏥 Jornada de Vacunación contra Influenza 2024
- 🧠 Taller de Salud Mental: Manejo del Estrés
- 🥗 Consulta Nutricional Gratuita

---

## 🐛 Si algo no funciona

### Backend no inicia
**Síntoma**: Error "Application failed to respond"
**Solución**: 
1. Ve a tu servicio → Environment
2. Verifica que `PORT=3000` esté configurado
3. Check logs para ver el error específico

### Base de datos no conecta
**Síntoma**: Error "Database connection failed"
**Solución**:
1. Verifica que la base de datos PostgreSQL esté "Live"
2. Check que `DATABASE_URL` esté en Environment Variables
3. Reinicia el servicio

### Promociones no aparecen
**Síntoma**: Flutter muestra promociones temporales
**Solución**:
1. Abre Shell en Render
2. Ejecuta: `npm run seed`
3. Verifica: `curl https://TU-SERVICIO.onrender.com/me/promociones -H "Authorization: Bearer TOKEN"`

### CORS Error
**Síntoma**: Error en consola del navegador sobre CORS
**Solución**:
1. Agrega tu dominio a `CORS_ORIGIN`:
   ```
   CORS_ORIGIN=https://edukshare-max.github.io,http://localhost:3000
   ```
2. Reinicia el servicio

---

## 💰 Sobre el Plan Free

⚠️ **Importante**:
- Después de **15 minutos sin actividad**, el servicio se "duerme"
- La primera petición después de dormir tarda **~30 segundos**
- Esto es normal en el plan Free

**Solución**: Configura un ping cada 10 minutos con:
- UptimeRobot: https://uptimerobot.com (gratis)
- Configurar ping a: `https://TU-SERVICIO.onrender.com/health`

---

## 📊 URLs Finales

Una vez configurado, tendrás:

| Servicio | URL |
|----------|-----|
| Backend API | `https://carnet-alumnos-backend-sasu.onrender.com` |
| Health Check | `https://carnet-alumnos-backend-sasu.onrender.com/health` |
| Login | `POST https://carnet-alumnos-backend-sasu.onrender.com/auth/login` |
| Promociones | `GET https://carnet-alumnos-backend-sasu.onrender.com/me/promociones` |
| Dashboard Render | https://dashboard.render.com |

---

## ✅ Checklist Final

Antes de dar por terminado:

- [ ] Backend desplegado y status "Live" en Render
- [ ] Base de datos PostgreSQL creada y conectada
- [ ] Comando `npm run seed` ejecutado exitosamente
- [ ] Health check responde correctamente
- [ ] Login funciona (prueba con Postman o curl)
- [ ] Endpoint `/me/promociones` devuelve las 12 promociones
- [ ] URL actualizada en Flutter (`api_service.dart`)
- [ ] Flutter recompilado con `flutter build web --release`
- [ ] Probado localmente y funciona
- [ ] Promociones reales aparecen (no temporales)

---

## 🎉 ¡Listo!

Si completaste todos los pasos, tu sistema SASU está 100% funcional con:
- ✅ Backend Node.js en producción
- ✅ Base de datos PostgreSQL con datos reales
- ✅ Flutter conectado al backend
- ✅ 12 promociones funcionando
- ✅ Autenticación JWT
- ✅ Sistema listo para usuarios

## 📞 Ayuda

Si necesitas ayuda:
1. 📖 Revisa `backend-sasu/DEPLOY_RENDER.md`
2. 🔍 Check logs en Render Dashboard
3. 🐛 Sección "Solución de Problemas" en `DEPLOY_RENDER.md`
