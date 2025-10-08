// 🚀 CACHE BUSTER - v2025.10.08.20.45.30
// Fuerza la recarga de la aplicación Flutter y limpia todos los cachés

(function() {
    console.log('🚀 FORCE CACHE REFRESH INITIATED - v2025.10.08.20.45.30');
    
    // 1. Limpiar todos los localStorage
    if (typeof(Storage) !== "undefined") {
        localStorage.clear();
        sessionStorage.clear();
        console.log('✅ Storage limpiado');
    }
    
    // 2. Forzar recarga de service worker
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.getRegistrations().then(function(registrations) {
            for(let registration of registrations) {
                registration.unregister();
                console.log('✅ Service Worker desregistrado');
            }
        });
    }
    
    // 3. Limpiar cachés del navegador
    if ('caches' in window) {
        caches.keys().then(function(names) {
            for (let name of names) {
                caches.delete(name);
                console.log('✅ Cache del navegador limpiado: ' + name);
            }
        });
    }
    
    // 4. Agregar timestamp único a recursos Flutter
    window.cacheBusterTimestamp = '20251008204530';
    
    // 5. Interceptar peticiones de main.dart.js y agregar timestamp
    const originalFetch = window.fetch;
    window.fetch = function(...args) {
        if (args[0] && args[0].includes('main.dart.js')) {
            const url = new URL(args[0], window.location.origin);
            url.searchParams.set('cache_bust', window.cacheBusterTimestamp);
            args[0] = url.toString();
            console.log('🔄 Cache bust aplicado a main.dart.js: ' + args[0]);
        }
        return originalFetch.apply(this, args);
    };
    
    console.log('✅ CACHE BUSTER READY - Aplicación forzará descarga de versión más reciente');
})();