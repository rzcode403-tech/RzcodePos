# دليل التثبيت المفصل

## المتطلبات الأساسية 📋

### 1. تثبيت Flutter
```bash
# تحميل Flutter من
https://flutter.dev/docs/get-started/install

# التحقق من التثبيت
flutter --version
flutter doctor
```

### 2. تثبيت المتطلبات الإضافية

#### على Android
```bash
# تثبيت Android Studio
# تثبيت Android SDK 28+
# تثبيت Java JDK 11+
```

#### على iOS (Mac فقط)
```bash
# تثبيت Xcode
xcode-select --install

# تثبيت CocoaPods
sudo gem install cocoapods
```

## خطوات التثبيت الكاملة 🚀

### 1. استنساخ المشروع
```bash
git clone https://github.com/rzcode/supermarche-pos.git
cd RzcodePos-enhanced
```

### 2. تثبيت الحزم
```bash
# تحديث Flutter
flutter upgrade

# جلب الحزم
flutter pub get

# تحديث الحزم
flutter pub upgrade
```

### 3. إعداد الملفات المطلوبة
```bash
# إنشاء الملفات المولدة
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. التحقق من الإعداد
```bash
flutter doctor -v
```

## تشغيل التطبيق 🎯

### على محاكي/جهاز Android
```bash
# قائمة الأجهزة المتاحة
flutter devices

# تشغيل التطبيق
flutter run

# تشغيل مع verbose
flutter run -v

# بناء وتشغيل Release
flutter run --release
```

### على محاكي/جهاز iOS
```bash
# على iOS (Mac فقط)
flutter run -d ios

# أو استخدام Xcode مباشرة
open ios/Runner.xcworkspace
```

### على محاكي الويب
```bash
flutter run -d web

# بناء الويب
flutter build web --release
```

## إعدادات API 🔌

### تحديث عنوان الخادم
قم بتعديل `lib/utils/constants.dart`:

```dart
class AppAPI {
  static const String baseURL = 'http://your-api-url/api';
}
```

### أمثلة على الـ URLs
- Development: `http://localhost:8000/api`
- Staging: `https://staging.api.com/api`
- Production: `https://api.production.com/api`

## حل المشاكل الشائعة 🔧

### خطأ: "Flutter not found"
```bash
# تأكد من إضافة Flutter إلى PATH
export PATH="$PATH:/path/to/flutter/bin"
```

### خطأ: "Doctor reports issues"
```bash
flutter doctor --android-licenses
flutter config --enable-web
```

### مشكلة في الحزم
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### مشكلة في Gradle
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter run
```

### مشكلة في CocoaPods (iOS)
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
```

## تكوينات إضافية

### تغيير حجم الخط الافتراضي
في `lib/main.dart`:
```dart
MaterialApp(
  builder: (context, child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: 1.0,
      ),
      child: child!,
    );
  },
)
```

### تفعيل الوضع الليلي
سيتم إضافته في الإصدارات القادمة.

### تكوين اللغة
التطبيق يدعم العربية افتراضياً.
لإضافة لغات أخرى:
```dart
const Locale('en', 'US') // الإنجليزية
const Locale('fr', 'FR') // الفرنسية
```

## اختبار التطبيق ✅

### تشغيل الاختبارات
```bash
# اختبارات الوحدات
flutter test

# اختبارات التكامل
flutter test integration_test/

# مع التغطية
flutter test --coverage
```

### اختبار الأداء
```bash
flutter run --profile
```

## بناء الإصدار النهائي 📦

### لـ Android
```bash
flutter build apk --release
# أو AAB للـ Play Store
flutter build appbundle --release
```

### لـ iOS
```bash
flutter build ios --release
```

### للويب
```bash
flutter build web --release
```

## الدعم الإضافي 💬

للمساعدة والاستفسارات:
- البريد: support@supermarche.tn
- الموقع: https://www.supermarche-pos.tn
- GitHub Issues: https://github.com/rzcode/pos/issues

---

**تم بنجاح! 🎉**
