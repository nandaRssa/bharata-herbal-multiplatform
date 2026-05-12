/**
 * Bharata Herbal Admin — Push Subscription Manager
 * Handles notification permission + push subscription for admin users.
 */

const VAPID_PUBLIC_KEY = 'BEl62iUYgUivxIkv69yViEuiBIa-Ib9-SkvMeAtA3LFgDzkrxZJjSgSnfckjBJuBkr3qBUYIHBQFLXYp5Nksh8U';

// ─── Utility: urlBase64ToUint8Array ────────────────────────────────────────
function urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4);
    const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
    const rawData = atob(base64);
    return Uint8Array.from([...rawData].map(c => c.charCodeAt(0)));
}

// ─── Get actual notification & push state ───────────────────────────────────
async function getActualPushState() {
    if (!('Notification' in window)) return 'unsupported';
    if (Notification.permission === 'denied') return 'denied';
    if (Notification.permission === 'granted') {
        // Check push subscription (optional enhancement)
        if ('serviceWorker' in navigator && 'PushManager' in window) {
            try {
                const reg = await navigator.serviceWorker.ready;
                const sub = await reg.pushManager.getSubscription();
                return sub ? 'subscribed' : 'unsubscribed';
            } catch { return 'unsubscribed'; }
        }
        return 'unsubscribed';
    }
    return 'unsubscribed';
}

// ─── Request notification permission ───────────────────────────────────────
async function requestNotificationPermission() {
    if (!('Notification' in window)) {
        alert('Browser tidak mendukung notifikasi.');
        return false;
    }

    if (Notification.permission === 'granted') return true;
    if (Notification.permission === 'denied') {
        const site = window.location.origin;
        const isEdge = navigator.userAgent.includes('Edg');
        const url = isEdge
            ? `edge://settings/content/siteDetails?site=${site}`
            : `chrome://settings/content/siteDetails?site=${site}`;
        alert(
            'Notifikasi diblokir browser.\n\n' +
            '1. Buka: ' + url + '\n' +
            '2. Set Notifications → Allow\n' +
            '3. Klik "Clear permissions" / "Hapus data"\n' +
            '4. Hard refresh (Ctrl+Shift+R)'
        );
        return false;
    }

    const permission = await Notification.requestPermission();
    return permission === 'granted';
}

// ─── Try Push API subscription (optional, does not block UI) ───────────────
async function tryPushSubscribe() {
    if (!('serviceWorker' in navigator) || !('PushManager' in window)) return;
    try {
        const reg = await navigator.serviceWorker.ready;
        let sub = await reg.pushManager.getSubscription();
        if (!sub) {
            sub = await reg.pushManager.subscribe({
                userVisibleOnly: true,
                applicationServerKey: urlBase64ToUint8Array(VAPID_PUBLIC_KEY),
            });
        }
        // Send to server (fire-and-forget)
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
        fetch('/admin/push/subscribe', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': csrfToken || '' },
            body: JSON.stringify({ subscription: sub.toJSON(), endpoint: sub.endpoint, keys: {} }),
        }).catch(() => {});
    } catch (e) {
        console.warn('[Push] Subscription skipped (Push API not available):', e);
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
        denied:       { color: 'text-red-500',   dot: 'bg-red-500',   text: 'Diblokir', btnText: 'Buka Pengaturan' },
        error:        { color: 'text-amber-500', dot: 'bg-amber-400', text: 'Error',    btnText: 'Coba Lagi' },
    };

    const s = states[state] || states.unsubscribed;
    if (indicator) indicator.className = `w-2 h-2 rounded-full ${s.dot}`;
    if (label)     { label.textContent = s.text; label.className = `text-xs font-medium ${s.color}`; }
    if (btn)       btn.textContent = s.btnText;

    localStorage.setItem('pushState', state);
}

// ─── Show page-level toast fallback ─────────────────────────────────────────
function showPageToast(title, body) {
    var existing = document.getElementById('bh-toast-container');
    if (!existing) {
        var container = document.createElement('div');
        container.id = 'bh-toast-container';
        container.style.cssText = 'position:fixed;top:20px;right:20px;z-index:99999;display:flex;flex-direction:column;gap:10px;';
        document.body.appendChild(container);
    }
    var toast = document.createElement('div');
    toast.style.cssText = 'background:#1f5233;color:white;padding:14px 18px;border-radius:10px;box-shadow:0 8px 30px rgba(0,0,0,0.3);font-size:14px;max-width:360px;animation:slideIn 0.3s ease;';
    toast.innerHTML = '<div style="font-weight:700;margin-bottom:4px;">' + title + '</div><div style="opacity:0.9;">' + body + '</div>';
    document.getElementById('bh-toast-container').appendChild(toast);
    setTimeout(function() { toast.style.opacity = '0'; toast.style.transition = 'opacity 0.3s'; setTimeout(function() { toast.remove(); }, 300); }, 5000);
    console.log('[Toast] Shown:', title);
}

// ─── Test notification ──────────────────────────────────────────────────────
function testPushNotification(type) {
    if (!window.Notification || Notification.permission !== 'granted') {
        showPageToast('Notifikasi Belum Aktif', 'Klik "Aktifkan Notifikasi" di widget dashboard.');
        return;
    }

    var title = (type === 'order') ? ' Pesanan Baru!' : ' Stok Menipis!';
    var body = (type === 'order')
        ? 'Ada pesanan baru dari pelanggan. Segera proses!'
        : 'Beberapa produk memiliki stok di bawah batas minimum.';

    // Always show page toast (guaranteed visible feedback)
    showPageToast(title, body);

    // Try Notification API (may be blocked by Windows Focus Assist)
    try {
        var n = new Notification(title, { body: body, icon: '/images/logo bharata.png', tag: 'test-' + type, requireInteraction: true });
        console.log('[Test] Notification API OK:', n);
    } catch(e) {
        console.warn('[Test] Notification API gagal:', e);
    }

    // Also try via ServiceWorker as backup
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.ready.then(function(reg) {
            return reg.showNotification(title, {
                body: body, icon: '/images/logo bharata.png', badge: '/images/logo bharata.png',
                tag: 'test-' + type, requireInteraction: true, vibrate: [200,100,200],
            });
        }).catch(function(err) {
            console.warn('[Test] SW notification gagal:', err);
        });
    }
}

// ─── Auto-init on DOM ready ─────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', async () => {
    const actualState = await getActualPushState();
    updatePushUI(actualState);

    // If permission granted, try Push API subscribe (non-blocking)
    if (Notification.permission === 'granted') {
        tryPushSubscribe();
        // Enable polling
        if (window.notificationPolling) {
            window.notificationPolling.updateEnabled(true);
        }
    }

    // Push toggle button
    const btn = document.getElementById('push-toggle-btn');
    if (btn) {
        btn.addEventListener('click', async () => {
            // ── Cek permission synchronously (tanpa await) ──
            // Biar gesture klik tetap aktif untuk Notification.requestPermission()
            const perm = Notification.permission;

            if (perm === 'granted') {
                // Already granted — toggle polling / unsubscribe
                const stored = localStorage.getItem('pushState');
                if (stored === 'subscribed') {
                    // Unsubscribe
                    try {
                        const reg = await navigator.serviceWorker.ready;
                        const sub = await reg.pushManager.getSubscription();
                        if (sub) await sub.unsubscribe();
                    } catch (e) { console.warn(e); }
                    fetch('/admin/push/unsubscribe', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.content || '' },
                        body: JSON.stringify({ endpoint: '' }),
                    }).catch(() => {});
                    updatePushUI('unsubscribed');
                    if (window.notificationPolling) window.notificationPolling.updateEnabled(false);
                } else {
                    // Subscribe push (optional) + start polling
                    tryPushSubscribe();
                    if (window.notificationPolling) window.notificationPolling.updateEnabled(true);
                    updatePushUI('subscribed');
                }
                return;
            }

            if (perm === 'denied') {
                const site = window.location.origin;
                const isEdge = navigator.userAgent.includes('Edg');
                const url = isEdge
                    ? `edge://settings/content/siteDetails?site=${site}`
                    : `chrome://settings/content/siteDetails?site=${site}`;
                alert(
                    'Notifikasi diblokir browser.\n\n' +
                    '1. Buka: ' + url + '\n' +
                    '2. Set Notifications → Allow\n' +
                    '3. Klik "Clear permissions" / "Hapus data"\n' +
                    '4. Hard refresh (Ctrl+Shift+R)'
                );
                return;
            }

            // ── perm === 'default' → request langsung tanpa await sebelumnya ──
            try {
                const result = await Notification.requestPermission();
                if (result === 'granted') {
                    tryPushSubscribe();
                    if (window.notificationPolling) window.notificationPolling.updateEnabled(true);
                    updatePushUI('subscribed');
                } else if (result === 'denied') {
                    updatePushUI('denied');
                } else {
                    // 'default' — user dismissed, stay on unsubscribed
                    updatePushUI('unsubscribed');
                }
            } catch (e) {
                console.error('[Push] requestPermission error:', e);
                updatePushUI('error');
            }
        });
    }

    // Test buttons
    document.getElementById('push-test-order')?.addEventListener('click', () => testPushNotification('order'));
    document.getElementById('push-test-stock')?.addEventListener('click', () => testPushNotification('stock'));
});
