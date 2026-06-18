// Routes akan diimplement berdasarkan navigasi yang dipilih
// Untuk sekarang, gunakan named routes

class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String roleSelection = '/role-selection';
  
  // Autentikasi
  static const String login = '/login';
  static const String register = '/register';
  static const String adminLogin = '/admin-login';
  static const String forgotPassword = '/forgot-password';
  
  // Admin
  static const String adminDashboard = '/admin-dashboard';
  static const String adminMenu = '/admin-menu';
  static const String adminCategory = '/admin-category';
  static const String adminOrders = '/admin-orders';
  static const String adminChat = '/admin-chat';
  static const String adminNotification = '/admin-notification';
  static const String adminStatistics = '/admin-statistics';
  static const String adminProfile = '/admin-profile';
  static const String adminSettings = '/admin-settings';
  
  // User
  static const String userHome = '/user-home';
  static const String userMenuDetail = '/user-menu-detail';
  static const String userCart = '/user-cart';
  static const String userCheckout = '/user-checkout';
  static const String userOrders = '/user-orders';
  static const String userOrderDetail = '/user-order-detail';
  static const String userChat = '/user-chat';
  static const String userNotification = '/user-notification';
  static const String userRecommendation = '/user-recommendation';
  static const String userProfile = '/user-profile';
}
