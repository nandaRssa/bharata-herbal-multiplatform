// Bharata Herbal Admin - Notifications Polling Service

class NotificationPolling {
  constructor() {
    this.isAdmin = window.location.pathname.includes('/admin');
    this.pollInterval = 30000; // 30 seconds
    this.lastCheckTime = Math.floor(Date.now() / 1000);
    this.shownNotifications = new Set(); // Track shown notifications to avoid duplicates
    this.enabled = false;

    if (this.isAdmin) {
      this.init();
    }
  }

  init() {
    console.log('[NotificationPolling] Initialized');

    // Wait for notification manager to be ready
    const waitForNotificationManager = setInterval(() => {
      if (window.notificationManager) {
        clearInterval(waitForNotificationManager);
        this.enabled = true;
        this.startPolling();
      }
    }, 100);

    // Cleanup on page unload
    window.addEventListener('beforeunload', () => {
      this.stopPolling();
    });
  }

  startPolling() {
    if (!this.enabled) {
      console.log('[NotificationPolling] Not enabled (no notification manager)');
      return;
    }

    console.log('[NotificationPolling] Starting polling every', this.pollInterval, 'ms');

    // Initial check
    this.checkNotifications();

    // Setup interval
    this.pollIntervalId = setInterval(() => {
      this.checkNotifications();
    }, this.pollInterval);
  }

  stopPolling() {
    if (this.pollIntervalId) {
      clearInterval(this.pollIntervalId);
      console.log('[NotificationPolling] Stopped');
    }
  }

  async checkNotifications() {
    if (!window.notificationManager?.permissionGranted) {
      return;
    }

    try {
      // Check new orders
      await this.checkNewOrders();

      // Check low stock
      await this.checkLowStock();
    } catch (err) {
      console.error('[NotificationPolling] Error checking notifications:', err);
    }
  }

  async checkNewOrders() {
    try {
      const response = await fetch(`/admin/notifications/check-new-orders?last_check=${this.lastCheckTime}`);
      const result = await response.json();

      if (result.success && result.data && result.data.length > 0) {
        result.data.forEach((order) => {
          const notificationId = `order-${order.id}`;

          // Only show if not already shown
          if (!this.shownNotifications.has(notificationId)) {
            window.notificationManager.notifyNewOrder(
              order.order_number,
              order.customer_name,
              order.total_price
            );
            this.shownNotifications.add(notificationId);
          }
        });
      }
    } catch (err) {
      console.warn('[NotificationPolling] Failed to check orders:', err);
    }
  }

  async checkLowStock() {
    try {
      const response = await fetch(`/admin/notifications/check-low-stock?last_check=${this.lastCheckTime}`);
      const result = await response.json();

      if (result.success && result.data && result.data.length > 0) {
        result.data.forEach((product) => {
          const notificationId = `stock-${product.id}`;

          // Only show if not already shown
          if (!this.shownNotifications.has(notificationId)) {
            window.notificationManager.notifyLowStock(
              product.name,
              product.stock
            );
            this.shownNotifications.add(notificationId);
          }
        });
      }
    } catch (err) {
      console.warn('[NotificationPolling] Failed to check stock:', err);
    }
  }

  async getSummary() {
    try {
      const response = await fetch('/admin/notifications/summary');
      const result = await response.json();

      if (result.success) {
        return result.data;
      }
    } catch (err) {
      console.warn('[NotificationPolling] Failed to get summary:', err);
    }

    return null;
  }

  /**
   * Enable/disable polling based on permission
   */
  updateEnabled(hasPermission) {
    if (hasPermission && !this.enabled) {
      this.enabled = true;
      this.startPolling();
    } else if (!hasPermission && this.enabled) {
      this.enabled = false;
      this.stopPolling();
    }
  }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    window.notificationPolling = new NotificationPolling();
  });
} else {
  window.notificationPolling = new NotificationPolling();
}
