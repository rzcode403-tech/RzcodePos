import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════
// COLORS & THEMING
// ═══════════════════════════════════════════════

class AppColors {
  // Primary Colors (Modern Gradient)
  static const Color primary = Color(0xFF1B3A5C);
  static const Color primaryLight = Color(0xFF234D7A);
  static const Color primaryDark = Color(0xFF0F2335);
  
  // Accent & Secondary
  static const Color accent = Color(0xFFE8A020);
  static const Color secondary = Color(0xFF00B4D8);
  
  // Semantic Colors
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFFB923C);
  static const Color info = Color(0xFF3B82F6);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1F2937);
  static const Color grey = Color(0xFF6B7280);
  static const Color greyLight = Color(0xFFF3F4F6);
  static const Color greyDark = Color(0xFF4B5563);
  
  // Additional
  static const List<Color> gradientColors = [primary, primaryLight];
  static const List<Color> categoryColors = [
    Color(0xFFFF6B6B), // Red
    Color(0xFF4ECDC4), // Teal
    Color(0xFFFFE66D), // Yellow
    Color(0xFF95E1D3), // Mint
    Color(0xFFC7CEEA), // Lavender
    Color(0xFFFF8C94), // Coral
    Color(0xFF99E9F2), // Light Blue
    Color(0xFFFFF0B4), // Light Yellow
  ];
}

// ═══════════════════════════════════════════════
// TYPOGRAPHY
// ═══════════════════════════════════════════════

class AppTypography {
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight normal = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extrabold = FontWeight.w800;
  
  // Text Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: bold,
    fontFamily: 'Poppins',
    color: AppColors.black,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 28,
    fontWeight: bold,
    fontFamily: 'Poppins',
    color: AppColors.black,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 24,
    fontWeight: semibold,
    fontFamily: 'Poppins',
    color: AppColors.black,
  );
  
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: semibold,
    fontFamily: 'Poppins',
    color: AppColors.black,
  );
  
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: medium,
    fontFamily: 'Inter',
    color: AppColors.greyDark,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: normal,
    fontFamily: 'Inter',
    color: AppColors.black,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: normal,
    fontFamily: 'Inter',
    color: AppColors.grey,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: light,
    fontFamily: 'Inter',
    color: AppColors.grey,
  );
}

// ═══════════════════════════════════════════════
// SPACING & SIZING
// ═══════════════════════════════════════════════

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppBorderRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
  static const double max = 100;
}

// ═══════════════════════════════════════════════
// PERMISSIONS & ROLES
// ═══════════════════════════════════════════════

class AppRoles {
  static const Map<String, List<String>> permissions = {
    'Admin': [
      'caisse',
      'dashboard',
      'produits',
      'categories',
      'utilisateurs',
      'rapports',
      'logs',
      'parametres',
      'stocks',
      'backup'
    ],
    'Superviseur': [
      'caisse',
      'dashboard',
      'produits',
      'categories',
      'rapports',
      'logs',
      'stocks'
    ],
    'Vendeur': ['caisse'],
  };
}

// ═══════════════════════════════════════════════
// PAYMENT METHODS
// ═══════════════════════════════════════════════

class AppPayment {
  static const List<String> methods = [
    'Espèces',
    'Carte',
    'Chèque',
    'Mobile Pay',
    'Virement',
    'Autre'
  ];
}

// ═══════════════════════════════════════════════
// API ENDPOINTS
// ═══════════════════════════════════════════════

class AppAPI {
  static const String baseURL = 'http://localhost:8000/api';
  // المستخدمين يجب أن يحدثوا هذا إلى الخادم الفعلي
  
  // Auth Endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  
  // Products
  static const String products = '/products';
  static const String categories = '/categories';
  
  // Users
  static const String users = '/users';
  
  // Sales & Orders
  static const String sales = '/sales';
  static const String orders = '/orders';
  
  // Settings
  static const String settings = '/settings';
  
  // Reports
  static const String reports = '/reports';
}

// ═══════════════════════════════════════════════
// TIME FORMATS
// ═══════════════════════════════════════════════

class AppDateFormat {
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm:ss';
  static const String displayFormat = 'dd MMM yyyy';
}

// ═══════════════════════════════════════════════
// ANIMATION DURATIONS
// ═══════════════════════════════════════════════

class AppAnimation {
  static const Duration fastest = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 700);
}

// ═══════════════════════════════════════════════
// VALIDATION & MESSAGES
// ═══════════════════════════════════════════════

class AppMessages {
  static const String loading = 'جاري التحميل...';
  static const String error = 'حدث خطأ';
  static const String success = 'تم بنجاح';
  static const String confirmation = 'هل أنت متأكد؟';
  static const String noConnection = 'لا توجد اتصالية';
  static const String retry = 'حاول مرة أخرى';
  static const String cancel = 'إلغاء';
  static const String confirm = 'تأكيد';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String add = 'إضافة';
  static const String save = 'حفظ';
}

// ═══════════════════════════════════════════════
// REGEX PATTERNS
// ═══════════════════════════════════════════════

class AppValidation {
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^[+]?[0-9]{7,}$';
  static const String pricePattern = r'^\d+(\.\d{1,2})?$';
}
