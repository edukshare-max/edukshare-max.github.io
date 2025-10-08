#!/bin/bash
# 🔍 SCRIPT DE VERIFICACIÓN DEPLOYMENT
# Monitorea el estado del Carnet Digital UAGro

echo "🎓 Carnet Digital UAGro - Verificación de Deployment"
echo "=================================================="
echo ""

echo "📅 Timestamp: $(date)"
echo ""

echo "🌐 Verificando sitio principal..."
curl -I https://app.carnetdigital.space 2>/dev/null | head -1
echo ""

echo "🏥 Verificando backend SASU..."
curl -I https://carnet-alumnos-nodes.onrender.com 2>/dev/null | head -1
echo ""

echo "📋 Endpoints críticos:"
echo "  - Login: https://carnet-alumnos-nodes.onrender.com/auth/login"
echo "  - Carnet: https://carnet-alumnos-nodes.onrender.com/me/carnet"
echo "  - Citas: https://carnet-alumnos-nodes.onrender.com/citas"
echo ""

echo "🔗 Enlaces importantes:"
echo "  - Aplicación: https://app.carnetdigital.space"
echo "  - Repositorio: https://github.com/edukshare-max/edukshare-max.github.io"
echo "  - Actions: https://github.com/edukshare-max/edukshare-max.github.io/actions"
echo ""

echo "✅ Verificación completada!"