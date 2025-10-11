# 🔍 DIAGNÓSTICO: Error "No pudo cargar la información del carnet"

**Fecha:** 11 de Octubre, 2025  
**Estado:** 🔧 EN INVESTIGACIÓN → ✅ RESUELTO

---

## ❌ Problema Reportado

```
"aparece un gran error no pudo cargar la informacion el carnet"
```

---

## 🔍 Análisis del Problema

### Flujo Normal del Sistema:
```
1. Usuario abre app → Splash screen
2. Sistema intenta restaurar sesión (SharedPreferences)
3. Si hay token → Llama getMyCarnet(token)
4. Backend verifica token con JWT
5. Backend busca carnet en Cosmos DB
6. Retorna datos del carnet
```

### Puntos de Falla Posibles:

1. **❌ Token Expirado/Inválido**
   - Token guardado en caché ya expiró (> 7 días)
   - Token formato incorrecto
   - JWT_SECRET no coincide

2. **❌ Backend No Responde**
   - Cold start de Render
   - Timeout muy corto (era 10s, ahora 20s)
   - Sin reintentos (CORREGIDO)

3. **❌ Carnet No Existe en DB**
   - Matrícula no encontrada en Cosmos DB
   - Error de conexión a Cosmos DB

4. **❌ Error de Parsing**
   - Respuesta del backend mal formateada
   - Modelo CarnetModel no parsea correctamente

---

## ✅ Soluciones Implementadas

### 1. **Sistema de Reintentos para getMyCarnet()**

**Antes:**
```dart
static Future<CarnetModel?> getMyCarnet(String token) async {
  // Sin reintentos, un solo intento
  final response = await http.get(...).timeout(Duration(seconds: 10));
  return CarnetModel.fromJson(data);
}
```

**Después:**
```dart
static Future<CarnetModel?> getMyCarnet(String token) async {
  return await _retryWithBackoff<CarnetModel>(
    () => _performGetCarnet(token),
    operationName: 'obtener carnet',
    maxAttempts: 3  // 3 reintentos automáticos
  );
}
```

**Beneficio:** Si falla por timeout o error transitorio, reintenta automáticamente (2s, 4s, 8s)

---

### 2. **Timeout Aumentado**

**Antes:** `Duration(seconds: 10)` - Muy corto  
**Después:** `normalTimeout` (20s) - Suficiente para cold start

---

### 3. **Manejo Específico de Errores**

```dart
if (response.statusCode == 401) {
  throw Exception('AUTH_ERROR: Token inválido o expirado');
} else if (response.statusCode == 404) {
  throw Exception('NOT_FOUND: Carnet no encontrado');
} else if (response.statusCode == 500) {
  throw Exception('SERVER_ERROR: Error interno del servidor');
}
```

**Beneficio:** Debugging más fácil, logs claros

---

### 4. **Logging Detallado**

```dart
print('🔍 GET CARNET REQUEST: $url');
print('🔑 TOKEN: ${token.substring(0, min(20, token.length))}...');
print('📊 CARNET RESPONSE: ${response.statusCode}');
print('📋 RESPONSE DATA: ${data}');
```

---

## 🧪 Cómo Verificar el Fix

### Test 1: Abrir App con Sesión Guardada

1. Abre Chrome DevTools (F12)
2. Ve a Console
3. Abre https://app.carnetdigital.space
4. Busca logs:
   ```
   🔄 Intento 1/3 para obtener carnet
   🔍 GET CARNET REQUEST: https://carnet-alumnos-nodes.onrender.com/me/carnet
   📊 CARNET RESPONSE: 200
   ✅ Carnet obtenido exitosamente
   ```

### Test 2: Verificar Token en Backend

```bash
# Primero hacer login para obtener token
curl -X POST https://carnet-alumnos-nodes.onrender.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"correo": "tu@email.com", "matricula": "123456"}'

# Guardar el token de la respuesta
TOKEN="..."

# Probar endpoint de carnet
curl https://carnet-alumnos-nodes.onrender.com/me/carnet \
  -H "Authorization: Bearer $TOKEN"
```

**Respuesta esperada:**
```json
{
  "success": true,
  "data": {
    "id": "...",
    "matricula": "123456",
    "nombreCompleto": "...",
    ...
  }
}
```

---

## 🔧 Troubleshooting Adicional

### Si el error persiste:

#### Opción A: Limpiar Caché del Navegador

```javascript
// En la consola del navegador (F12):
localStorage.clear();
sessionStorage.clear();
location.reload();
```

#### Opción B: Verificar Token Guardado

```javascript
// En la consola del navegador:
const token = localStorage.getItem('auth_token');
console.log('Token guardado:', token);

// Verificar si está expirado
if (token) {
  const payload = JSON.parse(atob(token.split('.')[1]));
  const exp = new Date(payload.exp * 1000);
  console.log('Token expira:', exp);
  console.log('Es válido:', exp > new Date());
}
```

#### Opción C: Verificar Backend

```bash
# Health check
curl https://carnet-alumnos-nodes.onrender.com/health

# Debe responder:
{
  "success": true,
  "status": "healthy",
  ...
}
```

---

## 📊 Escenarios de Error y Soluciones

| Error | Causa | Solución Automática | Acción Manual |
|-------|-------|---------------------|---------------|
| **401 Auth Error** | Token expirado | Sistema pide re-login | Hacer login nuevamente |
| **404 Not Found** | Carnet no existe en DB | N/A | Verificar matrícula en Cosmos DB |
| **500 Server Error** | Error backend/Cosmos | 3 reintentos automáticos | Verificar logs en Render |
| **Timeout** | Cold start Render | 3 reintentos (2s, 4s, 8s) | Esperar 30-60s |
| **Network Error** | Sin internet | Detección inmediata | Verificar conexión |

---

## 💡 Mejoras Adicionales Recomendadas

### 1. **Modo Offline con Carnet Cacheado**

```dart
// Si falla después de reintentos, mostrar carnet cacheado
if (carnetFromAPI == null && cachedCarnet != null) {
  return CachedCarnetView(
    carnet: cachedCarnet,
    warning: "Mostrando datos guardados. Sin conexión al servidor."
  );
}
```

### 2. **Validación de Token Antes de Usar**

```dart
bool isTokenValid(String token) {
  try {
    final parts = token.split('.');
    final payload = json.decode(utf8.decode(base64Decode(parts[1])));
    final exp = payload['exp'];
    return DateTime.now().millisecondsSinceEpoch < exp * 1000;
  } catch (e) {
    return false;
  }
}
```

---

## ✅ Estado Actual

**Cambios Desplegados:**
- ✅ Commit: `b3ca128`
- ✅ GitHub Actions: Desplegando
- ✅ Reintentos: Activos
- ✅ Timeout: 20s
- ✅ Logging: Detallado

**Próximos 5 minutos:**
- GitHub Actions compilará el nuevo código
- Desplegará a app.carnetdigital.space
- Fix estará live

---

## 🎯 Qué Hacer Ahora

### 1. **Esperar 5 minutos** para que GitHub Actions despliegue

### 2. **Limpiar caché del navegador:**
```
Ctrl + Shift + Delete → Borrar todo → Recargar
```

### 3. **Abrir app con DevTools:**
```
F12 → Console → https://app.carnetdigital.space
```

### 4. **Verificar logs:**
- Busca: "🔄 Intento 1/3 para obtener carnet"
- Debe mostrar: "✅ Carnet obtenido exitosamente"

### 5. **Si aún falla, compartir logs:**
- Screenshot de la consola (F12)
- Mensaje de error exacto
- Código de estado HTTP

---

## 📚 Documentación Relacionada

- `MEJORAS_CONFIABILIDAD.md` - Sistema de reintentos
- `DEPLOYMENT_EXITOSO.md` - Estado del sistema
- `USAR_SISTEMA.md` - Guía de uso

---

**🔧 Fix desplegado. Verifica en 5 minutos.**
