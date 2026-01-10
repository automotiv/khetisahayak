
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:kheti_sahayak_app/providers/user_provider.dart';
import 'package:kheti_sahayak_app/providers/cart_provider.dart';
import 'package:kheti_sahayak_app/providers/order_provider.dart';
import 'package:kheti_sahayak_app/providers/offline_provider.dart';
import 'package:kheti_sahayak_app/routes/routes.dart';
import 'package:kheti_sahayak_app/theme/app_theme.dart';
import 'package:kheti_sahayak_app/utils/logger.dart';
import 'package:kheti_sahayak_app/screens/splash/splash_screen.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';
import 'package:kheti_sahayak_app/services/notification_preferences_service.dart';
import 'package:kheti_sahayak_app/services/connectivity_service.dart';
import 'services/task/upload_queue.dart';
import 'package:kheti_sahayak_app/services/local_notification_service.dart';
import 'package:kheti_sahayak_app/services/sync_service.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  AppLogger.init();

  // Initialize language service
  await LanguageService.instance.initialize();

  // Initialize local notifications
  await LocalNotificationService().initialize();

  // Initialize connectivity service
  await ConnectivityService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => OfflineProvider()),
        ChangeNotifierProvider.value(value: LanguageService.instance),
        ChangeNotifierProvider(create: (_) => NotificationPreferencesService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initProviders();
    _initBackgroundProcessing();
  }

  void _initBackgroundProcessing() {
    // Initialize auto-sync for activity records
    SyncService.instance.startAutoSync();
    
    // Initialize offline provider
    final offlineProvider = Provider.of<OfflineProvider>(context, listen: false);
    offlineProvider.initialize();
    
    // Try processing queued uploads at startup
    UploadQueue.processQueue();

    // Listen for connectivity changes and retry (handled by OfflineProvider now)
    ConnectivityService.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        UploadQueue.processQueue();
      }
    });
  }

  Future<void> _initProviders() async {
    // Initialize user provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.initialize();
    
    // Initialize cart provider
    if (!mounted) return;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await cartProvider.loadCart();
    
    // Initialize orders if user is logged in
    if (userProvider.isAuthenticated) {
      if (!mounted) return;
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.loadOrders();
    }
  }

  @override
  void dispose() {
    // Clean up resources when the app is disposed
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, UserProvider>(
      builder: (context, languageService, userProvider, child) {
        return MaterialApp(
          title: 'Kheti Sahayak',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          locale: languageService.locale,
          supportedLocales: const [
            Locale('en'), // English
            Locale('hi'), // Hindi
            Locale('mr'), // Marathi
            Locale('ta'), // Tamil
            Locale('kn'), // Kannada
            Locale('te'), // Telugu
            Locale('gu'), // Gujarati
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: AppRoutes.splash,
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => const SplashScreen(),
              settings: settings,
            );
          },
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
