# 🔐 Fix: Limpieza Automática de Tokens Inválidos

## 📋 Problema Detectado

### Síntomas
```
🔑 TOKEN: mock_token_15662_176...
📊 CARNET RESPONSE: 403
📋 RESPONSE BODY: {"success":false,"message":"Token inválido o expirado"}
❌ No se pudo cargar el carnet
```

### Causa Raíz
1. **Token mock en caché**: Quedó un token de prueba (`mock_token_15662_176...`) guardado en `SharedPreferences`
2. **Sin limpieza automática**: El sistema intentaba usar el token inválido repetidamente
3. **Sin manejo de 403**: No había lógica para detectar y limpiar tokens rechazados por el servidor

### Impacto
- ❌ Todos los endpoints fallan con 403 (carnet, citas, promociones)
- ❌ Usuario queda atrapado en bucle de errores
- ❌ Única solución: limpiar caché del navegador manualmente

## ✅ Solución Implementada

### 1. Detección de Tokens Inválidos (`api_service.dart`)
```dart
// Antes:
} else if (response.statusCode == 401) {
  throw Exception('AUTH_ERROR: Token inválido o expirado');
}

// Después:
} else if (response.statusCode == 401 || response.statusCode == 403) {
  print('🚫 Token inválido detectado - limpiando sesión');
  throw Exception('INVALID_TOKEN: Token inválido o expirado');
}
```

**Cambios:**
- Detecta tanto 401 (no autorizado) como 403 (prohibido)
- Lanza excepción específica `INVALID_TOKEN` para identificación clara
- Agrega log de depuración para visibilidad

### 2. Limpieza Automática de Sesión (`session_provider.dart`)

#### En `_loadCarnetData()`:
```dart
} catch (e) {
  final errorStr = e.toString();
  if (errorStr.contains('INVALID_TOKEN')) {
    print('🚫 Token inválido detectado - cerrando sesión automáticamente');
    await clearCache();
    logout();
  } else {
    print('❌ Error cargando carnet: $e');
  }
}
```

#### En `_loadCitasData()`:
```dart
} catch (e) {
  final errorStr = e.toString();
  if (errorStr.contains('INVALID_TOKEN')) {
    print('🚫 Token inválido detectado - cerrando sesión automáticamente');
    await clearCache();
    logout();
  } else {
    print('❌ ERROR CARGANDO CITAS: $e');
    _citas = [];
  }
}
```

**Comportamiento:**
1. ✅ Detecta excepción `INVALID_TOKEN`
2. ✅ Llama `clearCache()` para eliminar token/carnet/timestamp de `SharedPreferences`
3. ✅ Llama `logout()` para resetear estado de sesión (_isLoggedIn = false)
4. ✅ Redirige automáticamente al login screen

## 🔬 Flujo de Auto-Recuperación

```
1. App inicia → restoreSession()
   └─ Encuentra token mock en caché
   
2. Intenta cargar carnet → getMyCarnet(mock_token)
   └─ Backend responde 403 Forbidden
   
3. ApiService detecta 403 → lanza INVALID_TOKEN
   
4. SessionProvider captura excepción
   ├─ clearCache() → elimina datos corruptos
   ├─ logout() → resetea estado
   └─ Redirige a /login
   
5. Usuario ve pantalla de login limpia ✅
   └─ Sin errores persistentes
```

## 📊 Comparación Antes/Después

| Aspecto | Antes ❌ | Después ✅ |
|---------|---------|-----------|
| **Detección** | Solo 401 | 401 + 403 |
| **Manejo** | Error genérico | Limpieza automática |
| **Experiencia** | Bucle de errores | Auto-recuperación |
| **Solución** | Manual (limpiar caché) | Automática |
| **Logs** | Confusos | Claros con emojis |

## 🧪 Validación

### Pasos de Prueba
```bash
# 1. Forzar token inválido en consola del navegador
localStorage.setItem('auth_token', 'mock_token_invalid_12345');

# 2. Recargar app
# Resultado esperado: Limpieza automática + redirección a login

# 3. Verificar logs en consola
🚫 Token inválido detectado - cerrando sesión automáticamente
💾 Caché limpiado
```

### Logs de Éxito
```
🔍 VERIFICANDO BACKEND: https://carnet-alumnos-nodes.onrender.com/health
✅ Backend SASU disponible
🔍 Cargando datos del carnet...
🔍 GET CARNET REQUEST: https://carnet-alumnos-nodes.onrender.com/me/carnet
📊 CARNET RESPONSE: 403
🚫 Token inválido detectado - limpiando sesión
💾 Caché limpiado
🔄 Sesión cerrada, redirigiendo a login
```

## 🛡️ Protección Adicional

### Casos Manejados
- ✅ Token mock de desarrollo
- ✅ Token expirado (>7 días)
- ✅ Token de otro ambiente (staging/prod)
- ✅ Token corrupto en localStorage
- ✅ Token revocado por backend

### Casos NO Manejados (todavía)
- ⏳ Renovación automática de token (refresh token)
- ⏳ Modo offline con datos cacheados
- ⏳ Migración de sesión entre dispositivos

## 📦 Archivos Modificados

### `lib/services/api_service.dart`
- Línea 226-228: Detección de 401/403 → `INVALID_TOKEN`
- **Impacto**: Todos los endpoints retornan error específico

### `lib/providers/session_provider.dart`
- Línea 230-236: Limpieza en `_loadCarnetData()`
- Línea 260-266: Limpieza en `_loadCitasData()`
- **Impacto**: Auto-recuperación de sesión corrupta

## 🚀 Deployment

```bash
# Build
flutter build web --release
# ✅ Built build\web (26.7s)

# Commit
git commit -m "fix: Limpieza automática de tokens inválidos (401/403)"
# ✅ [main 6baac01]

# Push
git push origin main
# ✅ Deployed to app.carnetdigital.space
```

## 📝 Próximos Pasos

1. ✅ **COMPLETADO**: Detectar tokens inválidos
2. ✅ **COMPLETADO**: Limpiar sesión automáticamente
3. ⏳ **PENDIENTE**: Agregar refresh token para renovación transparente
4. ⏳ **PENDIENTE**: Modo offline con últimos datos cacheados válidos
5. ⏳ **PENDIENTE**: Analytics de tokens inválidos (frecuencia, patrones)

## 🔗 Referencias

- Commit: `6baac01` - "fix: Limpieza automática de tokens inválidos (401/403)"
- Documentos relacionados:
  - `MEJORAS_CONFIABILIDAD.md` - Sistema de reintentos
  - `DIAGNOSTICO_ERROR_CARNET.md` - Error de carga de carnet
  - `DEPLOYMENT_EXITOSO.md` - Estado de despliegues

---

**Creado**: 11 de octubre de 2025  
**Estado**: ✅ Deployed en producción  
**Versión**: 1.0.0
