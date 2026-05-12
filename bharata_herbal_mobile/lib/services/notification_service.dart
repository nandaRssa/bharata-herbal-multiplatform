import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service untuk menampilkan local push notification update status pesanan
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Callback yang dipanggil saat notifikasi lokal diklik — di-set dari main
  void Function(String? payload)? onNotificationTap;

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        onNotificationTap?.call(details.payload);
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
      icon: '@drawable/ic_notification',
      enableVibration: true,
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      orderId,
      'Bharata Herbal — $statusLabel',
      body,
      details,
      payload: '$orderId',
    );
  }

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
      icon: '@drawable/ic_notification',
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Pesanan Berhasil Dibuat!',
      'Pesanan $orderNumber senilai $totalPrice sedang diproses.',
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> showGenericNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'bharata_herbal_orders',
      'Status Pesanan',
      channelDescription: 'Notifikasi Bharata Herbal',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      enableVibration: true,
      playSound: true,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  /// Handle both event names (from FCM) and status names
  String _statusLabel(String status) {
    const eventMap = {
      'order_created': 'Pesanan Dibuat',
      'payment_proof_uploaded': 'Bukti Pembayaran Diunggah',
      'payment_confirmed': 'Pembayaran Terkonfirmasi',
      'order_processing': 'Sedang Diproses',
      'order_shipped': 'Pesanan Dikirim',
      'order_completed': 'Pesanan Selesai',
      'order_cancelled': 'Pesanan Dibatalkan',
    };
    if (eventMap.containsKey(status)) return eventMap[status]!;

    const statusMap = {
      'pending': 'Menunggu',
      'pending_confirmation': 'Menunggu Konfirmasi Admin',
      'paid': 'Pembayaran Terkonfirmasi',
      'processing': 'Sedang Diproses',
      'shipped': 'Pesanan Dikirim',
      'completed': 'Pesanan Selesai',
      'cancelled': 'Pesanan Dibatalkan',
    };
    return statusMap[status] ?? status;
  }

  String _statusBody(String status, String orderNumber) {
    const eventMap = {
      'order_created': 'Pesananmu berhasil dibuat.',
      'payment_proof_uploaded': 'Bukti pembayaranmu sedang diverifikasi admin.',
      'payment_confirmed': 'Pembayaranmu sudah diverifikasi oleh admin.',
      'order_processing': 'Pesananmu sedang dikemas dan dipersiapkan.',
      'order_shipped': 'Pesananmu sedang dalam perjalanan ke alamatmu!',
      'order_completed': 'Pesananmu telah sampai. Jangan lupa berikan ulasan!',
      'order_cancelled': 'Pesananmu telah dibatalkan.',
    };
    if (eventMap.containsKey(status)) return '${eventMap[status]} (No. $orderNumber)';

    const statusMap = {
      'pending': 'Pesananmu sedang menunggu tahap berikutnya.',
      'pending_confirmation': 'Bukti pembayaranmu sedang diverifikasi oleh admin.',
      'paid': 'Pembayaranmu sudah diverifikasi oleh admin.',
      'processing': 'Pesananmu sedang dikemas dan dipersiapkan.',
      'shipped': 'Pesananmu sedang dalam perjalanan ke alamatmu!',
      'completed': 'Pesananmu telah sampai. Jangan lupa berikan ulasan!',
      'cancelled': 'Pesananmu telah dibatalkan.',
    };
    return '${statusMap[status] ?? ''} (No. $orderNumber)';
  }
}
