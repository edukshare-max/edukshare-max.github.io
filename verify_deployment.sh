#!/bin/bash#!/bin/bash

# 🔍 SCRIPT DE VERIFICACIÓN DEPLOYMENT

echo "🚀 VERIFICANDO DESPLIEGUE DE APP.CARNETDIGITAL.SPACE"# Monitorea el estado del Carnet Digital UAGro

echo "=================================================="

echo "🎓 Carnet Digital UAGro - Verificación de Deployment"

echo "📋 Verificando URLs..."echo "=================================================="

echo ""echo ""



echo "1️⃣ Verificando GitHub Pages principal:"echo "📅 Timestamp: $(date)"

curl -s -o /dev/null -w "Status: %{http_code}\n" https://edukshare-max.github.ioecho ""



echo ""echo "🌐 Verificando sitio principal..."

echo "2️⃣ Verificando dominio personalizado:"curl -I https://app.carnetdigital.space 2>/dev/null | head -1

curl -s -o /dev/null -w "Status: %{http_code}\n" https://app.carnetdigital.spaceecho ""



echo ""echo "🏥 Verificando backend SASU..."

echo "3️⃣ Verificando si la aplicación carga correctamente:"curl -I https://carnet-alumnos-nodes.onrender.com 2>/dev/null | head -1

curl -s https://app.carnetdigital.space | grep -q "Carnet Digital" && echo "✅ Aplicación detectada" || echo "❌ Aplicación no detectada"echo ""



echo ""echo "📋 Endpoints críticos:"

echo "4️⃣ Verificando Flutter Service Worker:"echo "  - Login: https://carnet-alumnos-nodes.onrender.com/auth/login"

curl -s https://app.carnetdigital.space/flutter_service_worker.js | head -1echo "  - Carnet: https://carnet-alumnos-nodes.onrender.com/me/carnet"

echo "  - Citas: https://carnet-alumnos-nodes.onrender.com/citas"

echo ""echo ""

echo "🏁 Verificación completa."

echo "Si todos los estados son 200 y la aplicación está detectada, el despliegue fue exitoso."echo "🔗 Enlaces importantes:"
echo "  - Aplicación: https://app.carnetdigital.space"
echo "  - Repositorio: https://github.com/edukshare-max/edukshare-max.github.io"
echo "  - Actions: https://github.com/edukshare-max/edukshare-max.github.io/actions"
echo ""

echo "✅ Verificación completada!"