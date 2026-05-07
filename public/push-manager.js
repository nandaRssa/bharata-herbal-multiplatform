/**
 * Bharata Herbal Admin — Web Push Subscription Manager
 * Handles push notification subscription for admin users.
 */

const VAPID_PUBLIC_KEY = 'BEl62iUYgUivxIkv69yViEuiBIa-Ib9-SkvMeAtA3LFgDzkrxZJjSgSnfckjBJuBkr3qBUYIHBQFLXYp5Nksh8U';

// ─── Utility: urlBase64ToUint8Array ────────────────────────────────────────
function urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4);
    const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
    const rawData = atob(base64);
    return Uint8Array.from([...rawData].map(c => c.charCodeAt(0)));
}

// ─── Init Push Manager ──────────────────────────────────────────────────────
async function initPushNotifications() {
    if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
        console.warn('[Push] Browser tidak mendukung Web Push');
        return;
    }

    try {
        const registration = await navigator.serviceWorker.ready;
        const permission = await Notification.requestPermission();

        if (permission !== 'granted') {
            console.warn('[Push] Izin notifikasi ditolak');
            updatePushUI('denied');
            return;
        }

        // Check existing subscription
        let subscription = await registration.pushManager.getSubscription();

        if (!subscription) {
            // Create new subscription
            subscription = await registration.pushManager.subscribe({
                userVisibleOnly: true,
                applicationServerKey: urlBase64ToUint8Array(VAPID_PUBLIC_KEY),
            });
        }

        // Send subscription to server
        await sendSubscriptionToServer(subscription);
        updatePushUI('subscribed');
        console.log('[Push] Subscription aktif:', subscription.endpoint);

    } catch (error) {
        console.error('[Push] Error:', error);
        updatePushUI('error');
    }
}

// ─── Unsubscribe ────────────────────────────────────────────────────────────
async function unsubscribePush() {
    try {
        const registration = await navigator.serviceWorker.ready;
        const subscription = await registration.pushManager.getSubscription();

        if (subscription) {
            await subscription.unsubscribe();
            updatePushUI('unsubscribed');
            console.log('[Push] Berhasil unsubscribe');
        }
    } catch (error) {
        console.error('[Push] Error unsubscribe:', error);
    }
}

// ─── Send Subscription to Server ───────────────────────────────────────────
async function sendSubscriptionToServer(subscription) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

    try {
        const response = await fetch('/admin/push/subscribe', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': csrfToken || '',
            },
            body: JSON.stringify({
                subscription: subscription.toJSON(),
                endpoint: subscription.endpoint,
                keys: {
                    p256dh: btoa(String.fromCharCode(...new Uint8Array(subscription.getKey('p256dh')))),
                    auth: btoa(String.fromCharCode(...new Uint8Array(subscription.getKey('auth')))),
                },
            }),
        });

        if (!response.ok) {
            console.warn('[Push] Server response:', response.status);
        }
    } catch (err) {
        // Server endpoint belum dibuat — simpan ke localStorage saja
        localStorage.setItem('pushSubscription', JSON.stringify(subscription.toJSON()));
        console.log('[Push] Subscription disimpan lokal (server endpoint belum tersedia)');
    }
}

// ─── Update UI ──────────────────────────────────────────────────────────────
function updatePushUI(state) {
    const btn = document.getElementById('push-toggle-btn');
    const indicator = document.getElementById('push-status-indicator');
    const label = document.getElementById('push-status-label');

    if (!btn) return;

    const states = {
        subscribed:   { color: 'text-green-600', dot: 'bg-green-500', text: 'Aktif',    btnText: 'Matikan Notifikasi' },
        unsubscribed: { color: 'text-gray-500',  dot: 'bg-gray-400',  text: 'Nonaktif', btnText: 'Aktifkan Notifikasi' },
        denied:       { color: 'text-red-500',   dot: 'bg-red-500',   text: 'Diblokir', btnText: 'Izin Ditolak' },
        error:        { color: 'text-amber-500', dot: 'bg-amber-400', text: 'Error',    btnText: 'Coba Lagi' },
    };

    const s = states[state] || states.unsubscribed;
    if (indicator) indicator.className = `w-2 h-2 rounded-full ${s.dot}`;
    if (label)     { label.textContent = s.text; label.className = `text-xs font-medium ${s.color}`; }
    if (btn)       btn.textContent = s.btnText;

    // Store state
    localStorage.setItem('pushState', state);
}

// ─── Test Notification ──────────────────────────────────────────────────────
async function testPushNotification(type = 'order') {
    const reg = await navigator.serviceWorker.ready;

    const messages = {
        order: {
            title: '🛒 Pesanan Baru!',
            body: 'Ada pesanan baru dari pelanggan. Segera proses!',
            url: '/admin/orders',
        },
        stock: {
            title: '⚠️ Stok Menipis!',
            body: 'Beberapa produk memiliki stok di bawah 10 unit.',
            url: '/admin/products?status=warning',
        },
    };

    const data = messages[type] || messages.order;

    await reg.showNotification(data.title, {
        body: data.body,
        icon: '/images/logo-bharata.jpeg',
        badge: '/images/logo-bharata.jpeg',
        data: { url: data.url },
        vibrate: [200, 100, 200],
        actions: [
            { action: 'open',    title: 'Buka Dashboard' },
            { action: 'dismiss', title: 'Tutup' },
        ],
    });
}

// ─── Auto-init on DOM ready ─────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    // Restore previous state
    const savedState = localStorage.getItem('pushState');
    if (savedState) updatePushUI(savedState);

    // Push toggle button
    const btn = document.getElementById('push-toggle-btn');
    if (btn) {
        btn.addEventListener('click', async () => {
            const current = localStorage.getItem('pushState');
            if (current === 'subscribed') {
                await unsubscribePush();
            } else {
                await initPushNotifications();
            }
        });
    }

    // Test buttons
    document.getElementById('push-test-order')?.addEventListener('click', () => testPushNotification('order'));
    document.getElementById('push-test-stock')?.addEventListener('click', () => testPushNotification('stock'));
});
