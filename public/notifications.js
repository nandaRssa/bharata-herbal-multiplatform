// Bharata Herbal Admin - Web Push Notifications Helper

class NotificationManager {
  constructor() {
    this.isSupported = 'Notification' in window;
    this.permissionGranted = false;
    this.checkPermission();
    this.setupNotifications();
  }

  checkPermission() {
    if (!this.isSupported) {
      console.log('[Notifications] Not supported in this browser');
      return;
    }

    this.permissionGranted = Notification.permission === 'granted';
    console.log('[Notifications] Permission status:', Notification.permission);
  }

  setupNotifications() {
    if (!this.isSupported) return;

    // Check if service worker is available
    if ('serviceWorker' in navigator && navigator.serviceWorker.controller) {
      console.log('[Notifications] Service Worker available for push notifications');
    }
  }

  /**
   * Request notification permission from user
   */
  async requestPermission() {
    if (!this.isSupported) {
      console.warn('[Notifications] Not supported in this browser');
      return false;
    }

    if (Notification.permission === 'granted') {
      console.log('[Notifications] Permission already granted');
      this.permissionGranted = true;
      return true;
    }

    if (Notification.permission !== 'denied') {
      try {
        const permission = await Notification.requestPermission();
        this.permissionGranted = permission === 'granted';
        console.log('[Notifications] Permission requested, result:', permission);

        if (this.permissionGranted) {
          this.showNotification('Notifikasi Diaktifkan', {
            body: 'Anda sekarang akan menerima notifikasi untuk pesanan baru dan stok menipis.',
            icon: 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 192 192"><rect fill="%231f5233" width="192" height="192"/><text x="50%" y="50%" font-size="80" font-weight="bold" text-anchor="middle" dominant-baseline="middle" fill="white" font-family="Arial">✓</text></svg>',
            tag: 'permission-granted',
            requireInteraction: false,
          });
        }

        return this.permissionGranted;
      } catch (err) {
        console.error('[Notifications] Failed to request permission:', err);
        return false;
      }
    }

    return false;
  }

  /**
   * Show a notification
   */
  showNotification(title, options = {}) {
    if (!this.isSupported || !this.permissionGranted) {
      console.warn('[Notifications] Cannot show notification - permission not granted');
      return;
    }

    const defaultOptions = {
      icon: 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 192 192"><rect fill="%231f5233" width="192" height="192"/><text x="50%" y="50%" font-size="80" font-weight="bold" text-anchor="middle" dominant-baseline="middle" fill="white" font-family="Arial">BH</text></svg>',
      badge: 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96"><circle cx="48" cy="48" r="48" fill="%231f5233"/></svg>',
      tag: 'bharata-admin-notification',
      requireInteraction: true,
    };

    const notificationOptions = { ...defaultOptions, ...options };

    try {
      const notification = new Notification(title, notificationOptions);

      // Auto-close after 7 seconds if not required to interact
      if (!notificationOptions.requireInteraction) {
        setTimeout(() => {
          if (notification) notification.close();
        }, 7000);
      }

      // Handle notification click
      notification.addEventListener('click', () => {
        window.focus();
        if (notificationOptions.url) {
          window.location.href = notificationOptions.url;
        }
      });

      console.log('[Notifications] Notification shown:', title);

      return notification;
    } catch (err) {
      console.error('[Notifications] Failed to show notification:', err);
    }
  }

  /**
   * Show New Order Notification
   */
  notifyNewOrder(orderNumber, customerName, total) {
    this.showNotification('📦 Pesanan Baru!', {
      body: `${customerName} memesan dengan total Rp ${this.formatCurrency(total)}`,
      tag: `order-${orderNumber}`,
      requireInteraction: true,
      url: `/admin/orders`,
    });
  }

  /**
   * Show Low Stock Notification
   */
  notifyLowStock(productName, currentStock) {
    this.showNotification('⚠️ Stok Menipis!', {
      body: `${productName} - Stok tersisa: ${currentStock} unit`,
      tag: `stock-${productName}`,
      requireInteraction: true,
      url: `/admin/products`,
    });
  }

  /**
   * Format currency to Rp format
   */
  formatCurrency(value) {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0,
    }).format(value);
  }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    window.notificationManager = new NotificationManager();
  });
} else {
  window.notificationManager = new NotificationManager();
}
