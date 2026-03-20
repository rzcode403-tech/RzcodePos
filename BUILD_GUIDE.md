# دليل البناء والنشر

## متطلبات البناء 📋

### Android
- Android SDK 28+
- Android Gradle Plugin 8.0+
- Java JDK 11+

### iOS
- macOS 12+
- Xcode 14+
- CocoaPods

### Windows
- Visual Studio 2022+
- C++ Build Tools

## البناء للـ Android APK 🤖

### APK Debug
```bash
flutter build apk --debug
# الملف: build/app/outputs/flutter-apk/app-debug.apk
```

### APK Release
```bash
flutter build apk --release
# الملف: build/app/outputs/flutter-apk/app-release.apk
```

### AAB (Google Play)
```bash
flutter build appbundle --release
# الملف: build/app/outputs/bundle/release/app-release.aab
```

## البناء لـ iOS 🍎

```bash
flutter build ios --release
# فتح في Xcode: open ios/Runner.xcworkspace
```

## البناء لـ Web 🌐

```bash
flutter build web --release
# الملف: build/web/
# رفع المحتوى إلى استضافة الويب
```

## التوقيع والنشر

### التوقيع على Android APK

#### إنشاء مفتاح التوقيع
```bash
keytool -genkey -v -keystore ~/supermarche.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias supermarche
```

#### توقيع APK
```bash
jarsigner -verbose -sigalg SHA256withRSA \
  -digestalg SHA-256 -keystore ~/supermarche.jks \
  build/app/outputs/flutter-apk/app-release-unsigned.apk supermarche
```

#### ضغط وتحسين APK
```bash
zipalign -v 4 app-release-unsigned.apk app-release.apk
```

## نشر على متاجر التطبيقات

### Google Play Store

1. إنشاء حساب المطور
2. تعبئة معلومات التطبيق
3. رفع AAB
4. تعيين الأسعار والدول المستهدفة
5. إرسال للمراجعة

### Apple App Store

1. إعداد شهادات التوقيع
2. بناء الـ IPA
3. تحميل عبر App Store Connect
4. ملء البيانات المطلوبة
5. إرسال للمراجعة

## التحسينات ⚡

### تقليل حجم APK
```bash
# استخدام split APK حسب architecture
flutter build apk --release --split-per-abi

# استخدام ProGuard
flutter build apk --release -v
```

### تحسين الأداء
- تفعيل Release Mode
- استخدام --obfuscate
- تقليل صور المتجر
- استخدام WebP format

## اختبار قبل النشر ✅

```bash
# اختبار الوحدات
flutter test

# اختبار التكامل
flutter test integration_test/

# اختبار الأداء
flutter drive --profile

# التحليل
flutter analyze
```

## الإصدارات

### تحديث رقم الإصدار
عدّل في `pubspec.yaml`:
```yaml
version: 3.0.0+1
```

### التعليمات البرمجية
```
major.minor.patch+build
3.0.0 = الإصدار الرئيسي
+1 = رقم البناء
```

## استكشاف الأخطاء

### التحقق من الحزم
```bash
flutter doctor
flutter doctor -v
```

### مسح الذاكرة
```bash
flutter clean
```

### إعادة البناء
```bash
flutter pub get
flutter pub upgrade
```

## ملفات مهمة

- `android/app/build.gradle.kts` - إعدادات Android
- `android/key.properties` - مفاتيح التوقيع
- `ios/Runner/Info.plist` - إعدادات iOS
- `pubspec.yaml` - معلومات المشروع

---

**تذكر: اختبر تطبيقك على أجهزة حقيقية قبل النشر!**
