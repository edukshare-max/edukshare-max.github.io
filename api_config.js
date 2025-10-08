/**
 * Configuración de API para el sistema de login
 * UAGro Digital Student Carnet System
 */

// Configuración global de la API
const API_CONFIG = {
    baseUrl: 'https://carnet-alumnos-nodes.onrender.com',
    endpoints: {
        login: '/auth/login',
        profile: '/api/student/profile',
        validationToken: '/auth/validate-token'
    },
    // Mapeo de campos del frontend al backend
    fieldMapping: {
        // Frontend -> Backend
        email: 'correo',
        matricula: 'matricula',
        password: 'password'
    },
    headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
};

/**
 * Crea el payload correcto para el login
 * @param {string} email - Email del usuario
 * @param {string} matricula - Matrícula del usuario
 * @param {string} password - Contraseña (opcional para algunos endpoints)
 * @returns {Object} Payload con campos mapeados correctamente
 */
function createLoginPayload(email, matricula, password = null) {
    const payload = {
        [API_CONFIG.fieldMapping.email]: email,
        [API_CONFIG.fieldMapping.matricula]: matricula
    };
    
    if (password) {
        payload[API_CONFIG.fieldMapping.password] = password;
    }
    
    console.log('🔧 Payload creado con mapeo correcto:', payload);
    return payload;
}

/**
 * Función helper para hacer requests con la configuración correcta
 */
async function makeApiRequest(endpoint, data, method = 'POST') {
    const url = `${API_CONFIG.baseUrl}${endpoint}`;
    
    const options = {
        method: method,
        headers: API_CONFIG.headers,
        body: method !== 'GET' ? JSON.stringify(data) : undefined
    };
    
    console.log(`🚀 API Request to: ${url}`);
    console.log(`📤 Payload:`, data);
    
    try {
        const response = await fetch(url, options);
        const responseData = await response.json();
        
        console.log(`📡 Response Status: ${response.status}`);
        console.log(`📡 Response Data:`, responseData);
        
        return {
            success: response.ok,
            status: response.status,
            data: responseData
        };
    } catch (error) {
        console.error('❌ API Request Error:', error);
        return {
            success: false,
            error: error.message
        };
    }
}

// Hacer la configuración disponible globalmente
window.API_CONFIG = API_CONFIG;
window.createLoginPayload = createLoginPayload;
window.makeApiRequest = makeApiRequest;

console.log('✅ API_CONFIG cargado correctamente');