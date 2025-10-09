# 🎨 Mejoras en Tarjetas de Promociones - Carnet Digital UAGro

## ✅ Cambios Realizados

### 1. **Instalación de `url_launcher`**
- ✅ Agregado paquete `url_launcher: ^6.2.5` en `pubspec.yaml`
- ✅ Permite abrir enlaces externos en el navegador

### 2. **Rediseño Completo de Tarjetas**

#### **ANTES:**
- ❌ Ícono de "play" (no tiene sentido para enlaces)
- ❌ Texto "Ver ahora" (confuso)
- ❌ No mostraba preview del enlace
- ❌ Diseño oscuro con gradiente que ocultaba información
- ❌ No abría realmente el enlace

#### **DESPUÉS:**
- ✅ **Diseño tipo tarjeta de blog/noticia**
- ✅ **Header visual con gradiente** - Muestra categoría y título principal
- ✅ **Información clara y legible** - Fondo blanco, texto oscuro
- ✅ **Preview del enlace** - Muestra el dominio del link (ej: "salud.uagro.mx")
- ✅ **Botón descriptivo** - "Más información" con ícono de info
- ✅ **Abre enlace real** - Al hacer clic, abre en nueva pestaña del navegador

---

## 🎨 Estructura de la Nueva Tarjeta

```
┌─────────────────────────────────────┐
│  HEADER (Gradiente colorido)       │
│  ┌─────────────────────────────┐   │
│  │ 💉 VACUNACIÓN         [Badge]│   │
│  │                              │   │
│  │ Campaña de Vacunación        │   │
│  │ Influenza 2024               │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│  CONTENIDO (Fondo blanco)           │
│  🏢 DEPARTAMENTO DE SALUD           │
│                                     │
│  Vacúnate contra la influenza.      │
│  Protege tu salud y la de tu        │
│  comunidad universitaria...         │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🔗 salud.uagro.mx     ↗     │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  ℹ️  Más información        │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

---

## 📋 Elementos de la Tarjeta

### 1. **Header Visual (180px altura)**
- **Gradiente de color** según categoría
- **Badge de categoría** con ícono (💉 VACUNACIÓN, 🧠 SALUD MENTAL, etc.)
- **Título principal** grande y en negrita
- **Patrón de fondo sutil** para profundidad visual

### 2. **Contenido Informativo**
- **Ícono + Departamento** - Identifica el origen
- **Descripción** - Máximo 3 líneas, texto claro y legible
- **Preview del enlace** - Muestra dominio en caja gris con ícono de link

### 3. **Call to Action**
- **Botón "Más información"** - Color según categoría
- **Ícono informativo** (ℹ️) en lugar de play (▶️)
- **Altura 48px** - Fácil de tocar/clickear

---

## 🔗 Funcionalidad del Enlace

### Cuando el usuario hace clic:

1. **Efecto visual** - Vibración háptica
2. **Marca como vista** - Registra en estadísticas
3. **Abre enlace** - En nueva pestaña del navegador
4. **Notificación** - SnackBar verde mostrando "Abriendo: dominio.com"

### Si hay error:

- **SnackBar rojo** - "No se pudo abrir el enlace. Verifica tu conexión."

---

## 🎨 Colores por Categoría

| Categoría | Ícono | Color Principal | Gradiente |
|-----------|-------|----------------|-----------|
| vacunacion | 💉 | Verde (#4CAF50) | Verde → Verde Oscuro |
| salud_mental | 🧠 | Púrpura (#9C27B0) | Púrpura → Púrpura Oscuro |
| odontologia | 🦷 | Azul (#2196F3) | Azul → Azul Oscuro |
| nutricion | 🥗 | Naranja (#FF9800) | Naranja → Naranja Oscuro |
| general | ❤️ | Rojo (#F44336) | Rojo → Rojo Oscuro |

---

## 💡 Función Helper: `_obtenerDominioDeLink()`

Esta función extrae el dominio del URL para mostrarlo de forma limpia:

```dart
"https://www.salud.uagro.mx/vacunacion" 
→ "salud.uagro.mx"

"https://facebook.com/UAGroOficial/posts/123456"
→ "facebook.com"

"http://ejemplo.com/pagina/muy/larga/con/muchas/rutas"
→ "ejemplo.com"
```

---

## 📱 Experiencia de Usuario

### Flujo Completo:

1. **Usuario ve tarjeta atractiva** con información clara
2. **Lee preview del enlace** - Sabe a dónde lo lleva
3. **Click en "Más información"**
4. **Enlace se abre** en nueva pestaña (no pierde su sesión)
5. **Notificación confirma** la acción

### Ventajas:

✅ **Información clara** - Usuario sabe qué esperar  
✅ **Preview del enlace** - Genera confianza  
✅ **No pierde sesión** - Se abre en nueva pestaña  
✅ **Diseño atractivo** - Estimula el click  
✅ **Feedback visual** - Confirma la acción  

---

## 🔧 Archivos Modificados

### 1. `pubspec.yaml`
```yaml
dependencies:
  url_launcher: ^6.2.5  # ← NUEVO
```

### 2. `lib/screens/carnet_screen.dart`
- Import de `url_launcher`
- Función `_buildNetflixCard()` completamente rediseñada
- Función `_abrirEnlaceDirecto()` ahora abre URLs reales
- Nueva función `_obtenerDominioDeLink()` para extraer dominio

---

## 🧪 Cómo Probar

1. **Compilar**: `flutter build web --release`
2. **Abrir**: http://localhost:3000
3. **Iniciar sesión** con tu cuenta
4. **Ver promociones** - Desliza el carrusel
5. **Click en "Más información"**
6. **Verificar** - Se abre en nueva pestaña

---

## 📊 Ejemplo de Datos en Cosmos DB

Para mejores resultados, asegúrate de que tus documentos tengan:

```json
{
  "id": "promocion:uuid",
  "link": "https://salud.uagro.mx/vacunacion",
  "departamento": "DEPARTAMENTO DE SALUD",
  "categoria": "vacunacion",
  "programa": "Campaña de Vacunación Influenza 2024",
  "titulo": "Vacúnate contra la Influenza",
  "descripcion": "Vacúnate contra la influenza. Protege tu salud y la de tu comunidad universitaria. Disponible en el Centro de Salud.",
  "matricula": null,
  "destinatario": "alumno",
  "autorizado": true,
  "createdAt": "2025-01-15T10:00:00Z",
  "createdBy": "admin@uagro.mx"
}
```

### Campos importantes:

- **`link`** - URL completa con https://
- **`programa`** - Título principal (aparece en header)
- **`descripcion`** - Texto descriptivo (3 líneas máx)
- **`categoria`** - Define color y ícono
- **`departamento`** - Identifica el origen

---

## 🎉 Resultado Final

Las tarjetas ahora se ven **profesionales, informativas y atractivas**, similares a:

- 📰 **Tarjetas de noticias** (Medium, LinkedIn)
- 🛍️ **Productos en e-commerce** (con preview de imagen)
- 📱 **Posts en redes sociales** (con link preview)

¡Listo para usar en producción! 🚀
