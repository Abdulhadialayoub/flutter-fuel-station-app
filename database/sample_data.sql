-- Sample Data for Fuel Station App
-- Run this AFTER running schema.sql

-- ============================================
-- SAMPLE FUEL TYPES
-- ============================================
INSERT INTO fuel_types (name, price, currency) VALUES
  ('بنزين 95', 8500.00, 'SYP'),
  ('بنزين 98', 9000.00, 'SYP'),
  ('ديزل', 7500.00, 'SYP'),
  ('غاز', 6000.00, 'SYP')
ON CONFLICT (name) DO UPDATE 
  SET price = EXCLUDED.price, 
      last_updated = NOW();

-- ============================================
-- SAMPLE STATIONS (Damascus, Syria)
-- ============================================

-- Station 1: محطة الشام
INSERT INTO stations (name, latitude, longitude, open_time, close_time) 
VALUES (
  'محطة الشام',
  33.5138,
  36.2765,
  '06:00:00',
  '22:00:00'
) RETURNING id AS station_1_id;

-- Station 2: محطة دمشق المركزية
INSERT INTO stations (name, latitude, longitude, open_time, close_time) 
VALUES (
  'محطة دمشق المركزية',
  33.5102,
  36.2913,
  '00:00:00',
  '23:59:59'
) RETURNING id AS station_2_id;

-- Station 3: محطة المزة
INSERT INTO stations (name, latitude, longitude, open_time, close_time) 
VALUES (
  'محطة المزة',
  33.4953,
  36.2615,
  '07:00:00',
  '21:00:00'
) RETURNING id AS station_3_id;

-- Station 4: محطة القدم
INSERT INTO stations (name, latitude, longitude, open_time, close_time) 
VALUES (
  'محطة القدم',
  33.4856,
  36.2892,
  '06:30:00',
  '22:30:00'
) RETURNING id AS station_4_id;

-- Station 5: محطة المالكي
INSERT INTO stations (name, latitude, longitude, open_time, close_time) 
VALUES (
  'محطة المالكي',
  33.5025,
  36.2845,
  '08:00:00',
  '20:00:00'
) RETURNING id AS station_5_id;

-- Station 6: محطة الميدان
INSERT INTO stations (name, latitude, longitude, open_time, close_time) 
VALUES (
  'محطة الميدان',
  33.5012,
  36.3125,
  '06:00:00',
  '23:00:00'
) RETURNING id AS station_6_id;

-- Station 7: محطة كفرسوسة
INSERT INTO stations (name, latitude, longitude, open_time, close_time) 
VALUES (
  'محطة كفرسوسة',
  33.4892,
  36.2456,
  '07:00:00',
  '21:00:00'
) RETURNING id AS station_7_id;

-- Station 8: محطة المهاجرين
INSERT INTO stations (name, latitude, longitude, open_time, close_time) 
VALUES (
  'محطة المهاجرين',
  33.5234,
  36.2987,
  '00:00:00',
  '23:59:59'
) RETURNING id AS station_8_id;

-- ============================================
-- SAMPLE SERVICES
-- ============================================

-- Get station IDs (you'll need to replace these with actual IDs from your database)
-- Or use a script to fetch and insert

-- For demonstration, we'll use a DO block to add services to all stations
DO $$
DECLARE
  station_record RECORD;
BEGIN
  FOR station_record IN SELECT id FROM stations LOOP
    -- Add random services to each station
    INSERT INTO services (station_id, name, icon) VALUES
      (station_record.id, 'غسيل سيارات', 'car_wash'),
      (station_record.id, 'متجر', 'store'),
      (station_record.id, 'مرحاض', 'restroom');
    
    -- Add tire service to some stations (50% chance)
    IF random() > 0.5 THEN
      INSERT INTO services (station_id, name, icon) VALUES
        (station_record.id, 'خدمة إطارات', 'tire');
    END IF;
    
    -- Add cafe to some stations (30% chance)
    IF random() > 0.7 THEN
      INSERT INTO services (station_id, name, icon) VALUES
        (station_record.id, 'كافيه', 'cafe');
    END IF;
    
    -- Add ATM to some stations (40% chance)
    IF random() > 0.6 THEN
      INSERT INTO services (station_id, name, icon) VALUES
        (station_record.id, 'صراف آلي', 'atm');
    END IF;
  END LOOP;
END $$;

-- ============================================
-- SAMPLE REVIEWS
-- ============================================

-- Add sample reviews to stations
DO $$
DECLARE
  station_record RECORD;
  review_count INTEGER;
BEGIN
  FOR station_record IN SELECT id FROM stations LOOP
    -- Add 2-5 reviews per station
    review_count := floor(random() * 4 + 2)::INTEGER;
    
    FOR i IN 1..review_count LOOP
      INSERT INTO reviews (station_id, user_id, rating, comment) VALUES
        (
          station_record.id,
          'user_' || floor(random() * 100)::TEXT,
          floor(random() * 3 + 3)::INTEGER, -- Rating between 3-5
          CASE floor(random() * 5)::INTEGER
            WHEN 0 THEN 'خدمة ممتازة وسريعة'
            WHEN 1 THEN 'محطة نظيفة ومنظمة'
            WHEN 2 THEN 'أسعار جيدة وموظفين محترمين'
            WHEN 3 THEN 'موقع مناسب وسهل الوصول'
            ELSE 'تجربة جيدة بشكل عام'
          END
        );
    END LOOP;
  END LOOP;
END $$;

-- ============================================
-- VERIFY DATA
-- ============================================

-- Check inserted data
SELECT 'Stations' AS table_name, COUNT(*) AS count FROM stations
UNION ALL
SELECT 'Fuel Types', COUNT(*) FROM fuel_types
UNION ALL
SELECT 'Services', COUNT(*) FROM services
UNION ALL
SELECT 'Reviews', COUNT(*) FROM reviews;

-- Show stations with their average ratings
SELECT 
  s.name,
  s.latitude,
  s.longitude,
  calculate_average_rating(s.id) AS avg_rating,
  COUNT(r.id) AS review_count
FROM stations s
LEFT JOIN reviews r ON s.id = r.station_id
GROUP BY s.id, s.name, s.latitude, s.longitude
ORDER BY s.name;
