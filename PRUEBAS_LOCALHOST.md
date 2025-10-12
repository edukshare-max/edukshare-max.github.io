# 🧪 GUÍA DE PRUEBAS EN LOCALHOST

## 📋 Prerequisitos

### 1. Backend Node.js (Puerto 3000)
- Node.js instalado
- MongoDB o base de datos configurada
- Variables de entorno configuradas

### 2. Frontend Flutter (Puerto 8080)
- Flutter SDK instalado
- Chrome instalado para web
- Dependencias de Flutter actualizadas

## 🚀 Paso 1: Preparar el Backend

### Opción A: Backend Existente (backend-sasu)

```powershell
# Navegar al directorio del backend
cd backend-sasu

# Instalar dependencias si es necesario
npm install

# Iniciar en modo desarrollo
npm run dev

# O con node directamente
node server.js
```

El backend debe estar corriendo en **http://localhost:3000**

### Opción B: Si no tienes backend local

Por ahora, el frontend está configurado para usar el backend en producción:
```
https://carnet-alumnos-nodes.onrender.com
```

Pero necesitas actualizar temporalmente para pruebas locales:

**En `lib/services/api_service.dart`, línea 13:**
```dart
// PARA PRUEBAS LOCALES: Descomentar esta línea
static const String baseUrl = 'http://localhost:3000';

// PARA PRODUCCIÓN: Usar esta línea
// static const String baseUrl = 'https://carnet-alumnos-nodes.onrender.com';
```

## 🚀 Paso 2: Preparar el Frontend Flutter

```powershell
# Navegar al directorio del proyecto
cd "C:\Users\gilbe\Documents\Carnet_digital _alumnos"

# Limpiar builds anteriores (opcional pero recomendado)
flutter clean

# Obtener dependencias
flutter pub get

# Ejecutar en modo desarrollo con Chrome
flutter run -d chrome --web-port 8080
```

El frontend estará disponible en **http://localhost:8080**

## 🧪 Paso 3: Flujo de Pruebas

### Test 1: Verificar Login Actual (Sin Registro)

1. Abrir **http://localhost:8080**
2. Debería aparecer la pantalla de login
3. Verificar que se vea el link "¿No tienes cuenta? Regístrate aquí"
4. Verificar campos: Matrícula + Contraseña

### Test 2: Acceder a Pantalla de Registro

1. Click en "¿No tienes cuenta? Regístrate aquí"
2. Debería aparecer la pantalla de registro
3. Verificar campos:
   - Correo Institucional
   - Matrícula
   - Contraseña
   - Confirmar Contraseña
   - Checkbox de términos
4. Verificar botón "Volver" funcione

### Test 3: Validaciones Frontend

**Prueba A: Campos vacíos**
```
1. Dejar todos los campos vacíos
2. Click en "Crear Cuenta"
3. Debería mostrar errores de validación
```

**Prueba B: Correo inválido**
```
1. Correo: "textosinformato"
2. Matrícula: "UAGRO-123456"
3. Password: "test123"
4. Confirmar: "test123"
5. Aceptar términos
6. Click "Crear Cuenta"
7. Debería mostrar error de formato de correo
```

**Prueba C: Contraseñas no coinciden**
```
1. Correo: "test@uagro.mx"
2. Matrícula: "UAGRO-123456"
3. Password: "test123"
4. Confirmar: "test456"  (diferente)
5. Aceptar términos
6. Click "Crear Cuenta"
7. Debería mostrar error "Las contraseñas no coinciden"
```

**Prueba D: Términos no aceptados**
```
1. Llenar todos los campos correctamente
2. NO marcar checkbox de términos
3. Click "Crear Cuenta"
4. Debería mostrar error "Debes aceptar los términos"
```

### Test 4: Intentar Registro (Requiere Backend)

**Nota**: Este test solo funcionará si el backend tiene implementado el endpoint `/auth/register`

```
1. Correo: "juan.perez@uagro.mx"  (debe existir en BD de carnets)
2. Matrícula: "UAGRO-123456"       (debe existir y coincidir)
3. Password: "miPassword123"
4. Confirmar: "miPassword123"
5. Aceptar términos
6. Click "Crear Cuenta"
7. Resultado esperado:
   - SI backend implementado: Mensaje de éxito o error específico
   - SI backend NO implementado: Error de conexión o 404
```

### Test 5: Login con Credenciales

**Nota**: Solo funciona si el registro fue exitoso o si ya existe un usuario

```
1. En pantalla de login
2. Matrícula: "UAGRO-123456"
3. Password: "miPassword123"
4. Click "Ingresar al Sistema"
5. Resultado esperado:
   - SI credenciales correctas: Acceso al carnet
   - SI incorrectas: Error "Credenciales incorrectas"
```

## 🔍 Verificación de Consola

Abre las DevTools de Chrome (F12) y verifica:

### Console Tab
Buscar mensajes como:
```
🔍 REGISTER REQUEST: http://localhost:3000/auth/register
📧 Email: xxx | 🎓 Matrícula: xxx
📊 REGISTER RESPONSE: XXX (XXXms)
```

o

```
🔍 LOGIN REQUEST: http://localhost:3000/auth/login
🎓 Matrícula: xxx
📊 LOGIN RESPONSE: XXX (XXXms)
```

### Network Tab
1. Filtrar por "Fetch/XHR"
2. Verificar requests a:
   - `/auth/register`
   - `/auth/login`
3. Ver respuestas del servidor

## ⚠️ Problemas Comunes

### Problema 1: "CORS Error"
```
Error: Access to fetch at 'http://localhost:3000' from origin 'http://localhost:8080' 
has been blocked by CORS policy
```

**Solución**: Configurar CORS en el backend
```javascript
// En server.js del backend
app.use(cors({
  origin: ['http://localhost:8080', 'http://127.0.0.1:8080'],
  credentials: true
}));
```

### Problema 2: "Connection Refused"
```
Error: Failed to connect to localhost:3000
```

**Solución**: 
1. Verificar que el backend esté corriendo
2. Verificar el puerto correcto (3000)
3. Revisar firewall

### Problema 3: "404 Not Found - /auth/register"
```
POST http://localhost:3000/auth/register 404
```

**Solución**: El backend aún no tiene implementado el endpoint de registro. Ver sección siguiente.

## 🛠️ Implementar Backend para Registro

Si el backend no tiene el endpoint `/auth/register`, necesitas agregarlo:

### Archivo: `routes/auth.js` (o similar)

```javascript
// POST /auth/register
router.post('/register', async (req, res) => {
  try {
    const { correo, matricula, password } = req.body;
    
    // 1. Validar datos
    if (!correo || !matricula || !password) {
      return res.status(400).json({
        success: false,
        errorType: 'VALIDATION',
        message: 'Todos los campos son requeridos'
      });
    }
    
    // 2. Buscar carnet en BD
    const carnet = await Carnet.findOne({ 
      correo: correo,
      matricula: matricula 
    });
    
    if (!carnet) {
      return res.status(404).json({
        success: false,
        errorType: 'NOT_FOUND',
        message: 'Carnet no encontrado. Acude a Servicios de Salud.'
      });
    }
    
    // 3. Verificar que no exista usuario
    const existingUser = await Usuario.findOne({ matricula });
    
    if (existingUser) {
      return res.status(409).json({
        success: false,
        errorType: 'ALREADY_EXISTS',
        message: 'Ya existe una cuenta con esta matrícula'
      });
    }
    
    // 4. Hashear contraseña
    const bcrypt = require('bcrypt');
    const passwordHash = await bcrypt.hash(password, 10);
    
    // 5. Crear usuario
    const newUser = new Usuario({
      matricula,
      passwordHash,
      createdAt: new Date()
    });
    
    await newUser.save();
    
    // 6. Respuesta exitosa
    res.status(201).json({
      success: true,
      message: 'Cuenta creada exitosamente'
    });
    
  } catch (error) {
    console.error('Error en registro:', error);
    res.status(500).json({
      success: false,
      errorType: 'SERVER',
      message: 'Error del servidor'
    });
  }
});
```

### Actualizar Login para usar Matrícula + Password

```javascript
// POST /auth/login
router.post('/login', async (req, res) => {
  try {
    const { matricula, password } = req.body;  // CAMBIO: antes era correo + matricula
    
    // 1. Buscar usuario
    const user = await Usuario.findOne({ matricula });
    
    if (!user) {
      return res.status(401).json({
        success: false,
        errorType: 'CREDENTIALS',
        message: 'Credenciales incorrectas'
      });
    }
    
    // 2. Verificar contraseña
    const bcrypt = require('bcrypt');
    const isValid = await bcrypt.compare(password, user.passwordHash);
    
    if (!isValid) {
      return res.status(401).json({
        success: false,
        errorType: 'CREDENTIALS',
        message: 'Credenciales incorrectas'
      });
    }
    
    // 3. Generar JWT
    const jwt = require('jsonwebtoken');
    const token = jwt.sign(
      { matricula: user.matricula },
      process.env.JWT_SECRET || 'tu_secreto_aqui',
      { expiresIn: '7d' }
    );
    
    // 4. Respuesta exitosa
    res.status(200).json({
      success: true,
      token,
      matricula: user.matricula
    });
    
  } catch (error) {
    console.error('Error en login:', error);
    res.status(500).json({
      success: false,
      errorType: 'SERVER',
      message: 'Error del servidor'
    });
  }
});
```

## 📝 Checklist de Pruebas

- [ ] Backend corriendo en localhost:3000
- [ ] Frontend corriendo en localhost:8080
- [ ] Pantalla de login se ve correctamente
- [ ] Link a registro funciona
- [ ] Pantalla de registro se ve correctamente
- [ ] Validaciones frontend funcionan
- [ ] Intento de registro se comunica con backend
- [ ] Backend responde apropiadamente
- [ ] Login con nuevas credenciales funciona
- [ ] Acceso al carnet después de login exitoso

## 🎯 Próximos Pasos Después de Pruebas

1. ✅ Verificar que todo funcione en localhost
2. ⏳ Implementar endpoints en backend de producción (Render)
3. ⏳ Actualizar baseUrl a producción en api_service.dart
4. ⏳ Hacer build de producción: `flutter build web --release`
5. ⏳ Desplegar a GitHub Pages
6. ⏳ Probar en app.carnetdigital.space

---

**Fecha**: 11 de Octubre, 2025
**Para**: Pruebas locales antes de producción
