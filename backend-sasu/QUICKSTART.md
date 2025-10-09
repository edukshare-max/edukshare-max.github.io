# 🚀 GUÍA RÁPIDA DE INICIO - SASU Backend

## ⚡ Inicio Rápido (5 minutos)

### 1. Instalar Dependencias

```bash
cd backend-sasu
npm install
```

### 2. Configurar Entorno

```bash
# Copiar archivo de configuración
copy .env.example .env

# O en Linux/Mac:
# cp .env.example .env
```

### 3. Poblar Base de Datos

```bash
npm run seed
```

**Esto creará:**
- ✅ 7 categorías de promociones
- ✅ 6 departamentos de salud  
- ✅ 12 promociones (3 para matrícula 15662)

### 4. Iniciar Servidor

```bash
npm start
```

**El servidor estará en:** `http://localhost:3000`

---

## 📊 Verificar que Funciona

### Opción 1: Browser

Abre en tu navegador:
```
http://localhost:3000
```

Deberías ver la página de bienvenida de la API.

### Opción 2: PowerShell

```powershell
# Health check
Invoke-WebRequest -Uri "http://localhost:3000/health"

# Estadísticas
Invoke-WebRequest -Uri "http://localhost:3000/public/promociones/stats"
```

---

## 🔧 Estructura de URLs para Flutter

El cliente Flutter está configurado para usar:

```
baseUrl = https://carnet-alumnos-nodes.onrender.com
```

**Para desarrollo local**, cambia temporalmente en `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://localhost:3000';
```

---

## 📱 Probar Integración Completa

### Paso 1: Backend Ejecutándose

```bash
cd backend-sasu
npm start
```

### Paso 2: Compilar Flutter

```bash
cd ..  # Volver a raíz del proyecto
flutter build web --release
```

### Paso 3: Servir Flutter

```bash
cd build/web
python -m http.server 3000
```

### Paso 4: Abrir Browser

```
http://localhost:3000
```

### Paso 5: Login

- Email: `juan.perez@uagro.mx`
- Matrícula: `15662`

### Paso 6: Ver Promociones

Deberías ver **3 promociones específicas** para la matrícula 15662 en el carrusel Netflix:
1. 🏥 Consulta Médica Especializada
2. 🛡️ Campaña de Vacunación
3. 🥗 Seguimiento Nutricional

---

## 🎯 Próximos Pasos

### Para Desarrollo

1. **Agregar más promociones:**
   ```bash
   # Editar scripts/seedData.js
   # Agregar tus promociones
   npm run seed
   ```

2. **Ver logs en tiempo real:**
   ```bash
   npm run dev  # Usa nodemon para auto-reload
   ```

3. **Probar endpoints con cURL:**
   ```bash
   # Ver README.md sección "Testing"
   ```

### Para Producción

1. **Configurar MySQL:**
   ```bash
   # Editar .env
   DB_HOST=tu-servidor-mysql.com
   DB_NAME=sasu_production
   DB_USER=tu_usuario
   DB_PASSWORD=tu_password_seguro
   ```

2. **Cambiar JWT Secret:**
   ```bash
   # En .env
   JWT_SECRET=genera_un_secret_muy_largo_y_aleatorio
   ```

3. **Desplegar:**
   - Heroku, Railway, Render, o tu servidor preferido
   - Configurar variables de entorno
   - Ejecutar `npm run seed` en producción

---

## 🆘 Solución de Problemas

### "Cannot find module 'express'"

```bash
npm install
```

### "Port 3000 is already in use"

Cambia el puerto en `.env`:
```
PORT=3001
```

### "Promociones vacías en Flutter"

1. Verifica que el backend esté corriendo: `http://localhost:3000/health`
2. Verifica que la base de datos tenga datos: `http://localhost:3000/public/promociones/stats`
3. Revisa los logs en la consola de Flutter
4. Verifica que el token JWT sea válido

### "Database error"

```bash
# Recrear base de datos
rm -rf database/  # En Linux/Mac
# O eliminar carpeta database/ manualmente en Windows

npm run seed  # Repoblar
```

---

## 📚 Documentación Completa

Ver `README.md` para:
- Documentación completa de endpoints
- Estructura de base de datos
- Seguridad y validación
- Métricas y analytics
- Y mucho más...

---

## ✅ Checklist de Verificación

- [ ] Node.js instalado (v16+)
- [ ] npm install completado sin errores
- [ ] .env configurado
- [ ] npm run seed ejecutado exitosamente
- [ ] npm start funciona y muestra banner de inicio
- [ ] http://localhost:3000/health devuelve status OK
- [ ] http://localhost:3000/public/promociones/stats muestra estadísticas
- [ ] Flutter conecta y obtiene promociones

**¡Si todos los checkboxes están marcados, estás listo! 🎉**

---

## 📞 Ayuda

¿Problemas? Revisa:
1. `README.md` - Documentación completa
2. Logs del servidor en la terminal
3. Consola del browser (F12)
4. Network tab para ver requests

---

Creado con ❤️ para la Universidad Autónoma de Guerrero  
Sistema SASU - Promociones de Salud