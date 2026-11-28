const CACHE_NAME = 'somase-static-v6';
const STATIC_ASSETS = [
    '/assets/css/app.css',
    '/assets/js/app.js',
    '/assets/js/bank-autocomplete.js',
    '/assets/brand/somase-wordmark-light.png',
    '/assets/brand/somase-logo-horizontal-light.png',
    '/assets/icons/icon-192.png',
    '/assets/icons/favicon-32.png',
    '/manifest.json',
];

self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then((cache) => cache.addAll(STATIC_ASSETS))
            .then(() => self.skipWaiting())
    );
});

self.addEventListener('activate', (event) => {
    event.waitUntil(
        caches.keys()
            .then((keys) => Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))))
            .then(() => self.clients.claim())
    );
});

self.addEventListener('fetch', (event) => {
    if (event.request.method !== 'GET' || new URL(event.request.url).origin !== self.location.origin) return;
    // Anexos sao privados e podem ser grandes: vao direto para a rede.
    if (/\/lancamentos\/\d+\/anexo/.test(new URL(event.request.url).pathname)) return;
    event.respondWith(
        fetch(event.request).then((response) => {
            const copy = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
            return response;
        }).catch(() => caches.match(event.request).then((cached) => cached || caches.match('/dashboard')))
    );
});
