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
    
    // Fix 3: CACHE BUST DEFINITIVO - NUEVA URL COMPLETA
    const currentUrl = window.location.href;
    if (!currentUrl.includes('definitive_bust=v23_25')) {
        console.log('🔄 APLICANDO CACHE BUST DEFINITIVO - NUEVA URL...');
        
        // Limpiar TODOS los caches posibles
        if ('caches' in window) {
            caches.keys().then(function(names) {
                names.forEach(name => caches.delete(name));
                console.log('🗑️ Todos los caches eliminados');
            });
        }
        
        // URL completamente nueva para evitar cache
        const newUrl = window.location.protocol + '//' + window.location.host + window.location.pathname + '?definitive_bust=v23_25&timestamp=' + Date.now() + '&nocache=true';
        window.location.replace(newUrl);
        return;
    } else {
        console.log('✅ Fixes aplicados, página lista para login');
    }
    
    // 🚀 CARRUSEL COMPLETAMENTE ELIMINADO - v2025.10.08.23.00
    console.log('✅ Sistema limpio - Sin componentes de carrusel');
})();