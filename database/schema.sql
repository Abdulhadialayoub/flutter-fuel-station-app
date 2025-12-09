-- Fuel Station App Database Schema
-- Run this script in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- STATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS stations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  open_time TIME NOT NULL,
  close_time TIME NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add index for location queries
CREATE INDEX IF NOT EXISTS idx_stations_location ON stations(latitude, longitude);

-- Add index for name search
CREATE INDEX IF NOT EXISTS idx_stations_name ON stations(name);

-- ============================================
-- FUEL TYPES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS fuel_types (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
  currency TEXT NOT NULL DEFAULT 'SYP',
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add index for name
CREATE INDEX IF NOT EXISTS idx_fuel_types_name ON fuel_types(name);

-- ============================================
-- SERVICES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS services (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  station_id UUID NOT NULL REFERENCES stations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add index for station_id
CREATE INDEX IF NOT EXISTS idx_services_station_id ON services(station_id);

-- Add index for service name search
CREATE INDEX IF NOT EXISTS idx_services_name ON services(name);

-- ============================================
-- REVIEWS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  station_id UUID NOT NULL REFERENCES stations(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add index for station_id
CREATE INDEX IF NOT EXISTS idx_reviews_station_id ON reviews(station_id);

-- Add index for user_id
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for stations table
DROP TRIGGER IF EXISTS update_stations_updated_at ON stations;
CREATE TRIGGER update_stations_updated_at
  BEFORE UPDATE ON stations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate average rating for a station
CREATE OR REPLACE FUNCTION calculate_average_rating(station_uuid UUID)
RETURNS DECIMAL AS $$
DECLARE
  avg_rating DECIMAL;
BEGIN
  SELECT AVG(rating)::DECIMAL(3,2) INTO avg_rating
  FROM reviews
  WHERE station_id = station_uuid;
  
  RETURN COALESCE(avg_rating, 0);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE fuel_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Policies for stations (public read, authenticated write)
CREATE POLICY "Allow public read access to stations"
  ON stations FOR SELECT
  USING (true);

CREATE POLICY "Allow authenticated insert to stations"
  ON stations FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated update to stations"
  ON stations FOR UPDATE
  USING (auth.role() = 'authenticated');

-- Policies for fuel_types (public read, authenticated write)
CREATE POLICY "Allow public read access to fuel_types"
  ON fuel_types FOR SELECT
  USING (true);

CREATE POLICY "Allow authenticated insert to fuel_types"
  ON fuel_types FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated update to fuel_types"
  ON fuel_types FOR UPDATE
  USING (auth.role() = 'authenticated');

-- Policies for services (public read, authenticated write)
CREATE POLICY "Allow public read access to services"
  ON services FOR SELECT
  USING (true);

CREATE POLICY "Allow authenticated insert to services"
  ON services FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated update to services"
  ON services FOR UPDATE
  USING (auth.role() = 'authenticated');

-- Policies for reviews (public read, anyone can insert)
CREATE POLICY "Allow public read access to reviews"
  ON reviews FOR SELECT
  USING (true);

CREATE POLICY "Allow anyone to insert reviews"
  ON reviews FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Allow users to update their own reviews"
  ON reviews FOR UPDATE
  USING (user_id = auth.uid()::text);

CREATE POLICY "Allow users to delete their own reviews"
  ON reviews FOR DELETE
  USING (user_id = auth.uid()::text);

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE stations IS 'Fuel stations with location and operating hours';
COMMENT ON TABLE fuel_types IS 'Types of fuel with current prices';
COMMENT ON TABLE services IS 'Services offered by each station';
COMMENT ON TABLE reviews IS 'User reviews and ratings for stations';

COMMENT ON FUNCTION calculate_average_rating IS 'Calculate average rating for a station';
