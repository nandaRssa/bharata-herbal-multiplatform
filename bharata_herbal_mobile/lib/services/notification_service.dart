import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service untuk menampilkan local push notification update status pesanan
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Bisa navigate ke OrderDetail berdasarkan payload
      },
    );

    _initialized = true;
  }

  Future<void> showOrderNotification({
    required int orderId,
    required String orderNumber,
    required String status,
  }) async {
    await init();

    final statusLabel = _statusLabel(status);
    final body = _statusBody(status, orderNumber);

    const androidDetails = AndroidNotificationDetails(
      'bharata_herbal_orders',
      'Status Pesanan',
      channelDescription: 'Notifikasi update status pesanan Bharata Herbal',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      orderId, // ID notif = ID pesanan agar unik
      '🌿 Bharata Herbal — $statusLabel',
      body,
      details,
      payload: '$orderId',
    );
  }

  /// Demo: Notif saat user baru checkout / buat pesanan
  Future<void> showCheckoutSuccessNotification(
    String orderNumber,
    String totalPrice,
  ) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'bharata_herbal_orders',
      'Status Pesanan',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '✅ Pesanan Berhasil Dibuat!',
      'Pesanan $orderNumber senilai $totalPrice sedang diproses.',
      const NotificationDetails(android: androidDetails),
    );
  }

  String _statusLabel(String status) {
    const map = {
      'pending': 'Menunggu Konfirmasi',
      'unpaid': 'Menunggu Pembayaran',
      'processing': 'Sedang Diproses',
      'shipped': 'Pesanan Dikirim',
      'completed': 'Pesanan Selesai',
      'cancelled': 'Pesanan Dibatalkan',
    };
    return map[status] ?? status;
  }

  String _statusBody(String status, String orderNumber) {
    const map = {
      'pending': 'Pesanan sedang menunggu konfirmasi dari admin.',
      'unpaid': 'Silakan selesaikan pembayaran untuk pesananmu.',
      'processing': 'Pesananmu sedang dikemas dan dipersiapkan.',
      'shipped': 'Pesananmu sedang dalam perjalanan ke alamatmu!',
      'completed': 'Pesananmu telah sampai. Jangan lupa berikan ulasan!',
      'cancelled': 'Pesananmu telah dibatalkan.',
    };
    return '${map[status] ?? ''} (No. $orderNumber)';
  }
}
