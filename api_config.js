// Configuración para endpoints del backend
// El backend de carnet-alumnos-nodes.onrender.com requiere estos campos específicos

const API_CONFIG = {
  baseUrl: 'https://carnet-alumnos-nodes.onrender.com',
  
  // Endpoints disponibles
  endpoints: {
    login: '/auth/login',
    carnet: '/carnet',
    notas: '/notas',
    citas: '/citas'
  },
  
  // Campos requeridos para login
  loginFields: {
    // IMPORTANTE: El backend espera 'correo', NO 'email'
    email: 'correo',        // Mapeo: usar 'correo' en lugar de 'email'
    matricula: 'matricula'  // Este campo está correcto
  },
  
  // Ejemplo de payload correcto para login:
  // {
  //   "correo": "15662@uagro.mx",
  //   "matricula": "15662"
  // }
};

// Función helper para crear payload de login
function createLoginPayload(email, matricula) {
  return {
    [API_CONFIG.loginFields.email]: email,
    [API_CONFIG.loginFields.matricula]: matricula
  };
}

// Exportar para uso en Flutter
if (typeof window !== 'undefined') {
  window.API_CONFIG = API_CONFIG;
  window.createLoginPayload = createLoginPayload;
}