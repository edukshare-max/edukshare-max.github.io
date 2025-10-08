// 🔧 FIX PARA PROBLEMAS DE LOGIN
// Este script soluciona los problemas de compatibilidad que impiden el login

(function() {
    console.log('🔧 Aplicando fixes para login...');
    
    // Fix 1: Limpiar Service Worker problemático
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.getRegistrations().then(function(registrations) {
            for(let registration of registrations) {
                registration.unregister().then(function(boolean) {
                    console.log('✅ Service Worker limpiado:', boolean);
                });
            }
        });
    }
    
    // Fix 2: Limpiar caché localStorage que puede interferir
    try {
        // No limpiar tokens de auth, solo caché problemático
        const keysToRemove = [];
        for (let i = 0; i < localStorage.length; i++) {
            const key = localStorage.key(i);
            if (key && (key.includes('flutter') || key.includes('cache') || key.includes('service'))) {
                keysToRemove.push(key);
            }
        }
        keysToRemove.forEach(key => localStorage.removeItem(key));
        console.log('✅ Caché problemático limpiado');
    } catch (e) {
        console.log('⚠️ No se pudo limpiar caché:', e);
    }
    
    // Fix 3: Forzar recarga sin caché después de fixes
    if (window.location.search.indexOf('fixed=1') === -1) {
        console.log('🔄 Aplicando fix de recarga...');
        setTimeout(() => {
            window.location.href = window.location.href + (window.location.search ? '&' : '?') + 'fixed=1';
        }, 1000);
    } else {
        console.log('✅ Fixes aplicados, página lista para login');
    }
    
    // Fix 4: Interceptar y corregir peticiones de login (SAFE PATCH)
    const SAFE_FETCH_PATCH = true; // 🛡️ Flag para activar/desactivar
    
    if (SAFE_FETCH_PATCH) {
        const originalFetch = window.fetch;
        window.fetch = function(url, options) {
            // Solo interceptar /auth/login con body presente
            if (url && url.includes('/auth/login') && options && options.body) {
                console.log('🔧 INTERCEPTANDO LOGIN - URL:', url);
                console.log('� PAYLOAD RECIBIDO:', options.body);
                console.log('📋 HEADERS:', options.headers);
                
                try {
                    let bodyData = null;
                    let isStringBody = false;
                    let isUint8ArrayBody = false;
                    
                    // Intentar parsear el body independientemente del Content-Type
                    if (typeof options.body === 'string') {
                        try {
                            bodyData = JSON.parse(options.body);
                            isStringBody = true;
                            console.log('✅ Body parseado como JSON:', bodyData);
                        } catch (e) {
                            console.log('⚠️ Body string no es JSON válido');
                            return originalFetch.apply(this, arguments);
                        }
                    } else if (options.body instanceof Uint8Array) {
                        try {
                            console.log('🔧 Body es Uint8Array, decodificando...');
                            const decoder = new TextDecoder('utf-8');
                            const jsonString = decoder.decode(options.body);
                            console.log('📄 JSON String decodificado:', jsonString);
                            bodyData = JSON.parse(jsonString);
                            isUint8ArrayBody = true;
                            console.log('✅ Uint8Array parseado como JSON:', bodyData);
                        } catch (e) {
                            console.log('⚠️ Uint8Array no contiene JSON válido:', e.message);
                            return originalFetch.apply(this, arguments);
                        }
                    } else if (options.body && typeof options.body === 'object') {
                        bodyData = options.body;
                        console.log('✅ Body es object directo:', bodyData);
                    }
                    
                    // Aplicar fix email -> correo
                    if (bodyData && bodyData.email && !bodyData.correo) {
                        console.log('🔧 APLICANDO FIX: email -> correo');
                        bodyData.correo = bodyData.email;
                        delete bodyData.email;
                        
                        // Reconstruir body según el tipo original
                        if (isStringBody) {
                            options.body = JSON.stringify(bodyData);
                        } else if (isUint8ArrayBody) {
                            const encoder = new TextEncoder();
                            options.body = encoder.encode(JSON.stringify(bodyData));
                            console.log('🔄 Payload re-codificado como Uint8Array');
                        } else {
                            options.body = bodyData;
                        }
                        
                        console.log('✅ PAYLOAD CORREGIDO FINAL:', options.body);
                    } else {
                        console.log('🛡️ No necesita corrección o ya tiene correo');
                    }
                } catch (e) {
                    console.log('⚠️ Error al aplicar fix:', e.message);
                    // 🛡️ NO modificar options.body si hay error
                }
            }
            return originalFetch.apply(this, arguments);
        };
        console.log('✅ SAFE_FETCH_PATCH activado');
    }
    
    // Fix 5: Asegurar que el carrusel esté disponible
    window.addEventListener('load', function() {
        if (typeof PromocionesCarousel !== 'undefined') {
            console.log('✅ Carrusel disponible');
        } else {
            console.log('⚠️ Carrusel no disponible, recargando scripts...');
            const script = document.createElement('script');
            script.src = 'carousel-netflix-component.js';
            document.head.appendChild(script);
        }
    });
})();