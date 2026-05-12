import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/address_provider.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'screens/splash_screen.dart';
import 'screens/order_detail_screen.dart';

Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  await initializeDateFormatting('id_ID', null);
  await NotificationService().init();
  runApp(const MyApp());
}

class _FcmInitializer extends StatefulWidget {
  final Widget child;
  const _FcmInitializer({required this.child});

  @override
  State<_FcmInitializer> createState() => _FcmInitializerState();
}

class _FcmInitializerState extends State<_FcmInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Set notification tap handler — navigate ke OrderDetailScreen
        NotificationService().onNotificationTap = (payload) {
          if (payload != null) {
            final orderId = int.tryParse(payload);
            if (orderId != null) {
              FcmService.navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(orderId: orderId),
                ),
              );
            }
          }
        };

        await FcmService().init();
      } catch (e) {
        debugPrint('FCM init skipped: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
      ],
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(
          physics: const ClampingScrollPhysics(),
        ),
        child: _FcmInitializer(
          child: MaterialApp(
            title: 'Bharata Herbal',
            debugShowCheckedModeBanner: false,
            navigatorKey: FcmService.navigatorKey,
            theme: ThemeData(
              fontFamily: 'Roboto',
              primaryColor: const Color(0xFF1A5C38),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1A5C38),
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                surfaceTintColor: Colors.white,
              ),
            ),
            home: const SplashScreen(),
          ),
        ),
      ),
    );
  }
}
