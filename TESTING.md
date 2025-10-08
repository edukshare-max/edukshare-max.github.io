# 🧪 PLAN DE TESTING - CARNET DIGITAL UAGRO

## 📋 Checklist de Funcionalidades

### 🔐 Autenticación
- [ ] Login con correo @uagro.mx válido
- [ ] Login con matrícula de 3 dígitos (ej: 123)
- [ ] Login con matrícula de 5 dígitos (ej: 15662)
- [ ] Login con matrícula de 9 dígitos (ej: 123456789)
- [ ] Validación de correo incorrecto
- [ ] Validación de matrícula vacía
- [ ] Manejo de errores de conexión

### 🎓 Carnet Digital
- [ ] Visualización completa de datos personales
- [ ] Foto placeholder funcional
- [ ] Código QR genera correctamente
- [ ] Información académica (carrera, semestre)
- [ ] Datos médicos (tipo de sangre)
- [ ] Diseño responsivo

### 🏥 Citas Médicas
- [ ] Lista de citas se carga
- [ ] Estados de citas (confirmada, pendiente, cancelada)
- [ ] Información completa (fecha, hora, doctor)
- [ ] Botones de acción funcionan
- [ ] Manejo de lista vacía

### 🎨 UI/UX
- [ ] Colores institucionales UAGro
- [ ] Navegación entre pantallas
- [ ] Loading states funcionan
- [ ] Error messages claros
- [ ] Responsive design

### 🌐 Deployment
- [ ] GitHub Actions workflow ejecuta
- [ ] Build sin errores
- [ ] Deploy a GitHub Pages exitoso
- [ ] Dominio app.carnetdigital.space accesible
- [ ] Performance optimizada

## 🔄 Casos de Prueba

### Caso 1: Login Exitoso
```
Correo: estudiante@uagro.mx
Matrícula: 123
Resultado Esperado: Acceso al carnet digital
```

### Caso 2: Login con Matrícula Larga
```
Correo: alumno@uagro.mx  
Matrícula: 123456789
Resultado Esperado: Acceso normal
```

### Caso 3: Error de Validación
```
Correo: invalid@gmail.com
Matrícula: 12
Resultado Esperado: Mensajes de error apropiados
```

### Caso 4: Backend Timeout
```
Simular conexión lenta/timeout
Resultado Esperado: Mensaje de error de conexión
```

## 📊 Métricas de Performance

- [ ] Tiempo de carga inicial < 3 segundos
- [ ] Login response time < 2 segundos
- [ ] Navegación fluida
- [ ] Tamaño de bundle optimizado
- [ ] Assets tree-shaked correctamente

## 🔧 Tests Técnicos

### Frontend
```bash
flutter test                 # Unit tests
flutter analyze             # Static analysis
flutter build web --release # Production build
```

### Backend Integration
```bash
curl -X POST https://carnet-alumnos-nodes.onrender.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"correo":"test@uagro.mx","matricula":"123"}'
```

## ✅ Criterios de Aceptación

1. **Funcionalidad**: Todas las features principales funcionan
2. **Performance**: Tiempos de respuesta aceptables  
3. **Seguridad**: JWT authentication funcional
4. **UX**: Interfaz intuitiva y responsive
5. **Deployment**: Proceso automático sin errores
6. **Compatibility**: Funciona en Edge, Chrome, Firefox

## 🚀 Checklist Final de Deployment

- [ ] Código compilado sin warnings
- [ ] GitHub Actions verde
- [ ] Dominio personalizado activo
- [ ] HTTPS configurado correctamente
- [ ] SEO básico implementado
- [ ] Documentación actualizada