// Bharata Herbal Admin - PWA Helper
// Menangani PWA installation dan display

class PWAHelper {
  constructor() {
    this.deferredPrompt = null;
    this.isInstalled = false;
    this.init();
  }

  async init() {
    // Register service worker
    this.registerServiceWorker();

    // Setup PWA install prompt
    window.addEventListener('beforeinstallprompt', (e) => {
      e.preventDefault();
      this.deferredPrompt = e;
      this.showInstallButton();
    });

    // Check if already installed
    window.addEventListener('appinstalled', () => {
      console.log('[PWA] App installed successfully');
      this.isInstalled = true;
      this.hideInstallButton();
      this.showNotification('Aplikasi berhasil dipasang! Anda dapat membukanya dari desktop atau app menu.');
    });

    // Detect if running as PWA
    if (window.navigator.standalone === true || window.matchMedia('(display-mode: standalone)').matches) {
      console.log('[PWA] Already running as standalone app');
      this.isInstalled = true;
      this.hideInstallButton();
    }
  }

  async registerServiceWorker() {
    if ('serviceWorker' in navigator) {
      try {
        const registration = await navigator.serviceWorker.register('/service-worker.js', {
          scope: '/admin',
        });
        console.log('[PWA] Service Worker registered:', registration);

        // Check for updates periodically
        setInterval(() => {
          registration.update();
        }, 60000);

        // Listen for SW updates
        registration.addEventListener('updatefound', () => {
          const newWorker = registration.installing;
          newWorker.addEventListener('statechange', () => {
            if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
              console.log('[PWA] New service worker available');
              this.showUpdateNotification();
            }
          });
        });
      } catch (err) {
        console.warn('[PWA] Service Worker registration failed:', err);
      }
    }
  }

  showInstallButton() {
    const btn = document.getElementById('pwaInstallBtn');
    if (btn) {
      btn.style.display = 'flex';
      btn.addEventListener('click', () => this.installApp());
    }
  }

  hideInstallButton() {
    const btn = document.getElementById('pwaInstallBtn');
    if (btn) {
      btn.style.display = 'none';
    }
  }

  async installApp() {
    if (!this.deferredPrompt) {
      return;
    }

    // Show install prompt
    this.deferredPrompt.prompt();
    const result = await this.deferredPrompt.userChoice;

    if (result.outcome === 'accepted') {
      console.log('[PWA] User installed the app');
    } else {
      console.log('[PWA] User declined installation');
    }

    this.deferredPrompt = null;
  }

  showNotification(message) {
    // Create a simple toast notification
    const toast = document.createElement('div');
    toast.className = 'pwa-notification';
    toast.innerHTML = `
      <div style="display: flex; align-items: center; gap: 12px;">
        <span style="font-size: 1.2rem;">✅</span>
        <span>${message}</span>
      </div>
    `;
    document.body.appendChild(toast);

    setTimeout(() => {
      toast.classList.add('pwa-notification-fade-out');
      setTimeout(() => toast.remove(), 300);
    }, 4000);
  }

  showUpdateNotification() {
    const toast = document.createElement('div');
    toast.className = 'pwa-notification pwa-notification-update';
    toast.innerHTML = `
      <div style="display: flex; align-items: center; justify-content: space-between; gap: 12px;">
        <span>Versi baru tersedia. <strong>Reload</strong> untuk update.</span>
        <button onclick="location.reload()" style="
          padding: 6px 12px;
          background: white;
          border: none;
          border-radius: 4px;
          cursor: pointer;
          font-weight: 600;
          font-size: 0.85rem;
        ">Reload</button>
      </div>
    `;
    document.body.appendChild(toast);
  }

  // Uninstall/Clear cache
  async clearCache() {
    if ('serviceWorker' in navigator && navigator.serviceWorker.controller) {
      const channel = new MessageChannel();
      navigator.serviceWorker.controller.postMessage(
        { type: 'CLEAR_CACHE' },
        [channel.port2]
      );
      
      return new Promise((resolve) => {
        channel.port1.onmessage = (event) => {
          if (event.data.success) {
            console.log('[PWA] Cache cleared');
            resolve(true);
          }
        };
      });
    }
  }
}

// Initialize PWA Helper when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    window.pwaHelper = new PWAHelper();
    setupNotificationButton();
  });
} else {
  window.pwaHelper = new PWAHelper();
  setupNotificationButton();
}

// Setup notification permission button
function setupNotificationButton() {
  const notificationBtn = document.getElementById('notificationPermissionBtn');
  if (!notificationBtn) return;

  // Wait for both notification manager and polling to be ready
  let waitAttempts = 0;
  const maxAttempts = 100; // 10 seconds max wait (100 * 100ms)

  const trySetup = () => {
    if (window.notificationManager && window.notificationPolling) {
      attachNotificationButtonHandler(notificationBtn);
    } else if (waitAttempts < maxAttempts) {
      waitAttempts++;
      setTimeout(trySetup, 100);
    }
  };

  trySetup();
}

// Attach click handler to notification button
function attachNotificationButtonHandler(notificationBtn) {
  // Update button state
  function updateButtonState() {
    if ('Notification' in window) {
      if (Notification.permission === 'granted') {
        notificationBtn.classList.add('bg-green-50', 'border-green-300');
        notificationBtn.classList.remove('bg-white', 'border-gray-200', 'hover:bg-blue-50', 'hover:border-blue-300');
        notificationBtn.innerHTML = `
          <svg class="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <span class="text-green-700">Aktif</span>
        `;
        notificationBtn.disabled = true;
      } else if (Notification.permission === 'denied') {
        notificationBtn.classList.add('opacity-50', 'cursor-not-allowed');
        notificationBtn.disabled = true;
        notificationBtn.title = 'Anda sudah menolak notifikasi. Ubah di pengaturan browser.';
      }
    }
  }

  // Initial state
  updateButtonState();

  // Handle click
  notificationBtn.addEventListener('click', async () => {
    if (!('Notification' in window)) {
      alert('Browser Anda tidak support Web Notifications');
      return;
    }

    const granted = await window.notificationManager.requestPermission();

    if (granted) {
      updateButtonState();

      // Start polling
      if (window.notificationPolling) {
        window.notificationPolling.updateEnabled(true);
        console.log('[PWA] Notification polling started');
      }
    } else {
      alert('Notifikasi ditolak. Silakan ubah di pengaturan browser.');
    }
  });
}

