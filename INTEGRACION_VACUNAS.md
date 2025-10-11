# 💉 Funcionalidad: Tarjeta de Vacunación

## 📋 Resumen

Implementación completa de la sección **Tarjeta de Vacunación** que consulta el contenedor `Tarjeta_vacunacion` en Cosmos DB SASU y muestra el historial de vacunas aplicadas a cada estudiante.

---

## 🎯 Características Implementadas

### 1️⃣ Modelo de Datos (`VacunaModel`)
**Archivo**: `lib/models/vacuna_model.dart`

```dart
class VacunaModel {
  final String id;
  final String matricula;
  final String nombreEstudiante;
  final String campana;          // Campaña de vacunación
  final String vacuna;            // Nombre de la vacuna
  final int dosis;                // Número de dosis
  final String lote;              // Lote y caducidad
  final String aplicadoPor;       // Profesional de salud
  final DateTime fechaAplicacion;
  final String? observaciones;
  final DateTime? timestamp;
}
```

**Características:**
- ✅ Compatible con estructura de Cosmos DB `Tarjeta_vacunacion`
- ✅ Conversión bidireccional JSON
- ✅ Getters útiles: `fechaFormateada`, `caducidad`, `numeroLote`, `tipoVacunaCorto`

---

### 2️⃣ Endpoint Backend (`/me/vacunas`)
**Archivos**: 
- `carnet_alumnos_nodes/routes/vacunas.js` (NUEVO)
- `carnet_alumnos_nodes/index.js` (modificado)

**Endpoint**: `GET /me/vacunas`

**Autenticación**: Requiere token JWT (extraído por `authMiddleware`)

**Query SQL**:
```sql
SELECT * FROM c 
WHERE c.matricula = @matricula 
  AND c.tipo = 'aplicacion_vacuna' 
ORDER BY c.fechaAplicacion DESC
```

**Response exitoso**:
```json
{
  "success": true,
  "data": [
    {
      "id": "vacuna_2025_1760148082213",
      "matricula": "2025",
      "nombreEstudiante": "Gilberto Valenzuela Herrera",
      "campana": "Campaña de vacunación invernal",
      "vacuna": "COVID-19",
      "dosis": 1,
      "lote": "02424523 Cad:2029",
      "aplicadoPor": "",
      "fechaAplicacion": "2025-10-10T00:00:00.000",
      "observaciones": "El alumno tenia miedo.",
      "timestamp": "2025-10-10T20:01:22.213061"
    }
  ],
  "total": 1
}
```

**Manejo de Errores**:
- ✅ 401/403: Token inválido → limpieza automática de sesión
- ✅ 404: Sin vacunas → retorna array vacío
- ✅ 500: Error de servidor → mensaje descriptivo
- ✅ Logs detallados con emojis para debugging

**Endpoint Adicional** (Admin - futuro):
- `GET /me/vacunas/estadisticas` - Estadísticas globales de vacunación

---

### 3️⃣ Servicio API (`ApiService.getVacunas()`)
**Archivo**: `lib/services/api_service.dart`

**Método principal**:
```dart
static Future<List<VacunaModel>> getVacunas(String token)
```

**Características**:
- ✅ Sistema de reintentos (3 intentos con backoff exponencial)
- ✅ Timeout de 20 segundos
- ✅ Detección de token inválido (401/403)
- ✅ Manejo robusto de errores
- ✅ Logging detallado

**Flujo de reintentos**:
1. Intento 1 → Espera 0s
2. Intento 2 → Espera 2s
3. Intento 3 → Espera 4s

---

### 4️⃣ Pantalla de Vacunas (`VacunasScreen`)
**Archivo**: `lib/screens/vacunas_screen.dart`

**Características visuales**:

#### 📊 Panel de Estadísticas
- Total de vacunas aplicadas
- Tipos diferentes de vacunas
- Dosis totales aplicadas

#### 🎛️ Filtros Dinámicos
- Chip "Todas"
- Chips por tipo de vacuna (COVID-19, Influenza, etc.)
- Filtrado en tiempo real

#### 💳 Tarjetas de Vacuna
Cada card muestra:
- **Header**: Icono + Nombre de vacuna + Badge de dosis
- **Detalles**:
  - 📅 Fecha de aplicación
  - 🏥 Campaña
  - 🔢 Número de lote
  - 👤 Aplicado por (si disponible)
- **Observaciones**: Panel destacado con ícono de info

#### 🎨 Colores por Tipo
- 🔴 COVID-19
- 🔵 Influenza
- 🟠 Hepatitis
- 🟣 Tétanos
- 🟢 Otras

#### 📭 Estado Vacío
- Mensaje amigable
- Botón de recarga
- Icono grande de vacunas

**Acciones**:
- ✅ Botón de refresco en AppBar
- ✅ Pull-to-refresh (futuro)
- ✅ Navegación fluida desde menú lateral

---

### 5️⃣ Gestión de Estado (`SessionProvider`)
**Archivo**: `lib/providers/session_provider.dart`

**Cambios agregados**:

```dart
// Nuevo estado
List<VacunaModel> _vacunas = [];

// Nuevo getter
List<VacunaModel> get vacunas => _vacunas;

// Nuevo método privado
Future<void> _loadVacunasData()

// Nuevo método público
Future<void> loadVacunas()
```

**Integración en flujo de autenticación**:
1. Login exitoso → `_loadVacunasData()` automático
2. Restauración de sesión → `_loadVacunasData()` en background
3. Manejo de token inválido → limpieza automática

**Logs implementados**:
```
🔍 Cargando vacunas desde SASU backend...
✅ VACUNAS REALES CARGADAS: 3 registros
💉 PRIMERA VACUNA: VacunaModel{vacuna: COVID-19, dosis: 1, ...}
```

---

### 6️⃣ Menú Lateral (Drawer)
**Archivo**: `lib/screens/carnet_screen.dart`

**Nuevo ítem agregado**:

```dart
ListTile(
  leading: Icon(Icons.vaccines_rounded, color: Colors.green),
  title: Text('Tarjeta de Vacunación'),
  subtitle: Consumer<SessionProvider>(
    builder: (context, session, child) {
      return Text('${session.vacunas.length} vacunas registradas');
    },
  ),
  onTap: () {
    Navigator.pushNamed(context, '/vacunas');
  },
)
```

**Ubicación**: Sección "Servicios Estudiantiles", después de "Salud"

**Badge dinámico**: Muestra el conteo de vacunas en tiempo real

---

### 7️⃣ Rutas de Navegación
**Archivo**: `lib/main.dart`

**Nueva ruta agregada**:
```dart
routes: {
  '/login': (context) => const LoginScreen(),
  '/carnet': (context) => const CarnetScreen(),
  '/vacunas': (context) => const VacunasScreen(),  // NUEVO
}
```

---

## 🗂️ Estructura de Archivos

```
lib/
├── models/
│   └── vacuna_model.dart          ✅ NUEVO
├── screens/
│   ├── carnet_screen.dart         ✏️ Modificado (menú lateral)
│   └── vacunas_screen.dart        ✅ NUEVO
├── services/
│   └── api_service.dart           ✏️ Modificado (getVacunas)
├── providers/
│   └── session_provider.dart      ✏️ Modificado (_vacunas, loadVacunas)
└── main.dart                      ✏️ Modificado (ruta /vacunas)

carnet_alumnos_nodes/
├── routes/
│   └── vacunas.js                 ✅ NUEVO
└── index.js                       ✏️ Modificado (require + app.use)
```

---

## 🚀 Deployment

### Frontend (GitHub Pages)
```bash
flutter build web --release
git add -A
git commit -m "feat: Agregar sección de Tarjeta de Vacunación completa"
git push origin main
# GitHub Actions desplegará automáticamente a app.carnetdigital.space
```

**Commit**: `6933a79`

### Backend (Render)
```bash
cd carnet_alumnos_nodes
git add routes/vacunas.js index.js
git commit -m "feat: Agregar endpoint /me/vacunas para tarjeta de vacunación"
git push origin main
# Render auto-deploy activado
```

**Commit**: `f3e0d8d`

**URL Backend**: `https://carnet-alumnos-nodes.onrender.com`

---

## 🧪 Testing Manual

### 1. Verificar Backend
```bash
curl -X GET https://carnet-alumnos-nodes.onrender.com/me/vacunas \
  -H "Authorization: Bearer <TOKEN>"
```

**Respuesta esperada**: JSON con array de vacunas

### 2. Flujo Frontend
1. ✅ Login con credenciales válidas
2. ✅ Abrir menú lateral (hamburger icon)
3. ✅ Ver ítem "Tarjeta de Vacunación" con contador
4. ✅ Tap en el ítem
5. ✅ Ver pantalla de vacunas con:
   - Panel de estadísticas
   - Filtros por tipo
   - Cards de cada vacuna
6. ✅ Probar filtros (tap en chips)
7. ✅ Botón de refresco en AppBar

### 3. Casos Edge
- ❌ Sin vacunas → Mostrar estado vacío
- ❌ Token inválido → Limpieza automática + redirección a login
- ❌ Timeout backend → Reintentos automáticos (3x)
- ❌ Backend offline → Mensaje de error amigable

---

## 📊 Métricas de Implementación

| Aspecto | Detalles |
|---------|----------|
| **Archivos creados** | 2 (vacuna_model.dart, vacunas_screen.dart, routes/vacunas.js) |
| **Archivos modificados** | 5 (api_service, session_provider, carnet_screen, main, index.js) |
| **Líneas de código** | ~636 líneas añadidas |
| **Tiempo de compilación** | 27.8s |
| **Endpoints nuevos** | 1 (GET /me/vacunas) |
| **Pantallas nuevas** | 1 (VacunasScreen) |
| **Modelos nuevos** | 1 (VacunaModel) |

---

## 🔮 Mejoras Futuras

### Fase 2
- [ ] Gráficos de cobertura de vacunación
- [ ] Exportar tarjeta a PDF
- [ ] Compartir tarjeta por WhatsApp/Email
- [ ] Notificaciones de próximas dosis
- [ ] Calendario de vacunación recomendado

### Fase 3
- [ ] Modo offline con último estado cacheado
- [ ] Búsqueda por nombre de vacuna
- [ ] Filtro por rango de fechas
- [ ] Vista de timeline

### Admin Dashboard
- [ ] Estadísticas globales de vacunación
- [ ] Registrar nueva aplicación de vacuna
- [ ] Generación de reportes
- [ ] Panel de campañas activas

---

## 📝 Notas Técnicas

### Contenedor Cosmos DB
- **Nombre**: `Tarjeta_vacunacion`
- **Partition Key**: `/matricula`
- **Tipo de documento**: `aplicacion_vacuna`

### Performance
- ✅ Query optimizado con índice en `matricula`
- ✅ Ordenamiento por fecha descendente
- ✅ Proyección limpia (sin metadatos `_rid`, `_etag`, etc.)

### Seguridad
- ✅ Autenticación JWT requerida
- ✅ Filtrado automático por matrícula del token
- ✅ Sin exposición de datos de otros estudiantes
- ✅ Rate limiting en el backend

---

## 🎓 Ejemplo de Uso

```dart
// Cargar vacunas manualmente
await context.read<SessionProvider>().loadVacunas();

// Acceder a vacunas
final vacunas = context.read<SessionProvider>().vacunas;

// Filtrar por tipo
final covidVacunas = vacunas.where((v) => v.vacuna.contains('COVID')).toList();

// Obtener última vacuna
final ultima = vacunas.isNotEmpty ? vacunas.first : null;
```

---

## ✅ Checklist de Implementación

- [x] Modelo de datos VacunaModel
- [x] Endpoint backend `/me/vacunas`
- [x] Integración con Cosmos DB
- [x] Método `getVacunas()` en ApiService
- [x] Pantalla VacunasScreen con UI completa
- [x] Filtros por tipo de vacuna
- [x] Panel de estadísticas
- [x] Integración con SessionProvider
- [x] Ítem en menú lateral con contador
- [x] Ruta de navegación `/vacunas`
- [x] Sistema de reintentos y manejo de errores
- [x] Logging detallado
- [x] Compilación exitosa
- [x] Deploy frontend (GitHub Pages)
- [x] Deploy backend (Render)
- [x] Documentación completa

---

**Creado**: 11 de octubre de 2025  
**Versión**: 1.0.0  
**Estado**: ✅ Desplegado en producción  
**Commits**: 
- Frontend: `6933a79`
- Backend: `f3e0d8d`
