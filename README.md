# 🎓 Carnet Digital UAGro

**Sistema de identificación digital para estudiantes de la Universidad Autónoma de Guerrero**

[![Flutter Version](https://img.shields.io/badge/Flutter-3.35.4-blue.svg)](https://flutter.dev/)
[![Dart Version](https://img.shields.io/badge/Dart-3.9.2-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🌟 Características

- ✅ **Autenticación SASU**: Login con correo institucional y matrícula
- 📱 **Carnet Digital**: Visualización completa del carnet estudiantil  
- 🏥 **Citas Médicas**: Consulta de citas programadas
- 🎨 **Diseño Institucional**: Colores y marca UAGro
- 📱 **Responsive**: Optimizado para web y móviles
- ⚡ **Sin Base de Datos Local**: Architecture Provider-only

## 🚀 Tecnologías

- **Flutter Web** 3.35.4
- **Provider** para state management
- **HTTP Client** para integración SASU
- **QR Flutter** para códigos QR
- **GitHub Pages** para deployment

## 🔧 Instalación y Desarrollo

### Prerrequisitos
- Flutter SDK ≥ 3.35.4
- Dart SDK ≥ 3.9.2

### Configuración Local
```bash
# Clonar repositorio
git clone https://github.com/edukshare-max/edukshare-max.github.io.git
cd edukshare-max.github.io

# Instalar dependencias
flutter pub get

# Ejecutar en modo desarrollo
flutter run -d chrome

# Compilar para producción
flutter build web --release
```

## 🌐 Deployment

### GitHub Pages (Automático)
El proyecto se despliega automáticamente en [app.carnetdigital.space](https://app.carnetdigital.space) cuando se hace push a `main`.

### Manual
```bash
flutter build web --release
# Copiar contenido de build/web/ al servidor
```

## 📚 Estructura del Proyecto

```
lib/
├── main.dart                 # Aplicación principal
├── models/                   # Modelos de datos
│   ├── carnet_model.dart    # Modelo del carnet
│   └── cita_model.dart      # Modelo de citas
├── providers/                # Estado global
│   └── session_provider.dart # Provider de sesión
├── screens/                  # Pantallas de la app
│   ├── login_screen.dart    # Pantalla de login
│   ├── carnet_screen.dart   # Vista del carnet
│   └── citas_screen.dart    # Vista de citas
├── services/                 # Servicios externos
│   └── api_service.dart     # Cliente HTTP SASU
└── theme/                   # Tema visual
    └── uagro_theme.dart     # Colores UAGro
```

## 🔗 Integración SASU

### Endpoints Utilizados
- `POST /auth/login` - Autenticación con JWT
- `GET /me/carnet` - Datos del carnet estudiantil  
- `GET /citas` - Citas médicas programadas

### Autenticación
```dart
// Login con correo institucional
final result = await ApiService.login(
  'estudiante@uagro.mx', 
  '12345678'
);
```

## 📱 Pantallas

### 🔐 Login
- Validación de correo @uagro.mx
- Verificación de matrícula
- Autenticación con backend SASU

### 🎓 Carnet Digital  
- Información completa del estudiante
- Código QR de identificación
- Datos académicos y personales

### 🏥 Citas Médicas
- Lista de citas programadas
- Estados: confirmada, pendiente, cancelada
- Detalles: fecha, hora, doctor, lugar

## 🎨 Diseño

### Colores Institucionales
- **Primario**: `#0175C2` (Azul UAGro)
- **Secundario**: `#FFD700` (Dorado UAGro)
- **Fondo**: `#F8FAFC` (Claro)
- **Error**: `#DC2626` (Rojo)
- **Éxito**: `#059669` (Verde)

## 🔒 Seguridad

- ✅ Autenticación JWT
- ✅ Validación de tokens
- ✅ Manejo seguro de credenciales
- ✅ Sin almacenamiento local de datos sensibles

## 🚦 Estado del Proyecto

- ✅ **Autenticación**: Funcional con SASU
- ✅ **UI/UX**: Diseño completo
- ✅ **Responsive**: Web optimizada
- ✅ **Deployment**: GitHub Pages activo
- 🔄 **Funciones Citas**: En desarrollo

## 📄 Licencia

MIT License - ver [LICENSE](LICENSE) para detalles.

## 👥 Equipo

Desarrollado para la **Universidad Autónoma de Guerrero**

---

**🌐 Acceso**: [app.carnetdigital.space](https://app.carnetdigital.space)  
**📧 Soporte**: Contactar administración UAGro
