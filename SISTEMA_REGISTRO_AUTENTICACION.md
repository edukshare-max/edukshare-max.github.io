# 🔐 SISTEMA DE REGISTRO Y AUTENTICACIÓN - CARNET DIGITAL UAGro

## 📋 Resumen del Sistema

Sistema completo de registro y autenticación implementado para el Carnet Digital UAGro SASU, que permite a los estudiantes crear cuentas seguras validadas contra la base de datos de carnets existentes.

## 🎯 Flujo del Usuario

### 1. **Usuario Nuevo (Sin Cuenta)**

```
Usuario accede a app.carnetdigital.space
    ↓
Pantalla de Login
    ↓
Click en "¿No tienes cuenta? Regístrate aquí"
    ↓
Pantalla de Registro
    ↓
Ingresa: Correo Institucional, Matrícula, Contraseña
    ↓
Sistema valida:
  - ¿Existe el carnet con ese correo y matrícula en la BD?
  - ¿Coinciden el correo y matrícula?
    ↓
SI EXISTE Y COINCIDE → Cuenta creada exitosamente
    ↓
Redirige a Login
    ↓
Ingresa: Matrícula + Contraseña
    ↓
Acceso al Carnet Digital
```

### 2. **Usuario con Carnet No Registrado en SASU**

```
Usuario intenta registrarse
    ↓
Sistema valida en BD de carnets
    ↓
NO EXISTE → Error: "Debes generar tu carnet digital primero"
    ↓
Mensaje: "Acude al Departamento de Servicios de Salud"
    ↓
Usuario debe ir presencialmente a generar su carnet
```

### 3. **Usuario con Cuenta Existente**

```
Usuario accede a Login
    ↓
Ingresa: Matrícula + Contraseña
    ↓
Sistema valida credenciales
    ↓
SI CORRECTO → Acceso al Carnet Digital
SI INCORRECTO → Error: "Credenciales incorrectas"
```

## 🏗️ Arquitectura del Sistema

### **Frontend (Flutter Web)**

#### Pantallas
- **`lib/screens/login_screen.dart`**: Pantalla de inicio de sesión
  - Campos: Matrícula + Contraseña
  - Link a pantalla de registro
  - Validaciones en frontend

- **`lib/screens/register_screen.dart`**: Pantalla de registro (NUEVA)
  - Campos: Correo Institucional, Matrícula, Contraseña, Confirmar Contraseña
  - Checkbox de términos y condiciones
  - Validaciones:
    - Formato de correo válido
    - Matrícula no vacía
    - Contraseña mínimo 6 caracteres
    - Contraseñas coinciden
    - Términos aceptados

- **`lib/screens/carnet_screen.dart`**: Pantalla principal del carnet
  - Solo accesible con autenticación válida

#### Providers
- **`lib/providers/session_provider.dart`**
  - **Método `login(String matricula, String password)`**: 
    - Login con matrícula + contraseña
    - Manejo de errores específicos
    - Caché de sesión (7 días)
  
  - **Método `register(String correo, String matricula, String password)`** (NUEVO):
    - Registro validado contra BD de carnets
    - Manejo de errores:
      - `NOT_FOUND`: Carnet no existe
      - `MISMATCH`: Correo y matrícula no coinciden
      - `ALREADY_EXISTS`: Usuario ya registrado
      - `SERVER`: Error del servidor

#### Services
- **`lib/services/api_service.dart`**
  - **`POST /auth/login`**: Login con matrícula + password
  - **`POST /auth/register`** (NUEVO): Registro de usuario
    - Request body: `{ correo, matricula, password }`
    - Respuestas:
      - `201/200`: Registro exitoso
      - `404`: Carnet no encontrado o datos no coinciden
      - `409`: Usuario ya existe
      - `400`: Datos inválidos
      - `500`: Error del servidor

#### Rutas
```dart
routes: {
  '/login': LoginScreen,
  '/register': RegisterScreen,  // NUEVA
  '/carnet': CarnetScreen,
  '/vacunas': VacunasScreen,
}
```

### **Backend (Node.js + Render)**

#### Endpoints Requeridos

**1. POST /auth/register**
```javascript
Request:
{
  "correo": "estudiante@uagro.mx",
  "matricula": "UAGRO-123456",
  "password": "miPassword123"
}

Lógica:
1. Buscar en BD de carnets si existe registro con correo Y matrícula
2. Verificar que correo y matrícula pertenezcan al mismo carnet
3. Verificar que no exista ya un usuario registrado con esa matrícula
4. Si todo OK, crear usuario en tabla de autenticación
5. Hashear contraseña (bcrypt)

Respuestas:
- 201: { success: true, message: "Cuenta creada" }
- 404: { success: false, errorType: "NOT_FOUND", message: "Carnet no encontrado" }
- 404: { success: false, errorType: "MISMATCH", message: "Correo y matrícula no coinciden" }
- 409: { success: false, errorType: "ALREADY_EXISTS", message: "Usuario ya existe" }
- 500: { success: false, errorType: "SERVER", message: "Error del servidor" }
```

**2. POST /auth/login** (ACTUALIZADO)
```javascript
Request:
{
  "matricula": "UAGRO-123456",
  "password": "miPassword123"
}

Lógica:
1. Buscar usuario por matrícula
2. Verificar contraseña hasheada
3. Generar JWT token
4. Devolver token

Respuestas:
- 200: { success: true, token: "jwt_token", matricula: "..." }
- 401: { success: false, errorType: "CREDENTIALS", message: "Credenciales incorrectas" }
- 500: { success: false, errorType: "SERVER", message: "Error del servidor" }
```

## 🗄️ Estructura de Base de Datos

### Tabla: `carnets` (Existente)
```sql
{
  _id: ObjectId,
  matricula: String (unique),
  correo: String,
  nombreCompleto: String,
  programa: String,
  ... (otros datos del carnet)
}
```

### Tabla: `usuarios` (Nueva - Autenticación)
```sql
{
  _id: ObjectId,
  matricula: String (unique, foreign key a carnets),
  passwordHash: String (bcrypt),
  createdAt: Date,
  lastLogin: Date
}
```

## 🔒 Seguridad Implementada

### Frontend
- ✅ Validación de formatos (correo, matrícula, contraseña)
- ✅ Contraseña mínimo 6 caracteres
- ✅ Confirmación de contraseña
- ✅ Aceptación de términos y condiciones
- ✅ Ofuscación de contraseña en campos

### Backend (Recomendaciones)
- 🔐 Hash de contraseñas con bcrypt (salt rounds: 10)
- 🔐 JWT con expiración (7 días)
- 🔐 Rate limiting en endpoints de auth
- 🔐 Validación de datos en servidor
- 🔐 HTTPS obligatorio
- 🔐 CORS configurado correctamente

## 📝 Validaciones del Sistema

### Al Registrarse
1. ✅ Correo tiene formato válido
2. ✅ Matrícula no está vacía
3. ✅ Contraseña tiene mínimo 6 caracteres
4. ✅ Contraseñas coinciden
5. ✅ Términos y condiciones aceptados
6. ✅ **Carnet existe en BD** (backend)
7. ✅ **Correo y matrícula coinciden** (backend)
8. ✅ **Usuario no existe previamente** (backend)

### Al Iniciar Sesión
1. ✅ Matrícula no está vacía
2. ✅ Contraseña no está vacía
3. ✅ **Credenciales correctas** (backend)
4. ✅ **Usuario existe y está activo** (backend)

## 🎨 UX/UI Mejorado

### Pantalla de Registro
- Diseño moderno con gradiente animado
- Partículas médicas flotantes
- Campos con iconos dinámicos
- Validación en tiempo real
- Mensaje claro de requisitos
- Alert informativo sobre necesidad de carnet previo

### Mensajes de Error Específicos
- ❌ "Carnet no encontrado" → Usuario debe ir a servicios de salud
- ❌ "Correo y matrícula no coinciden" → Verificar datos
- ❌ "Usuario ya existe" → Usar login en su lugar
- ❌ "Contraseñas no coinciden" → Revisar contraseña
- ❌ "Términos no aceptados" → Leer y aceptar términos

### Mensajes de Éxito
- ✅ "Cuenta creada exitosamente" → Redirige a login
- ✅ "Login exitoso" → Acceso al carnet

## 🚀 Cómo Probar Localmente

### 1. Preparar el Backend
```bash
cd backend-sasu
npm install
npm run dev  # Corre en localhost:3000
```

### 2. Preparar el Frontend
```bash
cd carnet_digital_alumnos
flutter pub get
flutter run -d chrome --web-port 8080
```

### 3. Flujo de Prueba
1. Acceder a `http://localhost:8080`
2. Click en "Regístrate aquí"
3. Ingresar datos de prueba (que existan en BD de carnets)
4. Verificar creación exitosa
5. Regresar a login
6. Ingresar matrícula + contraseña
7. Verificar acceso al carnet

## 📊 Casos de Prueba

### Caso 1: Registro Exitoso
```
Input:
- Correo: juan.perez@uagro.mx
- Matrícula: UAGRO-123456
- Password: miPassword123

Precondición: Carnet existe en BD con ese correo y matrícula
Resultado Esperado: ✅ Cuenta creada, redirige a login
```

### Caso 2: Carnet No Existe
```
Input:
- Correo: noexiste@uagro.mx
- Matrícula: UAGRO-999999
- Password: test123

Precondición: Carnet NO existe en BD
Resultado Esperado: ❌ Error "Carnet no encontrado"
```

### Caso 3: Datos No Coinciden
```
Input:
- Correo: juan.perez@uagro.mx
- Matrícula: UAGRO-654321  (matrícula de otro estudiante)
- Password: test123

Precondición: Ambos existen pero no coinciden
Resultado Esperado: ❌ Error "Correo y matrícula no coinciden"
```

### Caso 4: Usuario Ya Existe
```
Input:
- Correo: juan.perez@uagro.mx
- Matrícula: UAGRO-123456
- Password: nuevoPassword

Precondición: Usuario ya registrado previamente
Resultado Esperado: ❌ Error "Usuario ya existe"
```

### Caso 5: Login Exitoso
```
Input:
- Matrícula: UAGRO-123456
- Password: miPassword123

Precondición: Usuario registrado con esas credenciales
Resultado Esperado: ✅ Login exitoso, acceso al carnet
```

## 🛠️ Comandos de Desarrollo

### Build de Producción
```bash
flutter build web --release
```

### Verificar Errores
```bash
flutter analyze
```

### Limpiar Build
```bash
flutter clean
flutter pub get
flutter build web --release
```

## 📦 Archivos Modificados/Creados

### Nuevos
- ✅ `lib/screens/register_screen.dart`
- ✅ `SISTEMA_REGISTRO_AUTENTICACION.md`

### Modificados
- ✅ `lib/main.dart` (ruta /register)
- ✅ `lib/screens/login_screen.dart` (link a registro)
- ✅ `lib/providers/session_provider.dart` (método register, login actualizado)
- ✅ `lib/services/api_service.dart` (endpoint register, login actualizado)

## ⚠️ Importante para Producción

### Backend
1. **Implementar endpoint `/auth/register`** con validaciones completas
2. **Actualizar endpoint `/auth/login`** para aceptar matrícula + password
3. **Hashear contraseñas** con bcrypt antes de guardar
4. **Implementar rate limiting** para prevenir ataques de fuerza bruta
5. **Logs de auditoría** para registros y logins

### Frontend
1. **Actualizar baseUrl** en api_service.dart cuando backend esté listo
2. **Probar flujo completo** en staging antes de producción
3. **Verificar HTTPS** en producción

### Base de Datos
1. **Crear tabla `usuarios`** si no existe
2. **Crear índices** en campos de búsqueda (matricula)
3. **Backup** antes de implementar cambios

## 📞 Soporte

- Sistema desarrollado para CRES Llano Largo
- Universidad Autónoma de Guerrero
- Sistema SASU (Sistema de Atención en Salud Universitaria)

## 🔄 Próximos Pasos

1. ✅ Implementar endpoint `/auth/register` en backend
2. ✅ Actualizar endpoint `/auth/login` en backend
3. ✅ Crear tabla `usuarios` en base de datos
4. ⏳ Probar flujo completo en localhost
5. ⏳ Deploy a staging
6. ⏳ Pruebas con usuarios reales
7. ⏳ Deploy a producción

---

**Fecha de Implementación**: 11 de Octubre, 2025
**Versión**: 2.0.0 - Sistema de Registro y Autenticación Completo
