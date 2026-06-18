import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/autentikasi/presentation/pages/admin_login_page.dart';
import 'features/autentikasi/presentation/pages/auth_page.dart';
import 'features/autentikasi/presentation/pages/forgot_password_page.dart';
import 'features/autentikasi/presentation/pages/role_selection_page.dart';
import 'features/autentikasi/presentation/pages/user_login_page.dart';
import 'features/autentikasi/presentation/pages/user_register_page.dart';
import 'features/admin/presentation/pages/admin_dashboard_page.dart';
import 'features/admin/presentation/pages/admin_menu_page.dart';
import 'features/admin/presentation/pages/admin_orders_page.dart';
import 'features/admin/presentation/pages/admin_chat_page.dart';
import 'features/admin/presentation/pages/admin_category_page.dart';
import 'features/admin/presentation/pages/admin_settings_page.dart';
import 'features/admin/presentation/pages/admin_profile_page.dart';
import 'features/admin/presentation/pages/admin_statistics_page.dart';
import 'features/admin/presentation/pages/admin_notification_page.dart';
import 'features/user/presentation/pages/user_home_page.dart';
import 'features/user/presentation/pages/user_menu_detail_page.dart';
import 'features/user/presentation/pages/user_cart_page.dart';
import 'features/user/presentation/pages/user_checkout_page.dart';
import 'features/user/presentation/pages/user_orders_page.dart';
import 'features/user/presentation/pages/user_chat_page.dart';
import 'features/user/presentation/pages/user_profile_page.dart';
import 'features/user/presentation/pages/user_notification_page.dart';
import 'features/user/presentation/pages/user_recommendation_page.dart';
import 'features/shared/presentation/pages/coming_soon_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Register FCM background handler (must be top-level function)
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('FCM background handler registration error: $e');
  }

  // Initialize notification channels & FCM listeners in the background (non-blocking)
  NotificationService().initialize().catchError((e) {
    debugPrint('Error initializing NotificationService: $e');
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const SmartCanteenApp(),
    ),
  );
}

class SmartCanteenApp extends StatelessWidget {
  const SmartCanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartCanteen',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
      routes: {
        AppRoutes.auth: (_) => const AuthPage(),
        AppRoutes.roleSelection: (_) => const RoleSelectionPage(),
        AppRoutes.login: (_) => const UserLoginPage(),
        AppRoutes.register: (_) => const UserRegisterPage(),
        AppRoutes.adminLogin: (_) => const AdminLoginPage(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordPage(),
        AppRoutes.adminDashboard: (_) => const AdminDashboardPage(),
        AppRoutes.adminMenu: (_) => const AdminMenuPage(),
        AppRoutes.adminOrders: (_) => const AdminOrdersPage(),
        AppRoutes.adminCategory: (_) => const AdminCategoryPage(),
        AppRoutes.adminChat: (_) => const AdminChatPage(),
        AppRoutes.adminNotification: (_) => const AdminNotificationPage(),
        AppRoutes.adminStatistics: (_) => const AdminStatisticsPage(),
        AppRoutes.adminProfile: (_) => const AdminProfilePage(),
        AppRoutes.adminSettings: (_) => const AdminSettingsPage(),
        AppRoutes.userHome: (_) => const UserHomePage(),
        AppRoutes.userMenuDetail: (_) => const UserMenuDetailPage(),
        AppRoutes.userCart: (_) => const UserCartPage(),
        AppRoutes.userCheckout: (_) => const UserCheckoutPage(),
        AppRoutes.userOrders: (_) => const UserOrdersPage(),
        AppRoutes.userOrderDetail: (_) =>
            const ComingSoonPage(title: 'Detail Pesanan'),
        AppRoutes.userChat: (_) => const UserChatPage(),
        // ✅ Real notification page
        AppRoutes.userNotification: (_) => const UserNotificationPage(),
        AppRoutes.userRecommendation: (_) => const UserRecommendationPage(),
        AppRoutes.userProfile: (_) => const UserProfilePage(),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => ComingSoonPage(
          title: 'Rute tidak dikenal',
          message: 'Halaman "${settings.name}" belum tersedia.',
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ── Splash Screen ─────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final authService = context.read<AuthService>();

    while (!authService.isInitialized && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Save FCM token after we know the userId
    if (authService.isAuthenticated && authService.userId != null) {
      await NotificationService().saveTokenForUser(authService.userId!);
    }

    final routeName = authService.isAuthenticated
        ? authService.userRole == 'admin'
            ? AppRoutes.adminDashboard
            : AppRoutes.userHome
        : AppRoutes.auth;

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu, size: 80, color: Colors.white),
              SizedBox(height: 20),
              Text(
                'SmartCanteen',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              SizedBox(height: 10),
              Text(
                'Smart Food Ordering & Recommendation System',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 50),
              CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
