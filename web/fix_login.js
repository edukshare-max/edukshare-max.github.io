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
    
    // Fix 4: Asegurar que el carrusel esté disponible
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