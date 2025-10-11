# 🔄 Plan de Rollback y Recuperación de Desastres

## 📍 Puntos de Restauración Disponibles

### ✅ RECOMENDADO: Commit `54a09f4` (Última Versión Estable)
```bash
Commit: 54a09f4
Mensaje: "feat: Sistema de reintentos, caché de sesión y mensajes específicos de error"
Fecha: Hace ~2 horas
Estado: ✅ DESPLEGADO Y FUNCIONANDO
Features:
  ✅ Sistema de reintentos (3 intentos con backoff)
  ✅ Caché de sesión (7 días)
  ✅ Timeouts optimizados (8s/20s/35s)
  ✅ Health check preventivo
  ✅ Mensajes de error específicos
  ❌ NO incluye: Fix de getMyCarnet con reintentos
  ❌ NO incluye: Limpieza automática de tokens
```

**Cuándo usar**: Si los nuevos cambios causan más problemas que soluciones.

---

### 🆕 ACTUAL: Commit `d92440c` (Con Fix de Tokens)
```bash
Commit: d92440c (HEAD -> main)
Mensaje: "docs: Documentación del fix de tokens inválidos"
Fecha: Hace ~5 minutos
Estado: 🚀 DESPLEGANDO AHORA
Features:
  ✅ Todo lo de 54a09f4 +
  ✅ Fix de getMyCarnet con reintentos
  ✅ Limpieza automática de tokens 401/403
  ✅ Auto-recuperación de sesión corrupta
```

**Cuándo usar**: Si todo funciona correctamente (esperado).

---

## 🚨 Scripts de Rollback Rápido

### Script 1: Rollback a Última Versión Estable (54a09f4)
```powershell
# ROLLBACK_ESTABLE.ps1
cd "c:\Users\gilbe\Documents\Carnet_digital _alumnos"

Write-Host "`n🔄 ROLLBACK A VERSIÓN ESTABLE 54a09f4`n" -ForegroundColor Yellow

# 1. Revertir a commit estable
git reset --hard 54a09f4
Write-Host "✅ Código revertido a commit 54a09f4" -ForegroundColor Green

# 2. Recompilar
Write-Host "`n📦 Recompilando aplicación...`n" -ForegroundColor Cyan
flutter build web --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Compilación exitosa" -ForegroundColor Green
    
    # 3. Hacer push forzado (cuidado!)
    Write-Host "`n⚠️  PUSH FORZADO A PRODUCCIÓN (5 segundos para cancelar con Ctrl+C)..." -ForegroundColor Red
    Start-Sleep -Seconds 5
    
    git push origin main --force
    
    Write-Host "`n✅ ROLLBACK COMPLETADO" -ForegroundColor Green
    Write-Host "   • Código: 54a09f4" -ForegroundColor White
    Write-Host "   • Features: Sistema de reintentos + caché + health check" -ForegroundColor White
    Write-Host "   • Sin: Fix de tokens inválidos automático" -ForegroundColor White
    Write-Host "`n🔍 Verifica en 5 minutos: https://app.carnetdigital.space`n" -ForegroundColor Cyan
} else {
    Write-Host "❌ Error en compilación" -ForegroundColor Red
    exit 1
}
```

**Ejecución**:
```powershell
# Copiar el script y ejecutar
cd "c:\Users\gilbe\Documents\Carnet_digital _alumnos"
# Pegar el script completo y ejecutar
```

---

### Script 2: Limpieza Manual de Token (Sin Rollback)
```javascript
// Ejecutar en consola del navegador (F12)
// en https://app.carnetdigital.space

// Limpiar todos los datos de la app
localStorage.clear();
sessionStorage.clear();

// Verificar limpieza
console.log('✅ Token limpiado:', localStorage.getItem('auth_token')); // null
console.log('✅ Carnet limpiado:', localStorage.getItem('cached_carnet')); // null

// Recargar página
location.reload();
```

**Cuándo usar**: Si el problema es solo el token mock y no quieres hacer rollback.

---

### Script 3: Rollback Selectivo (Revertir Solo Últimos 2 Commits)
```powershell
# ROLLBACK_PARCIAL.ps1
cd "c:\Users\gilbe\Documents\Carnet_digital _alumnos"

Write-Host "`n🔄 ROLLBACK PARCIAL (revertir fix de tokens)`n" -ForegroundColor Yellow

# Revertir últimos 2 commits pero mantener cambios de getMyCarnet
git revert HEAD~1..HEAD --no-commit

Write-Host "⚠️  Revisa los cambios con git diff antes de continuar" -ForegroundColor Yellow
Write-Host "   Si todo se ve bien, ejecuta:" -ForegroundColor White
Write-Host "   git commit -m 'revert: Revertir fix de tokens inválidos'" -ForegroundColor Cyan
Write-Host "   git push origin main`n" -ForegroundColor Cyan
```

---

## 🔬 Procedimiento de Validación Post-Rollback

### Checklist de Verificación
```bash
# 1. Verificar backend
curl https://carnet-alumnos-nodes.onrender.com/health

# 2. Verificar frontend desplegado
curl -I https://app.carnetdigital.space

# 3. Probar login con credenciales reales
# (Abrir navegador e intentar login)

# 4. Verificar logs en consola del navegador
# Debe mostrar:
# ✅ Backend SASU disponible
# ✅ Login exitoso
# ✅ Carnet cargado
# ✅ Citas cargadas
```

### Criterios de Éxito
- ✅ Login funciona sin "credenciales invalidadas"
- ✅ Carnet se carga correctamente
- ✅ Citas médicas se muestran
- ✅ No hay errores 403 en consola
- ✅ Sesión persiste al recargar página

---

## 📊 Comparación de Versiones

| Feature | 54a09f4 (Estable) | d92440c (Actual) |
|---------|-------------------|------------------|
| **Sistema de reintentos** | ✅ | ✅ |
| **Caché de sesión** | ✅ | ✅ |
| **Health check** | ✅ | ✅ |
| **Timeouts optimizados** | ✅ | ✅ |
| **Reintentos en getMyCarnet** | ❌ | ✅ |
| **Limpieza auto tokens** | ❌ | ✅ |
| **Manejo 403** | ❌ | ✅ |
| **Riesgo** | 🟢 Bajo | 🟡 Medio |
| **Estabilidad probada** | ✅ 2 horas | ⏳ 0 min |

---

## 🎯 Decisión Recomendada

### Escenario 1: Fix Funciona ✅
- **Acción**: Mantener versión actual (d92440c)
- **Beneficio**: Auto-recuperación de tokens + mejor UX
- **Riesgo**: Ninguno

### Escenario 2: Nuevos Errores Aparecen ❌
- **Acción**: Rollback a 54a09f4
- **Comando**: Ejecutar ROLLBACK_ESTABLE.ps1
- **Resultado**: Volver a versión probada (sin fix de tokens)
- **Solución temporal**: Limpiar caché del navegador manualmente

### Escenario 3: Solo Token Mock es el Problema 🔧
- **Acción**: Limpiar localStorage del navegador
- **Comando**: Ejecutar script de limpieza en consola (F12)
- **Resultado**: Mantener versión actual, sin rollback

---

## ⏱️ Timeline de Decisión

```
T+0 min (AHORA):
  └─ Deployment d92440c en progreso
  └─ Esperar 5 minutos

T+5 min:
  ├─ Abrir app.carnetdigital.space
  ├─ Verificar si token mock se limpia automáticamente
  └─ Intentar login con credenciales reales

T+7 min:
  ├─ SI FUNCIONA → ✅ Éxito, cerrar incidencia
  └─ SI FALLA → 🔄 Ejecutar ROLLBACK_ESTABLE.ps1

T+12 min (post-rollback):
  └─ Verificar que versión estable 54a09f4 funciona
  └─ Documentar lecciones aprendidas
```

---

## 📞 Checklist de Comunicación

### Si hay que hacer rollback:
```
✅ Informar a usuarios: "Mantenimiento temporal, volvemos en 10 minutos"
✅ Documentar causa raíz en POSTMORTEM.md
✅ Agregar tests antes del próximo deployment
✅ Revisar logs de producción
```

---

## 🛡️ Protecciones Futuras

### 1. Ambiente de Staging
```yaml
# Crear rama staging para probar antes de producción
git checkout -b staging
# Deployar a: staging.carnetdigital.space
# Validar 24 horas antes de merge a main
```

### 2. Feature Flags
```dart
// Habilitar/deshabilitar features sin redeploy
const bool ENABLE_AUTO_TOKEN_CLEANUP = false; // Toggle remotamente
```

### 3. Canary Deployment
```yaml
# Deployar a 10% de usuarios primero
# Si métricas OK → 100% de usuarios
```

---

## 📝 Comandos Rápidos de Referencia

```powershell
# Ver estado actual
git log --oneline -n 5

# Rollback INMEDIATO (sin compilar)
git reset --hard 54a09f4 && git push origin main --force

# Ver diferencias entre versiones
git diff 54a09f4 d92440c

# Crear tag de versión estable
git tag v1.0-stable 54a09f4
git push origin v1.0-stable

# Restaurar archivo específico
git checkout 54a09f4 -- lib/services/api_service.dart
```

---

## ✅ Checklist Pre-Decisión

Antes de decidir si hacer rollback, verificar:

- [ ] ¿El deployment terminó? (esperar 5 minutos completos)
- [ ] ¿Limpiaste el caché del navegador? (Ctrl+Shift+Delete)
- [ ] ¿Probaste con credenciales reales? (no token mock)
- [ ] ¿Revisaste la consola del navegador? (F12 → Console)
- [ ] ¿El backend está saludable? (carnet-alumnos-nodes.onrender.com/health)
- [ ] ¿Probaste en modo incógnito? (sin caché antiguo)

**Si respondiste NO a alguna**, completa esos pasos antes de hacer rollback.

---

**Creado**: 11 de octubre de 2025  
**Autor**: Sistema de Recuperación Automática  
**Versión**: 1.0.0

---

## 🚀 Ejecución de Rollback

### Opción A: Rollback Completo (PowerShell)
```powershell
cd "c:\Users\gilbe\Documents\Carnet_digital _alumnos"
git reset --hard 54a09f4
flutter build web --release
git push origin main --force
```

### Opción B: Solo Limpiar Token (Navegador)
```javascript
// En consola del navegador (F12)
localStorage.clear(); location.reload();
```

**Elige la opción según la severidad del problema.**
