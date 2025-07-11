import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kheti_sahayak_app/providers/user_provider.dart';
import 'package:kheti_sahayak_app/providers/cart_provider.dart';
import 'package:kheti_sahayak_app/providers/order_provider.dart';
import 'package:kheti_sahayak_app/routes/routes.dart';
import 'package:kheti_sahayak_app/theme/app_theme.dart';
import 'package:kheti_sahayak_app/utils/logger.dart';
import 'package:kheti_sahayak_app/screens/splash/splash_screen.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize logger
  Logger.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
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
  }

  Future<void> _initProviders() async {
    // Initialize user provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.initialize();

    // Initialize cart provider
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await cartProvider.loadCart();

    // Initialize orders if user is logged in
    if (userProvider.isAuthenticated) {
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
    return MaterialApp(
      title: 'Kheti Sahayak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        // Handle dynamic routes here if needed
        return MaterialPageRoute(
          builder: (context) => const SplashScreen(), // Fallback screen
          settings: settings,
        );
      },
      routes: AppRoutes.routes,
    );
  }
}