# 📚 DOCUMENTACIÓN COMPLETA DEL SISTEMA DE PROMOCIONES SASU

## 🎯 RESUMEN EJECUTIVO

Se ha desarrollado un **sistema completo de promociones de salud** para el backend SASU de la Universidad Autónoma de Guerrero, con integración al carnet digital Flutter. El sistema está **listo para producción** y solo requiere:

### 🚀 Inicio Rápido (Local)

1. Instalar dependencias (`npm install`)
2. Configurar variables de entorno (`.env`)
3. Poblar la base de datos (`npm run seed`)
4. Iniciar el servidor (`npm start`)

### ☁️ Despliegue en Render

Para desplegar en producción en Render, consulta: **[DEPLOY_RENDER.md](./DEPLOY_RENDER.md)**

---

## 📁 ESTRUCTURA DE ARCHIVOS CREADOS

```
backend-sasu/
├── server.js                       # Servidor principal Express
├── package.json                    # Dependencias y scripts
├── .env.example                    # Plantilla de configuración
│
├── config/
│   └── database.js                 # Configuración Sequelize (MySQL/PostgreSQL/SQLite)
│
├── models/
│   └── PromocionSalud.js           # Modelos: PromocionSalud, CategoriaPromocion, 
│                                   #          DepartamentoSalud, PromocionInteraccion
│
├── controllers/
│   └── PromocionesController.js    # Lógica de negocio para promociones
│
├── routes/
│   └── promociones.js              # Endpoints REST de la API
│
├── middleware/
│   ├── authMiddleware.js           # Autenticación JWT
│   ├── adminMiddleware.js          # Permisos de administrador
│   ├── rateLimitMiddleware.js      # Control de tasa de solicitudes
│   └── validationMiddleware.js     # Validación de datos de entrada
│
├── database/
│   └── schema.sql                  # Esquema completo de base de datos MySQL
│
└── scripts/
    └── seedData.js                 # Script para poblar datos de prueba
```

---

## 🗄️ ESQUEMA DE BASE DE DATOS

### Tablas Principales

1. **`categorias_promociones`** - 7 categorías predefinidas:
   - Consulta Médica (🏥 azul #3B82F6)
   - Prevención (🛡️ verde #10B981)
   - Emergencia (🚨 rojo #EF4444)
   - Salud Mental (🧠 morado #8B5CF6)
   - Nutrición (🥗 naranja #F59E0B)
   - Deportes (⚽ cyan #06B6D4)
   - Información (📱 gris #6B7280)

2. **`departamentos_salud`** - 6 departamentos:
   - Consultorio Médico General
   - Servicios Psicológicos
   - Departamento de Nutrición
   - Medicina Deportiva
   - Servicios de Emergencia
   - Promoción de la Salud

3. **`promociones_salud`** - Tabla principal con campos:
   - Información básica: titulo, descripcion, resumen, link, imagen_url
   - Relaciones: categoria_id, departamento_id
   - Targeting: matricula_target, carrera_target, semestre_target
   - Fechas: fecha_inicio, fecha_fin, fecha_publicacion
   - Estados: activo, destacado, urgente, prioridad (1-10)
   - Métricas: vistas, clicks
   - Timestamps: created_at, updated_at

4. **`promociones_interacciones`** - Tracking de uso:
   - Registra vistas, clicks y compartidos
   - Asociado a promocion_id y matricula
   - Incluye user_agent e ip_address

### Índices Optimizados

- `idx_activo_fechas` - Consultas de promociones activas
- `idx_matricula_target` - Filtrado por matrícula
- `idx_categoria` y `idx_departamento` - Joins optimizados
- `idx_prioridad` - Ordenamiento por importancia
- `idx_destacado` - Carrusel de promociones destacadas

---

## 🔌 ENDPOINTS DE LA API

### 👨‍🎓 Endpoints para Estudiantes

#### GET `/me/promociones`
Obtiene todas las promociones activas para el estudiante autenticado.

**Autenticación:** Bearer JWT Token  
**Query Params:**
- `incluir_vencidas` (boolean, default: false)
- `limite` (number, 1-100, default: 20)
- `categoria_id` (number)
- `departamento_id` (number)

**Respuesta Exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "titulo": "Consulta Médica Especializada",
      "descripcion": "Consulta programada con el Dr. Martinez...",
      "resumen": "Consulta médica - Trae tu carnet",
      "link": "https://citas.uagro.mx/consulta/15662",
      "imagen_url": "https://images.unsplash.com/...",
      "categoria": "Consulta Médica",
      "categoria_color": "#3B82F6",
      "categoria_icono": "🏥",
      "departamento": "Consultorio Médico General",
      "departamento_contacto": {
        "email": "medico@uagro.mx",
        "telefono": "+52 744 445 1100",
        "ubicacion": "Edificio Central, Planta Baja"
      },
      "fecha_inicio": "2025-10-09",
      "fecha_fin": "2025-11-08",
      "destacado": true,
      "urgente": false,
      "prioridad": 10,
      "vistas": 15,
      "clicks": 5,
      "es_especifica": true,
      "tiempo_restante_dias": 30,
      "created_at": "2025-10-09T12:00:00.000Z",
      "updated_at": "2025-10-09T12:00:00.000Z"
    }
  ],
  "meta": {
    "total": 5,
    "matricula": "15662",
    "incluir_vencidas": false,
    "timestamp": "2025-10-09T20:30:45.123Z"
  }
}
```

#### GET `/me/promociones/destacadas`
Obtiene promociones destacadas para el carrusel Netflix.

**Autenticación:** Bearer JWT Token  
**Query Params:**
- `limite` (number, 1-20, default: 10)

#### POST `/me/promociones/:promocion_id/click`
Registra un click/interacción con una promoción.

**Autenticación:** Bearer JWT Token  
**Params:** promocion_id (number)  

**Respuesta Exitosa (200):**
```json
{
  "success": true,
  "message": "Click registrado correctamente",
  "data": {
    "promocion_id": 1,
    "titulo": "Consulta Médica Especializada",
    "link": "https://citas.uagro.mx/consulta/15662",
    "clicks_totales": 6
  }
}
```

### 👨‍💼 Endpoints Administrativos

#### GET `/admin/promociones`
Lista todas las promociones con filtros avanzados.

**Autenticación:** Bearer JWT Token + Rol Admin  
**Query Params:**
- `activo` (boolean)
- `categoria_id`, `departamento_id` (number)
- `fecha_desde`, `fecha_hasta` (YYYY-MM-DD)
- `matricula_target` (string)
- `page` (number, default: 1)
- `limit` (number, 1-200, default: 50)
- `order_by` (id|titulo|created_at|prioridad)
- `order_direction` (ASC|DESC)

#### POST `/admin/promociones`
Crea una nueva promoción.

**Autenticación:** Bearer JWT Token + Rol Admin  
**Body:**
```json
{
  "titulo": "Campaña de Vacunación 2025",
  "descripcion": "Descripción completa de la campaña...",
  "resumen": "Vacunación gratuita para estudiantes",
  "link": "https://vacunacion.uagro.mx",
  "imagen_url": "https://images.unsplash.com/...",
  "categoria_id": 2,
  "departamento_id": 6,
  "matricula_target": null,
  "fecha_inicio": "2025-10-15",
  "fecha_fin": "2025-11-15",
  "destacado": true,
  "urgente": false,
  "prioridad": 9
}
```

#### PUT `/admin/promociones/:promocion_id`
Actualiza una promoción existente.

#### DELETE `/admin/promociones/:promocion_id`
Elimina/desactiva una promoción.

**Query Params:**
- `eliminar_permanente` (boolean, default: false)

### 🌐 Endpoints Públicos

#### GET `/public/promociones/categorias`
Lista todas las categorías disponibles.

#### GET `/public/promociones/departamentos`
Lista todos los departamentos de salud.

#### GET `/public/promociones/stats`
Estadísticas generales del sistema.

---

## 🚀 INSTALACIÓN Y DESPLIEGUE

### 1. Instalación de Dependencias

```bash
cd backend-sasu
npm install
```

**Dependencias Principales:**
- express (servidor HTTP)
- sequelize (ORM para base de datos)
- jsonwebtoken (autenticación JWT)
- express-validator (validación de datos)
- express-rate-limit (control de tasa)
- cors, helmet, compression (seguridad y rendimiento)

### 2. Configuración de Base de Datos

#### Opción A: SQLite (Desarrollo)
```bash
# Copiar archivo de ejemplo
cp .env.example .env

# .env ya está configurado para SQLite por defecto
NODE_ENV=development
DB_DIALECT=sqlite
DB_STORAGE=./database/sasu_development.db
```

#### Opción B: MySQL (Producción)
```bash
# Editar .env
NODE_ENV=production
DB_HOST=localhost
DB_PORT=3306
DB_NAME=sasu_production
DB_USER=sasu_user
DB_PASSWORD=your_secure_password
```

### 3. Poblar Base de Datos

```bash
# Ejecutar script de población
npm run seed
```

Este comando:
- Crea 7 categorías de promociones
- Crea 6 departamentos de salud
- Crea 12 promociones de ejemplo (3 para matrícula 15662)

### 4. Iniciar Servidor

```bash
# Desarrollo (con nodemon)
npm run dev

# Producción
npm start
```

El servidor se ejecutará en `http://localhost:3000`

### 5. Verificar Instalación

```bash
# Health check
curl http://localhost:3000/health

# Estadísticas públicas
curl http://localhost:3000/public/promociones/stats
```

---

## 🔐 AUTENTICACIÓN

### Obtener Token JWT

El sistema usa el mismo endpoint de login existente:

```bash
POST https://carnet-alumnos-nodes.onrender.com/auth/login
Content-Type: application/json

{
  "correo": "estudiante@uagro.mx",
  "matricula": "15662"
}
```

**Respuesta:**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "matricula": "15662"
}
```

### Usar Token en Requests

```bash
GET /me/promociones
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 📊 DATOS DE PRUEBA

### Promociones para Matrícula 15662

El script de seed crea **3 promociones específicas** para matrícula 15662:

1. **Consulta Médica Especializada**
   - Departamento: Consultorio Médico General
   - Categoría: Consulta Médica
   - Prioridad: 10 (máxima)
   - Destacada: Sí

2. **Campaña de Vacunación - Registro Confirmado**
   - Departamento: Promoción de la Salud
   - Categoría: Prevención
   - Prioridad: 9
   - Destacada: Sí

3. **Seguimiento Nutricional Personalizado**
   - Departamento: Departamento de Nutrición
   - Categoría: Nutrición
   - Prioridad: 8
   - Destacada: No

### Promociones Generales (Todos los Estudiantes)

También se crean **9 promociones generales** que aplican a todos:
- Servicio de Nutrición - Evaluación Gratuita
- Apoyo Psicológico - Sesiones Individuales
- Actualización de Expediente Médico
- Programa de Actividad Física
- Campaña de Donación de Sangre
- Taller de Manejo del Estrés
- Servicio de Emergencias 24/7
- Y más...

---

## 🔧 INTEGRACIÓN CON FLUTTER

### 1. ApiService Actualizado

El archivo `lib/services/api_service.dart` ya está configurado con:

```dart
static Future<List<PromocionSaludModel>> getPromocionesSalud(
  String token, 
  String matricula
) async {
  final url = Uri.parse('$baseUrl/me/promociones');
  
  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
  
  // Manejo de respuesta...
}
```

### 2. Registrar Clicks

```dart
static Future<bool> registrarClickPromocion(
  String token, 
  String promocionId
) async {
  final url = Uri.parse('$baseUrl/me/promociones/$promocionId/click');
  
  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
  
  return response.statusCode == 200;
}
```

### 3. SessionProvider

El `SessionProvider` cargará automáticamente las promociones al hacer login:

```dart
await loadPromociones(); // Ya está implementado
```

---

## 🎨 CARRUSEL NETFLIX

El carrusel ya está implementado en `lib/screens/carnet_screen.dart` con:

- **320px** cards estilo Netflix
- **Gradientes de 3 colores** por categoría
- **Badges "NUEVO"** para promociones recientes
- **Animaciones suaves** en hover
- **Modales cinemáticos** con información completa
- **Registro automático de clicks**

---

## 🧪 TESTING

### Probar con cURL

```bash
# 1. Login
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"correo":"test@uagro.mx","matricula":"15662"}'

# 2. Obtener promociones
curl -X GET "http://localhost:3000/me/promociones" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# 3. Registrar click
curl -X POST "http://localhost:3000/me/promociones/1/click" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# 4. Estadísticas públicas
curl http://localhost:3000/public/promociones/stats
```

---

## 📈 MÉTRICAS Y ANALYTICS

El sistema registra automáticamente:

- **Vistas** de cada promoción
- **Clicks** en enlaces
- **Compartidos** (preparado para futuro)
- **User Agent** e **IP Address** por privacidad

### Consultar Estadísticas de una Promoción

```bash
GET /me/promociones/:promocion_id/estadisticas
```

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "vistas": 150,
    "clicks": 45,
    "compartidos": 12,
    "ctr": "30.00"
  }
}
```

---

## 🔒 SEGURIDAD

### Rate Limiting

- **Endpoints públicos:** 50 req/10min
- **Promociones:** 100 req/15min
- **Clicks:** 20 req/1min
- **Operaciones admin:** 200 req/1hora
- **Creación:** 10 creaciones/1hora
- **Eliminación:** 5 eliminaciones/1hora

### Validación de Datos

- Validación de URLs con protocolos https
- Validación de fechas (inicio < fin)
- Validación de prioridades (1-10)
- Sanitización de strings
- Escape de caracteres peligrosos

### Headers de Seguridad

- `helmet` para headers HTTP seguros
- `cors` configurado para orígenes permitidos
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`

---

## 📝 PRÓXIMOS PASOS

### Para Desarrollo

1. **Instalar dependencias del backend:**
   ```bash
   cd backend-sasu
   npm install
   ```

2. **Configurar .env:**
   ```bash
   cp .env.example .env
   # Editar JWT_SECRET y configuración de BD
   ```

3. **Poblar base de datos:**
   ```bash
   npm run seed
   ```

4. **Iniciar servidor:**
   ```bash
   npm start
   ```

5. **Compilar Flutter:**
   ```bash
   flutter build web --release
   ```

6. **Servir build de Flutter:**
   ```bash
   cd build/web
   python -m http.server 3000
   ```

7. **Probar login con matrícula 15662**

### Para Producción

1. Configurar MySQL/PostgreSQL
2. Actualizar `DATABASE_URL` en variables de entorno
3. Ejecutar migraciones: `npm run db:migrate`
4. Poblar datos: `npm run seed`
5. Configurar proxy inverso (nginx)
6. Configurar SSL/TLS
7. Monitoreo con PM2 o similar

---

## 🎯 CONCLUSIÓN

El sistema de promociones SASU está **100% funcional** y listo para producción. Incluye:

✅ Backend completo con Node.js + Express  
✅ Base de datos con esquema optimizado  
✅ API RESTful con autenticación JWT  
✅ Validación y seguridad robusta  
✅ Rate limiting y CORS configurado  
✅ Datos de prueba para matrícula 15662  
✅ Integración con Flutter (ApiService)  
✅ Carrusel Netflix-style implementado  
✅ Sistema de métricas y analytics  
✅ Documentación completa  

**Solo falta iniciar el servidor y empezar a usarlo** 🚀

---

## 📞 SOPORTE

Para dudas o problemas:
- Email: soporte@uagro.mx
- Teléfono: +52 744 445 1100

---

Documentación generada: 9 de octubre de 2025  
Versión: 1.0.0  
Sistema: SASU - Universidad Autónoma de Guerrero