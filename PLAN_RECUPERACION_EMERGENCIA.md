# 🚨 RECUPERACIÓN DE EMERGENCIA - CÓDIGO FLUTTER

## ESCENARIO 1: CÓDIGO FLUTTER ROTO LOCALMENTE

### OPCIÓN A: Volver al Tag (Más rápido)
```bash
cd "c:\Users\gilbe\Documents\Carnet_digital _alumnos"
git reset --hard v2.0-FUNCIONAL-PRESENTACION
flutter clean
flutter pub get
flutter build web
```

### OPCIÓN B: Volver desde respaldo físico
```bash
# 1. Borrar proyecto actual
Remove-Item "c:\Users\gilbe\Documents\Carnet_digital _alumnos" -Recurse -Force

# 2. Copiar desde respaldo
robocopy "C:\Users\gilbe\Documents\RESPALDO VERSION 2.0 OFICIAL UAGRO\RESPALDO VERSION 2.0 OFICIAL UAGRO1.0" "c:\Users\gilbe\Documents\Carnet_digital _alumnos" /E

# 3. Recompilar
cd "c:\Users\gilbe\Documents\Carnet_digital _alumnos"
flutter clean
flutter pub get
flutter build web
git add .
git commit -m "RECUPERACIÓN DE EMERGENCIA"
git push origin main
```

## ESCENARIO 2: FALLA EN PRODUCCIÓN (app.carnetdigital.space)

### OPCIÓN A: Revertir último commit
```bash
cd "c:\Users\gilbe\Documents\Carnet_digital _alumnos"
git log --oneline -5  # Ver últimos commits
git revert HEAD       # Revertir último commit
git push origin main  # Se despliega automáticamente
```

### OPCIÓN B: Reset total al tag funcional
```bash
cd "c:\Users\gilbe\Documents\Carnet_digital _alumnos"
git reset --hard v2.0-FUNCIONAL-PRESENTACION
git push origin main --force  # EMERGENCIA SOLO
```

## ESCENARIO 3: FALLA DEL BACKEND SASU

### NO PUEDES CONTROLAR EL BACKEND, PERO PUEDES:
```bash
# 1. Activar modo offline temporal
# 2. Mostrar mensaje de mantenimiento
# 3. Usar datos de cache/demo temporalmente
```

## TIEMPOS DE RECUPERACIÓN:
- ⚡ Tag Recovery: 30 segundos
- 🔄 Backup físico: 2 minutos  
- 🌐 Producción: 1-3 minutos (GitHub Actions)