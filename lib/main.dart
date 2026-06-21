import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uts_1123150004/core/constants/app_strings.dart';
import 'package:uts_1123150004/core/routes/app_router.dart';
import 'package:uts_1123150004/core/services/secure_storage.dart';
import 'package:uts_1123150004/core/theme/app_theme.dart';
import 'package:uts_1123150004/features/auth/presentation/providers/auth_provider.dart';
import 'package:uts_1123150004/features/cart/presentation/providers/cart_provider.dart';
import 'package:uts_1123150004/features/cart/presentation/providers/checkout_provider.dart';
import 'package:uts_1123150004/features/dashboard/presentation/providers/product_provider.dart';
import 'package:uts_1123150004/core/services/notification_service.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                  AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme:                  AppTheme.light,
      initialRoute:           AppRouter.splash,
      routes:                 AppRouter.routes,
    );
  }
}