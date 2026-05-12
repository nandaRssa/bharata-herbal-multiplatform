import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'base_service.dart';
import '../screens/order_detail_screen.dart';

class FcmService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final BaseService _baseService = BaseService();

  static String? _currentToken;

  static String? get currentToken => _currentToken;

  /// Global navigator key untuk navigasi dari notifikasi
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  Future<void> init() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _currentToken = await _fcm.getToken();
    debugPrint('FCM Token: $_currentToken');

    if (_currentToken != null) {
      await _sendTokenToServer(_currentToken!);
    }

    _fcm.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      _sendTokenToServer(newToken);
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      final options = await _baseService.authOptions();
      await _baseService.dio.post('/fcm-token', data: {
        'fcm_token': token,
      }, options: options);
    } catch (e) {
      debugPrint('FCM token send error: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Bharata Herbal';
    final body = message.notification?.body ?? '';
    final orderId = int.tryParse(message.data['order_id'] ?? '');
    final status = message.data['status'] ?? 'info';

    if (orderId != null) {
      await NotificationService().showOrderNotification(
        orderId: orderId,
        orderNumber: message.data['order_number'] ?? '',
        status: status,
      );
      return;
    }

    await NotificationService().showGenericNotification(
      title: title,
      body: body,
      payload: message.data['type'],
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final orderId = message.data['order_id'];
    if (orderId != null) {
      debugPrint('FCM tapped with order_id: $orderId');
      // Navigate ke OrderDetailScreen
      final id = int.tryParse(orderId);
      if (id != null && navigatorKey.currentState?.context.mounted == true) {
        Navigator.of(navigatorKey.currentState!.context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: id),
          ),
        );
      }
    }
  }
}
