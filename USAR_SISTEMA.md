# 🚀 GUÍA DE USO - Sistema Carnet Digital UAGro

## ✅ Configuración Actual

**Backend:** Render (https://carnet-alumnos-nodes.onrender.com)  
**Frontend:** Flutter Web en puerto 3000  
**Integración:** Flutter → Render → Base de Datos SASU

---

## 📋 Pasos para Iniciar el Sistema

### 1️⃣ Verificar que el Puerto 3000 esté Libre

```powershell
# Verificar si hay algo en el puerto 3000
netstat -ano | findstr :3000

# Si hay algo, liberar el puerto (reemplaza XXXX con el PID que aparece)
taskkill /F /PID XXXX
```

### 2️⃣ Compilar Flutter

```powershell
cd "c:\Users\gilbe\Documents\Carnet_digital _alumnos"
flutter build web --release
```

**Salida esperada:**
```
✓ Built build\web
```

### 3️⃣ Servir Flutter en Puerto 3000

```powershell
cd "c:\Users\gilbe\Documents\Carnet_digital _alumnos\build\web"
python -m http.server 3000
```

**Salida esperada:**
```
Serving HTTP on :: port 3000 (http://[::]:3000/) ...
```

### 4️⃣ Abrir en Navegador

Abre tu navegador en:
```
http://localhost:3000
```

---

## 🔐 Credenciales de Prueba

**Email:** `juan.perez@uagro.mx`  
**Matrícula:** `15662`

---

## 📊 Arquitectura del Sistema

```
┌─────────────────────────────────────────────────┐
│   NAVEGADOR (localhost:3000)                    │
│   - Flutter Web App                             │
│   - Carnet Digital                              │
│   - Carrusel Netflix de Promociones             │
└──────────────────┬──────────────────────────────┘
                   │
                   │ HTTPS
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│   BACKEND RENDER                                │
│   https://carnet-alumnos-nodes.onrender.com    │
│   - Node.js + Express                           │
│   - JWT Authentication                          │
│   - REST API                                    │
└──────────────────┬──────────────────────────────┘
                   │
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│   BASE DE DATOS                                 │
│   - Estudiantes                                 │
│   - Carnets                                     │
│   - Promociones SASU                            │
└─────────────────────────────────────────────────┘
```

---

## 🎯 Endpoints Disponibles

### Backend Render:

**Autenticación:**
- `POST /auth/login` - Login con email y matrícula

**Carnet:**
- `GET /me/carnet` - Obtener mi carnet (requiere JWT)

**Promociones SASU:**
- `GET /me/promociones` - Mis promociones de salud (requiere JWT)
- `POST /me/promociones/:id/click` - Registrar click

**Públicos:**
- `GET /health` - Health check del servidor
- `GET /public/promociones/stats` - Estadísticas generales

---

## 🔧 Comandos Útiles

### Recompilar Flutter Después de Cambios

```powershell
cd "c:\Users\gilbe\Documents\Carnet_digital _alumnos"
flutter clean
flutter pub get
flutter build web --release
```

### Ver Logs de Red en el Navegador

1. Presiona `F12` para abrir DevTools
2. Ve a la pestaña **Network**
3. Filtra por "XHR" para ver las peticiones API
4. Busca las peticiones a `carnet-alumnos-nodes.onrender.com`

### Verificar Conexión con Render

```powershell
# PowerShell
Invoke-RestMethod -Uri "https://carnet-alumnos-nodes.onrender.com/health"

# O con curl
curl https://carnet-alumnos-nodes.onrender.com/health
```

---

## 📱 Funcionalidades del Sistema

### ✅ Implementadas:

1. **Login con Matrícula y Email**
   - Autenticación JWT
   - Sesión persistente

2. **Visualización de Carnet Digital**
   - QR Code del estudiante
   - Datos personales
   - Foto

3. **Carrusel Netflix de Promociones SASU**
   - Promociones de salud
   - Categorías con colores
   - Filtrado por matrícula
   - Tracking de clicks

4. **Gestión de Citas Médicas**
   - Ver citas pendientes
   - Historial de citas

---

## 🐛 Troubleshooting

### ❌ Problema: "Port 3000 is already in use"

**Solución:**
```powershell
netstat -ano | findstr :3000
taskkill /F /PID [PID_DEL_PROCESO]
```

### ❌ Problema: "Failed to compile application"

**Solución:**
```powershell
cd "c:\Users\gilbe\Documents\Carnet_digital _alumnos"
flutter clean
flutter pub get
flutter build web --release
```

### ❌ Problema: "Cannot connect to Render backend"

**Verificar:**
1. Conexión a internet
2. Backend está desplegado en Render
3. URL correcta en `lib/services/api_service.dart`:
   ```dart
   static const String baseUrl = 'https://carnet-alumnos-nodes.onrender.com';
   ```

### ❌ Problema: "Login failed"

**Verificar:**
1. Email y matrícula correctos
2. Backend Render está activo (puede tardar 30s en iniciar si estaba dormido)
3. Revisar logs del navegador (F12 → Console)

---

## 📝 Archivos Importantes

### Flutter (Frontend):
- `lib/services/api_service.dart` - Conexión con backend
- `lib/screens/login_screen.dart` - Pantalla de login
- `lib/screens/home_screen.dart` - Pantalla principal con carrusel
- `lib/models/promocion_salud_model.dart` - Modelo de promociones

### Backend (Ya desplegado en Render):
- Repositorio separado
- URL: https://carnet-alumnos-nodes.onrender.com

---

## 🚀 Despliegue en Producción

### Opción 1: GitHub Pages (Recomendado)

1. **Preparar build:**
   ```powershell
   flutter build web --release --base-href "/carnet-digital/"
   ```

2. **Subir a GitHub:**
   ```powershell
   cd build/web
   git init
   git add .
   git commit -m "Deploy Flutter Web"
   git branch -M gh-pages
   git remote add origin https://github.com/tu-usuario/carnet-digital.git
   git push -f origin gh-pages
   ```

3. **Activar GitHub Pages:**
   - Ve a Settings → Pages
   - Source: gh-pages branch
   - URL: `https://tu-usuario.github.io/carnet-digital/`

### Opción 2: Netlify

1. Arrastra la carpeta `build/web` a https://app.netlify.com/drop
2. Listo! Netlify te dará una URL automática

### Opción 3: Vercel

```powershell
# Instalar Vercel CLI
npm i -g vercel

# Desplegar
cd build/web
vercel
```

---

## ✅ Checklist de Verificación

Antes de usar el sistema, verifica:

- [ ] Puerto 3000 libre
- [ ] Flutter compilado (`flutter build web --release`)
- [ ] Servidor HTTP corriendo en puerto 3000
- [ ] Navegador abierto en `http://localhost:3000`
- [ ] Backend Render activo (prueba con /health)
- [ ] Login funcional con matrícula 15662

---

## 📞 Soporte

**Sistema:** Carnet Digital UAGro  
**Última Actualización:** 2025-10-09  
**Estado:** ✅ Funcional con Backend Render

---

¡Todo listo para usar! 🎉
