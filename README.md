# SuperMarché POS v3.0

نظام نقاط البيع الاحترافي للمتاجر الكبرى

## المميزات الرئيسية ✨

✅ **واجهة احترافية وجميلة**
- تصميم حديث مع Gradient متدرج
- شاشة اقلاع جذابة مع رسوم متحركة
- دعم اللغة العربية الكامل
- ألوان متناسقة مع نظام Material Design 3

✅ **نظام مصادقة متقدم**
- تسجيل دخول/خروج آمن
- حفظ بيانات المستخدم محلياً
- عدم الحاجة للدخول في كل مرة (Session Persistence)
- توكن توثيق آمن

✅ **API Integration**
- تطبيق يعتمد بالكامل على API بدون SQLite
- طلب HTTP محسّن مع معالجة الأخطاء
- دعم جميع العمليات الأساسية

✅ **نظام المنتجات والفئات**
- عرض المنتجات مع صور فعلية (بدل الـ Emoji)
- إدارة الفئات مع صور مخصصة
- نظام Barcode Scanner
- البحث والتصفية المتقدمة

✅ **نظام المبيعات**
- سلة التسوق المتقدمة
- حساب الخصومات والضرائب
- طرق دفع متعددة
- طباعة الفواتير

✅ **الإعدادات والتخصيص**
- تخزين صورة الـ Logo والمتجر
- إعدادات الضرائب والعملة
- معلومات المتجر والاتصال

## المتطلبات 📋

- Flutter 3.3.0 أو أحدث
- Dart 3.3.0 أو أحدث
- Android SDK / iOS SDK
- الاتصال بالإنترنت (للـ API)

## التثبيت والتشغيل 🚀

### 1. استنساخ المشروع
```bash
git clone <repository-url>
cd RzcodePos-enhanced
```

### 2. تثبيت الحزم
```bash
flutter pub get
```

### 3. إعداد API
قم بتحديث `lib/utils/constants.dart`:
```dart
class AppAPI {
  static const String baseURL = 'YOUR_API_URL';
}
```

### 4. تشغيل التطبيق
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d web
```

## هيكل المشروع 📁

```
lib/
├── main.dart                 # نقطة البداية
├── models/
│   └── models.dart          # نماذج البيانات
├── services/
│   └── api_service.dart     # خدمة API
├── providers/
│   └── auth_provider.dart   # مزود المصادقة
├── screens/
│   ├── splash_screen.dart   # شاشة الاقلاع
│   ├── login_screen.dart    # شاشة الدخول
│   └── home_screen.dart     # الشاشة الرئيسية
├── widgets/
│   └── app_button.dart      # المكونات المخصصة
└── utils/
    ├── constants.dart       # الثوابت والألوان
    └── app_extensions.dart  # الامتدادات
```

## الحزم المستخدمة 📦

```yaml
http: ^1.1.0                    # HTTP Requests
provider: ^6.1.2                # State Management
shared_preferences: ^2.2.2      # Local Storage
mobile_scanner: ^5.1.1          # Barcode Scanner
pdf: ^3.10.8                    # PDF Generation
printing: ^5.12.0               # Printing
image_picker: ^1.0.7            # Image Selection
cached_network_image: ^3.3.1    # Image Caching
```

## API المتوقع 🔌

### Authentication
```
POST /api/auth/login
POST /api/auth/logout
```

### Products
```
GET /api/products
GET /api/products/barcode/:barcode
GET /api/categories
```

### Sales
```
POST /api/sales
GET /api/sales
```

### Settings
```
GET /api/settings
PUT /api/settings
```

## الميزات المستقبلية 🔮

- [ ] نظام المستخدمين والصلاحيات
- [ ] التقارير والإحصائيات
- [ ] نظام الأرصدة والمخزون
- [ ] الفواتير المتقدمة
- [ ] نظام العروض والخصومات
- [ ] نظام CRM للعملاء
- [ ] المزامنة المحلية Offline
- [ ] نسخ احتياطية تلقائية

## الدعم والمساعدة 💬

للمساعدة والاستفسارات:
- البريد: support@supermarche.tn
- الهاتف: +216 71 000 000

## الترخيص 📄

جميع الحقوق محفوظة © 2024 SuperMarché POS

---

**تم التطوير باستخدام Flutter 💙**
