# � CONEXIÓN A AZURE COSMOS DB - SASU

## ℹ️ Información Importante

Este backend **NO CREA** promociones. Solo las **LEE** del contenedor `promociones_salud` en Azure Cosmos DB.

Las promociones son creadas por otra aplicación de administración que guarda los datos en el mismo contenedor Cosmos DB que este backend consulta.

## 🗄️ Base de Datos: Azure Cosmos DB

**Contenedor**: `promociones_salud`

**Estructura de documento**:
```json
{
    "id": "promocion:uuid",
    "link": "https://...",
    "departamento": "Atención estudiantil",
    "categoria": "Promoción",
    "programa": "Licenciatura",
    "matricula": "15662",  // null o vacío = para todos
    "destinatario": "alumno",
    "autorizado": true,
    "createdAt": "2025-10-09T21:18:06.246851Z",
    "createdBy": ""
}
```

---

## 📊 Configuración de Base de Datos

### Opción 1: Mismo contenedor/servidor que la app de administración

Si ambas aplicaciones (admin y este backend) están en el mismo servidor/contenedor:

**Variables de entorno necesarias**:

```env
# PostgreSQL (ejemplo)
DATABASE_URL=postgresql://usuario:password@host:5432/sasu_database

# MySQL (ejemplo)
DATABASE_URL=mysql://usuario:password@host:3306/sasu_database

# SQL Server (ejemplo)
DATABASE_URL=mssql://usuario:password@host:1433/sasu_database
```

### Opción 2: Base de datos compartida en la nube

Si la base de datos está en un servidor separado que ambas apps consultan:

1. Obtén la **connection string** de la base de datos SASU
2. Configúrala en `DATABASE_URL`
3. Asegúrate de que el backend tenga permisos de **solo lectura** (recomendado)

---

## 🔍 Estructura de Tablas Esperada

El backend espera que existan estas tablas en la base de datos SASU:

### 1. `categorias_promociones`
```sql
- id (PK)
- nombre
- descripcion
- color_hex
- icono
- activo
- created_at
- updated_at
```

### 2. `departamentos_salud`
```sql
- id (PK)
- nombre
- descripcion
- ubicacion
- telefono
- email
- activo
- created_at
- updated_at
```

### 3. `promociones_salud`
```sql
- id (PK)
- titulo
- descripcion
- resumen
- categoria_id (FK)
- departamento_id (FK)
- fecha_publicacion
- fecha_inicio
- fecha_fin
- link
- imagen_url
- matricula_target (NULL = para todos, o matrícula específica)
- destacado
- urgente
- prioridad
- activo
- created_at
- updated_at
```

### 4. `promociones_interacciones` (opcional)
```sql
- id (PK)
- promocion_id (FK)
- matricula
- tipo_interaccion ('view', 'click', 'share')
- created_at
```

---

## ⚙️ Configuración en Render

### Si la base de datos SASU ya existe en Render:

1. **No crear nueva base de datos**
2. Usar la URL de conexión existente
3. En Environment Variables del backend:
   ```
   DATABASE_URL=<URL_DE_BASE_DATOS_SASU_EXISTENTE>
   ```

### Si necesitas conectar a base de datos externa:

```env
# Ejemplo: Base de datos en otro servidor
DATABASE_URL=postgresql://sasu_user:password@external-db.example.com:5432/sasu_production

# Permisos recomendados: SOLO LECTURA
# El backend solo ejecuta SELECT, no INSERT/UPDATE/DELETE
```

---

## 🛡️ Seguridad Recomendada

### Usuario de base de datos con permisos limitados:

```sql
-- PostgreSQL ejemplo
CREATE USER backend_readonly WITH PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE sasu_database TO backend_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backend_readonly;

-- MySQL ejemplo
CREATE USER 'backend_readonly'@'%' IDENTIFIED BY 'secure_password';
GRANT SELECT ON sasu_database.* TO 'backend_readonly'@'%';
FLUSH PRIVILEGES;
```

De esta forma el backend **solo puede leer**, no modificar datos.

---

## 🔄 Flujo de Datos

```
┌─────────────────────────────────────────────┐
│  APP DE ADMINISTRACIÓN (otra aplicación)    │
│  - Crea promociones                         │
│  - Actualiza promociones                    │
│  - Elimina promociones                      │
└────────────────┬────────────────────────────┘
                 │
                 │ INSERT/UPDATE/DELETE
                 ↓
┌─────────────────────────────────────────────┐
│        BASE DE DATOS SASU (compartida)      │
│  - Tabla: promociones_salud                 │
│  - Tabla: categorias_promociones            │
│  - Tabla: departamentos_salud               │
└────────────────┬────────────────────────────┘
                 │
                 │ SELECT (solo lectura)
                 ↓
┌─────────────────────────────────────────────┐
│     ESTE BACKEND (carnet-alumnos-backend)   │
│  - Lee promociones                          │
│  - Filtra por matrícula                     │
│  - Sirve API REST al frontend Flutter       │
└────────────────┬────────────────────────────┘
                 │
                 │ HTTP/JSON
                 ↓
┌─────────────────────────────────────────────┐
│        FRONTEND FLUTTER (tu app)            │
│  - Muestra promociones                      │
│  - Interfaz de usuario                      │
└─────────────────────────────────────────────┘
```

---

## 📝 Próximos Pasos

1. **Identifica dónde está la base de datos SASU**
   - ¿Render? ¿Otro proveedor?
   - ¿Mismo servidor que la app de admin?

2. **Obtén la connection string**
   - Si está en Render: Dashboard → Database → Connection String
   - Si está en otro lado: Contacta al administrador

3. **Configura `DATABASE_URL`**
   - En Render: Environment Variables
   - Localmente: Archivo `.env`

4. **Verifica la estructura**
   - Las tablas deben existir
   - Los campos deben coincidir con los modelos

5. **Ejecuta `npm run seed`**
   - Solo sincroniza modelos
   - No crea datos de prueba
   - Muestra cuántas promociones hay

---

## ❓ Preguntas Frecuentes

**P: ¿Este backend puede crear promociones?**
R: No directamente. Este backend es de **solo lectura**. Las promociones se crean desde la app de administración.

**P: ¿Puedo usar endpoints de admin (POST/PUT/DELETE)?**
R: Sí, si necesitas que este backend también administre promociones. Pero lo recomendado es que solo lea y la app de admin sea la única que escriba.

**P: ¿Qué pasa si no hay promociones en la BD?**
R: El endpoint `/me/promociones` devolverá un array vacío `[]`. No habrá error.

**P: ¿Cómo filtrar promociones por matrícula?**
R: El backend ya lo hace automáticamente en el endpoint `/me/promociones`. Devuelve:
- Promociones con `matricula_target = NULL` (para todos)
- Promociones con `matricula_target = matrícula del usuario`

---

## 📞 Necesitas Ayuda?

Para conectar correctamente, proporciona:
1. Motor de base de datos (PostgreSQL, MySQL, etc.)
2. Ubicación (Render, AWS, Azure, etc.)
3. Connection string (si la tienes)
4. Estructura de tablas (nombres y campos)
