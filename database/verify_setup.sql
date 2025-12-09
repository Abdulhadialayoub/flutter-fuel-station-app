-- Veritabanı Kurulumunu Doğrulama Scripti
-- Bu scripti Supabase SQL Editor'de çalıştırın

-- ============================================
-- 1. TABLOLARIN VARLIĞINI KONTROL ET
-- ============================================
SELECT 
  'Tablo Kontrolü' AS test_name,
  CASE 
    WHEN COUNT(*) = 4 THEN '✅ Tüm tablolar mevcut'
    ELSE '❌ Bazı tablolar eksik: ' || (4 - COUNT(*))::TEXT || ' tablo bulunamadı'
  END AS result
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('stations', 'fuel_types', 'services', 'reviews');

-- ============================================
-- 2. VERİ SAYILARINI KONTROL ET
-- ============================================
SELECT 'Veri Sayıları' AS test_name, 
       'Stations: ' || (SELECT COUNT(*) FROM stations)::TEXT || 
       ', Fuel Types: ' || (SELECT COUNT(*) FROM fuel_types)::TEXT ||
       ', Services: ' || (SELECT COUNT(*) FROM services)::TEXT ||
       ', Reviews: ' || (SELECT COUNT(*) FROM reviews)::TEXT AS result;

-- ============================================
-- 3. İSTASYONLARI LİSTELE
-- ============================================
SELECT 
  'İstasyon Listesi' AS test_name,
  name AS station_name,
  latitude,
  longitude,
  open_time || ' - ' || close_time AS hours
FROM stations
ORDER BY name;

-- ============================================
-- 4. YAKIT TÜRLERİNİ LİSTELE
-- ============================================
SELECT 
  'Yakıt Türleri' AS test_name,
  name AS fuel_name,
  price,
  currency,
  last_updated
FROM fuel_types
ORDER BY name;

-- ============================================
-- 5. RLS POLİTİKALARINI KONTROL ET
-- ============================================
SELECT 
  'RLS Politikaları' AS test_name,
  tablename,
  policyname,
  cmd AS operation
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================
-- 6. FONKSİYONLARI KONTROL ET
-- ============================================
SELECT 
  'Fonksiyonlar' AS test_name,
  routine_name AS function_name,
  routine_type AS type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('calculate_average_rating', 'update_updated_at_column')
ORDER BY routine_name;

-- ============================================
-- 7. ÖRNEK VERİ SORGUSU (API TEST)
-- ============================================
-- Bu sorgu, uygulamanın kullandığı sorguya benzer
SELECT 
  s.id,
  s.name,
  s.latitude,
  s.longitude,
  s.open_time,
  s.close_time,
  json_agg(
    json_build_object(
      'id', srv.id,
      'name', srv.name,
      'icon', srv.icon
    )
  ) FILTER (WHERE srv.id IS NOT NULL) AS services
FROM stations s
LEFT JOIN services srv ON s.id = srv.station_id
GROUP BY s.id, s.name, s.latitude, s.longitude, s.open_time, s.close_time
ORDER BY s.name
LIMIT 3;

-- ============================================
-- 8. ORTALAMA PUANLARI KONTROL ET
-- ============================================
SELECT 
  s.name AS station_name,
  calculate_average_rating(s.id) AS avg_rating,
  COUNT(r.id) AS review_count
FROM stations s
LEFT JOIN reviews r ON s.id = r.station_id
GROUP BY s.id, s.name
ORDER BY avg_rating DESC NULLS LAST
LIMIT 5;
