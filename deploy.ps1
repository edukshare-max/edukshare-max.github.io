# Script de Despliegue a app.carnetdigital.space
# Carnet Digital UAGro - Versión de Producción

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   DESPLIEGUE A app.carnetdigital.space" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Paso 1: Limpiar build anterior
Write-Host "Paso 1/6: Limpiando builds anteriores..." -ForegroundColor Yellow
flutter clean
Write-Host "✓ Build anterior limpiado" -ForegroundColor Green
Write-Host ""

# Paso 2: Obtener dependencias
Write-Host "Paso 2/6: Instalando dependencias..." -ForegroundColor Yellow
flutter pub get
Write-Host "✓ Dependencias instaladas" -ForegroundColor Green
Write-Host ""

# Paso 3: Build de producción
Write-Host "Paso 3/6: Generando build de producción..." -ForegroundColor Yellow
flutter build web --release
Write-Host "✓ Build generado exitosamente" -ForegroundColor Green
Write-Host ""

# Paso 4: Copiar archivos necesarios
Write-Host "Paso 4/6: Copiando archivos de configuración..." -ForegroundColor Yellow
Copy-Item "CNAME" -Destination "build\web\CNAME" -Force
Copy-Item "web\favicon.png" -Destination "build\web\favicon.png" -Force -ErrorAction SilentlyContinue
Write-Host "✓ CNAME y assets copiados" -ForegroundColor Green
Write-Host ""

# Paso 5: Commit y Push
Write-Host "Paso 5/6: Preparando commit de producción..." -ForegroundColor Yellow
git add build/web
git add CNAME
git commit -m "deploy: Build de producción con nuevo diseño UAGro - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-Host "✓ Commit creado" -ForegroundColor Green
Write-Host ""

# Paso 6: Push a GitHub
Write-Host "Paso 6/6: Subiendo a GitHub..." -ForegroundColor Yellow
git push origin redesign-preview
Write-Host "✓ Push completado" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   ✓ DESPLIEGUE COMPLETADO" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Tu aplicación estará disponible en:" -ForegroundColor White
Write-Host "https://app.carnetdigital.space" -ForegroundColor Cyan
Write-Host ""
Write-Host "Nota: GitHub Pages puede tardar 1-5 minutos en actualizar" -ForegroundColor Yellow
