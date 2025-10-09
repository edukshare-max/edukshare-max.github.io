#!/bin/bash
# Script post-deploy para Render
# Este script se ejecuta automáticamente después del despliegue

echo "🚀 Ejecutando script post-deploy..."

# Esperar 5 segundos para que la base de datos esté lista
echo "⏳ Esperando conexión a base de datos..."
sleep 5

# Poblar base de datos con datos iniciales
echo "🌱 Poblando base de datos..."
npm run seed

# Verificar que todo está funcionando
echo "✅ Post-deploy completado"
