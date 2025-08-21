const CACHE_NAME = '4mrna-v2.2';
const ASSETS = [
  './manifest.json',
  './Icons/icon-192.png',
  './Icons/icon-512.png',
];

self.addEventListener('install', (e) => {
  e.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    await cache.addAll(ASSETS);
    const freshIndex = new Request('./index.html', { cache: 'reload' });
    await cache.add(freshIndex);
  })());
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.map((k) => (k !== CACHE_NAME ? caches.delete(k) : undefined)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (e) => {
  const req = e.request;

  if (req.mode === 'navigate') {
    e.respondWith((async () => {
      try {
        const fresh = await fetch(new Request(req, { cache: 'no-store' }));
        const cache = await caches.open(CACHE_NAME);
        await cache.put('./index.html', fresh.clone());
        return fresh;
      } catch {

        return (await caches.match('./index.html')) ||
               new Response('Offline', { status: 503, statusText: 'Offline' });
      }
    })());
    return;
  }

  e.respondWith((async () => {
    const cached = await caches.match(req);
    if (cached) return cached;
    try {
      return await fetch(req);
    } catch {
      return cached || Response.error();
    }
  })());
});
