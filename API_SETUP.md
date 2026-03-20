# إعداد خادم API

## متطلبات الخادم 🖥️

- PHP 8.0+
- MySQL/MariaDB
- Composer
- CORS enabled

## خطوات الإعداد

### 1. تثبيت الحزم
```bash
cd api
composer install
```

### 2. إنشاء قاعدة البيانات
```sql
CREATE DATABASE supermarche_pos;
USE supermarche_pos;
```

### 3. تشغيل الهجرات
```bash
php artisan migrate
php artisan seed:run
```

### 4. بدء الخادم
```bash
php -S localhost:8000
```

## Endpoints المتاحة

### Authentication
- `POST /api/auth/login` - تسجيل الدخول
- `POST /api/auth/logout` - تسجيل الخروج
- `POST /api/auth/register` - إنشاء حساب

### Products
- `GET /api/products` - جلب المنتجات
- `GET /api/products/{id}` - تفاصيل المنتج
- `GET /api/products/barcode/{barcode}` - البحث عن منتج بـ Barcode
- `POST /api/products` - إنشاء منتج
- `PUT /api/products/{id}` - تحديث منتج
- `DELETE /api/products/{id}` - حذف منتج

### Categories
- `GET /api/categories` - جلب الفئات
- `POST /api/categories` - إنشاء فئة
- `PUT /api/categories/{id}` - تحديث فئة
- `DELETE /api/categories/{id}` - حذف فئة

### Sales
- `GET /api/sales` - جلب المبيعات
- `POST /api/sales` - إنشاء مبيعة
- `GET /api/sales/{id}` - تفاصيل المبيعة

### Users
- `GET /api/users` - جلب المستخدمين
- `POST /api/users` - إنشاء مستخدم
- `PUT /api/users/{id}` - تحديث مستخدم
- `DELETE /api/users/{id}` - حذف مستخدم

### Settings
- `GET /api/settings` - جلب الإعدادات
- `PUT /api/settings` - تحديث الإعدادات

## نموذج الاستجابة الناجحة

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Product Name",
    ...
  }
}
```

## نموذج الاستجابة الخاطئة

```json
{
  "success": false,
  "error": "Error message",
  "code": 400
}
```

## أمثلة الطلبات

### تسجيل الدخول
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}'
```

### جلب المنتجات
```bash
curl -X GET http://localhost:8000/api/products \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### إنشاء مبيعة
```bash
curl -X POST http://localhost:8000/api/sales \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [{"product_id": 1, "quantity": 2}],
    "payment_method": "Espèces",
    "total": 100
  }'
```

## معالجة الأخطاء

- `400` - طلب خاطئ
- `401` - غير مصرح
- `403` - محظور
- `404` - غير موجود
- `500` - خطأ في الخادم

