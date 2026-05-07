// Bharata Herbal Admin Dashboard - Service Worker
// Caching strategy untuk PWA offline support

const CACHE_VERSION = 'bharata-admin-v1';
const STATIC_CACHE = `${CACHE_VERSION}-static`;
const DYNAMIC_CACHE = `${CACHE_VERSION}-dynamic`;

const STATIC_ASSETS = [
  '/admin',
  '/css/app.css',
  '/js/app.js',
  '/manifest.json',
];

// ════════════════════════════════════════════════════════════════════════
// INSTALL EVENT - Cache static assets
// ════════════════════════════════════════════════════════════════════════
self.addEventListener('install', (event) => {
  console.log('[Service Worker] Installing...');
  
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then((cache) => {
        console.log('[Service Worker] Caching static assets');
        return cache.addAll(STATIC_ASSETS).catch((err) => {
          console.warn('[Service Worker] Some assets failed to cache:', err);
          // Don't fail install if some assets can't be cached
        });
      })
      .then(() => {
        console.log('[Service Worker] Install complete');
        self.skipWaiting();
      })
  );
});

// ════════════════════════════════════════════════════════════════════════
// ACTIVATE EVENT - Clean up old caches
// ════════════════════════════════════════════════════════════════════════
self.addEventListener('activate', (event) => {
  console.log('[Service Worker] Activating...');
  
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            if (!cacheName.startsWith('bharata-admin')) {
              return;
            }
            if (cacheName !== STATIC_CACHE && cacheName !== DYNAMIC_CACHE) {
              console.log('[Service Worker] Deleting old cache:', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      })
      .then(() => {
        console.log('[Service Worker] Activation complete');
        return self.clients.claim();
      })
  );
});

// ════════════════════════════════════════════════════════════════════════
// FETCH EVENT - Network first, then cache (for API calls)
//                Cache first, then network (for assets)
// ════════════════════════════════════════════════════════════════════════
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }

  // Handle API requests (network first)
  if (url.pathname.includes('/api/') || url.pathname.includes('/admin/')) {
    event.respondWith(
      fetch(request)
        .then((response) => {
          // Only cache successful responses
          if (response.status === 200 && request.method === 'GET') {
            const clonedResponse = response.clone();
            caches.open(DYNAMIC_CACHE)
              .then((cache) => cache.put(request, clonedResponse));
          }
          return response;
        })
        .catch(() => {
          // Return cached version on network failure
          return caches.match(request)
            .then((response) => {
              return response || createOfflineResponse();
            });
        })
    );
    return;
  }

  // Handle static assets (cache first)
  if (
    url.pathname.match(/\.(js|css|png|jpg|jpeg|svg|gif|webp|woff2?|ttf|eot)$/i)
  ) {
    event.respondWith(
      caches.match(request)
        .then((response) => {
          if (response) {
            return response;
          }
          return fetch(request)
            .then((response) => {
              // Cache successful asset responses
              if (response.status === 200) {
                const clonedResponse = response.clone();
                caches.open(DYNAMIC_CACHE)
                  .then((cache) => cache.put(request, clonedResponse));
              }
              return response;
            })
            .catch(() => {
              // Return placeholder for failed assets
              return new Response('Asset not available offline', {
                status: 503,
                statusText: 'Service Unavailable',
              });
            });
        })
    );
    return;
  }

  // Default: network first
  event.respondWith(
    fetch(request)
      .then((response) => response)
      .catch(() => caches.match(request)
        .then((response) => response || createOfflineResponse()))
  );
});

// ════════════════════════════════════════════════════════════════════════
// HELPER: Create offline fallback response
// ════════════════════════════════════════════════════════════════════════
function createOfflineResponse() {
  return new Response(
    `
    <!DOCTYPE html>
    <html>
    <head>
      <title>Offline - Bharata Herbal Admin</title>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          display: flex;
          align-items: center;
          justify-content: center;
          height: 100vh;
          margin: 0;
          background: linear-gradient(135deg, #1f5233 0%, #2d8659 100%);
          color: #333;
        }
        .container {
          text-align: center;
          background: white;
          padding: 2rem;
          border-radius: 12px;
          box-shadow: 0 10px 40px rgba(0,0,0,0.1);
          max-width: 400px;
        }
        h1 {
          color: #1f5233;
          margin-top: 0;
        }
        p {
          color: #666;
          line-height: 1.6;
        }
        .icon {
          font-size: 3rem;
          margin-bottom: 1rem;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="icon">📡</div>
        <h1>Akses Offline</h1>
        <p>Anda sedang offline. Dashboard akan dimuat kembali ketika koneksi internet tersedia.</p>
        <p style="font-size: 0.9rem; color: #999; margin-top: 1.5rem;">Silakan periksa koneksi Anda dan coba lagi.</p>
      </div>
    </body>
    </html>
    `,
    {
      status: 503,
      statusText: 'Service Unavailable',
      headers: new Headers({
        'Content-Type': 'text/html; charset=utf-8',
      }),
    }
  );
}

// ════════════════════════════════════════════════════════════════════════
// MESSAGE EVENT - Handle messages from clients
// ════════════════════════════════════════════════════════════════════════
self.addEventListener('message', (event) => {
  const { type } = event.data;

  if (type === 'CLEAR_CACHE') {
    console.log('[Service Worker] Clearing caches');
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames
            .filter((name) => name.startsWith('bharata-admin'))
            .map((name) => caches.delete(name))
        );
      })
      .then(() => {
        event.ports[0].postMessage({ success: true });
      });
  }

  if (type === 'GET_CACHE_SIZE') {
    // Send cache status to client
    event.ports[0].postMessage({
      status: 'Service Worker is running',
      caches: [STATIC_CACHE, DYNAMIC_CACHE],
    });
  }
});

// ════════════════════════════════════════════════════════════════════════
// PUSH EVENT - Handle incoming push notifications
// ════════════════════════════════════════════════════════════════════════
self.addEventListener('push', function(event) {
  console.log('[Service Worker] Push received');

  let data = {
    title: 'Bharata Herbal',
    body: 'Ada notifikasi baru',
    icon: '/images/logo-bharata.jpeg',
    badge: '/images/logo-bharata.jpeg',
    url: '/admin',
  };

  if (event.data) {
    try {
      const parsed = event.data.json();
      data = { ...data, ...parsed };
    } catch (e) {
      data.body = event.data.text();
    }
  }

  const options = {
    body: data.body,
    icon: data.icon || '/images/logo-bharata.jpeg',
    badge: data.badge || '/images/logo-bharata.jpeg',
    data: { url: data.url || '/admin' },
    vibrate: [200, 100, 200],
    requireInteraction: false,
    actions: [
      { action: 'open',    title: 'Buka Dashboard' },
      { action: 'dismiss', title: 'Tutup' },
    ],
  };

  event.waitUntil(
    self.registration.showNotification(data.title, options)
  );
});

// ════════════════════════════════════════════════════════════════════════
// NOTIFICATION CLICK - Handle click on notification
// ════════════════════════════════════════════════════════════════════════
self.addEventListener('notificationclick', function(event) {
  console.log('[Service Worker] Notification click:', event.action);

  event.notification.close();

  if (event.action === 'dismiss') return;

  const targetUrl = event.notification.data?.url || '/admin';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        // If admin tab already open, focus it
        for (const client of clientList) {
          if (client.url.includes('/admin') && 'focus' in client) {
            return client.focus();
          }
        }
        // Otherwise open new tab
        if (clients.openWindow) {
          return clients.openWindow(targetUrl);
        }
      })
  );
});

console.log('[Service Worker] Loaded successfully');
