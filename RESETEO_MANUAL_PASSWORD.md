# 🔐 Guía de Reseteo Manual de Contraseña

## ⚠️ Situación: Alumno Olvidó su Contraseña

Cuando un alumno olvida su contraseña, el administrador puede eliminar su cuenta del sistema para que pueda registrarse nuevamente con una nueva contraseña.

---

## 📋 Método 1: Desde Azure Portal (Recomendado)

### Paso 1: Acceder a Azure Cosmos DB

1. Ve a: https://portal.azure.com
2. Busca tu recurso de Cosmos DB (probablemente "SASU" o similar)
3. En el menú lateral, haz clic en **"Data Explorer"**

### Paso 2: Localizar el Usuario

1. Expande la base de datos **"SASU"**
2. Expande el contenedor **"usuarios_matricula"**
3. Haz clic en **"Items"**
4. Busca el usuario por matrícula usando la búsqueda o filtrando:
   ```sql
   SELECT * FROM c WHERE c.matricula = "15662"
   ```

### Paso 3: Eliminar el Usuario

1. Haz clic en el documento del usuario
2. En la parte superior, haz clic en el botón **"Delete Item"** (icono de basura)
3. Confirma la eliminación

### Paso 4: Informar al Alumno

Dile al alumno:
> "Tu cuenta ha sido reseteada. Por favor, ve a la aplicación y regístrate nuevamente con tu correo y matrícula. Podrás establecer una nueva contraseña."

---

## 🔧 Método 2: Mediante Script (Para Múltiples Usuarios)

Si necesitas resetear varios usuarios, puedes usar un script de Node.js:

### Crear archivo: `reset-password.js`

```javascript
const { CosmosClient } = require('@azure/cosmos');
require('dotenv').config();

async function resetearUsuario(matricula) {
  try {
    const client = new CosmosClient({
      endpoint: process.env.COSMOS_ENDPOINT,
      key: process.env.COSMOS_KEY
    });

    const database = client.database('SASU');
    const container = database.container('usuarios_matricula');

    // Buscar usuario
    const querySpec = {
      query: 'SELECT * FROM c WHERE c.matricula = @matricula',
      parameters: [{ name: '@matricula', value: matricula }]
    };

    const { resources } = await container.items.query(querySpec).fetchAll();

    if (resources.length === 0) {
      console.log(`❌ Usuario con matrícula ${matricula} no encontrado`);
      return false;
    }

    const usuario = resources[0];

    // Eliminar usuario
    await container.item(usuario.id, matricula).delete();
    console.log(`✅ Usuario ${matricula} eliminado exitosamente`);
    console.log(`   El alumno puede registrarse nuevamente con nueva contraseña`);
    return true;

  } catch (error) {
    console.error('❌ Error:', error.message);
    return false;
  }
}

// Uso:
const matriculaAReset = process.argv[2];

if (!matriculaAReset) {
  console.log('Uso: node reset-password.js [MATRICULA]');
  console.log('Ejemplo: node reset-password.js 15662');
  process.exit(1);
}

resetearUsuario(matriculaAReset);
```

### Cómo Usar el Script:

```bash
cd carnet_alumnos_nodes
node reset-password.js 15662
```

---

## 📝 Procedimiento Completo para Soporte

### Cuando un Alumno Contacta:

**Alumno dice:** "Olvidé mi contraseña"

**Tú verificas:**
1. ¿El alumno tiene un carnet registrado? (verificar en contenedor `carnets_id`)
2. ¿La matrícula es correcta?
3. ¿El correo institucional es válido?

**Tú reseteas:**
1. Accede a Azure Portal
2. Data Explorer → SASU → usuarios_matricula
3. Busca por matrícula: `SELECT * FROM c WHERE c.matricula = "XXXXX"`
4. Elimina el documento

**Tú informas al alumno:**
```
Hola [Nombre],

Tu contraseña ha sido reseteada exitosamente.

Para recuperar el acceso a tu carnet digital:
1. Abre la aplicación: https://app.carnetdigital.space
2. Haz clic en "¿No tienes cuenta? Regístrate aquí"
3. Ingresa tu correo institucional: [correo]@uagro.mx
4. Ingresa tu matrícula: [matrícula]
5. Crea una nueva contraseña (mínimo 6 caracteres)
6. Confirma la contraseña
7. Acepta términos y condiciones
8. ¡Listo! Ya puedes acceder a tu carnet

IMPORTANTE: Anota tu nueva contraseña en un lugar seguro.

Saludos,
Soporte Técnico - Carnet Digital UAGro
```

---

## 🔍 Verificación Post-Reseteo

Después de eliminar al usuario, verifica:

1. **El usuario ya no existe en usuarios_matricula:**
   ```sql
   SELECT * FROM c WHERE c.matricula = "15662"
   ```
   Debe retornar: `[]` (vacío)

2. **El carnet sigue existiendo en carnets_id:**
   ```sql
   SELECT * FROM c WHERE c.matricula = "15662"
   ```
   Debe retornar: El documento del carnet (intacto)

3. **El alumno puede registrarse nuevamente:**
   - Ir a la app
   - Registrarse con correo + matrícula
   - Sistema valida contra carnets_id ✅
   - Crea nuevo usuario en usuarios_matricula ✅

---

## ⚠️ Notas Importantes

### ✅ Lo que SE ELIMINA:
- Credenciales de acceso (usuario + password)
- Token de sesión antiguo

### ✅ Lo que NO SE ELIMINA:
- **Datos del carnet** (nombre, foto, carrera, etc.)
- **Citas médicas**
- **Historial de vacunas**
- **Promociones**

> El alumno NO pierde ningún dato importante, solo necesita registrarse de nuevo.

---

## 🔐 Seguridad

**¿Cómo verificar que el solicitante es el dueño de la cuenta?**

Antes de resetear, pide al alumno:
1. **Nombre completo** (verificar contra carnets_id)
2. **Carrera** (verificar contra carnets_id)
3. **Correo institucional** (debe coincidir)
4. **Último dígito de matrícula** (confirmación adicional)

Solo resetea si la información coincide 100%.

---

## 📊 Estadísticas

Para llevar control de reseteos:

```sql
-- Ver total de usuarios registrados
SELECT VALUE COUNT(1) FROM c

-- Ver usuarios creados hoy
SELECT * FROM c 
WHERE c.createdAt >= "2025-10-12T00:00:00.000Z"

-- Ver usuarios por carrera (si agregas ese campo)
SELECT c.carrera, COUNT(1) as total 
FROM c 
GROUP BY c.carrera
```

---

## 🚀 Mejora Futura (Opcional)

En el futuro puedes implementar:

1. **Recuperación por email automática** (Opción 1 del documento anterior)
2. **Panel de administración web** para gestionar usuarios
3. **Auditoría de cambios** (log de quién resetea qué)
4. **Límite de reseteos** (prevenir abuso)

Por ahora, el reseteo manual es suficiente y funcional. ✅

---

## 📞 Contacto de Soporte

Si tienes dudas sobre cómo hacer un reseteo:
- Revisar esta guía
- Verificar en Azure Portal
- Probar en ambiente de prueba primero

**¡No hay forma de romper nada!** Los datos del carnet están en otro contenedor y no se ven afectados.
