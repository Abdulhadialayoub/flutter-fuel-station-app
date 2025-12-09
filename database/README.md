# Veritabanı Kurulumu

Bu klasör Supabase veritabanı için gerekli SQL scriptlerini içerir.

## Kurulum Adımları

### 1. Supabase Projesine Giriş Yapın

1. [Supabase Dashboard](https://app.supabase.com) adresine gidin
2. Projenizi seçin veya yeni bir proje oluşturun

### 2. SQL Editor'ü Açın

1. Sol menüden **SQL Editor** seçeneğine tıklayın
2. **New Query** butonuna tıklayın

### 3. Veritabanı Şemasını Oluşturun

1. `schema.sql` dosyasının içeriğini kopyalayın
2. SQL Editor'e yapıştırın
3. **Run** butonuna tıklayın (veya Ctrl+Enter)
4. Başarılı mesajını bekleyin

### 4. Örnek Verileri Ekleyin (Opsiyonel)

1. Yeni bir query açın
2. `sample_data.sql` dosyasının içeriğini kopyalayın
3. SQL Editor'e yapıştırın
4. **Run** butonuna tıklayın
5. Başarılı mesajını bekleyin

## Oluşturulan Tablolar

### `stations` - Yakıt İstasyonları
- `id`: UUID (Primary Key)
- `name`: İstasyon adı
- `latitude`: Enlem
- `longitude`: Boylam
- `open_time`: Açılış saati
- `close_time`: Kapanış saati
- `created_at`: Oluşturulma zamanı
- `updated_at`: Güncellenme zamanı

### `fuel_types` - Yakıt Türleri
- `id`: UUID (Primary Key)
- `name`: Yakıt adı (benzin, dizel, vb.)
- `price`: Fiyat
- `currency`: Para birimi (SYP, USD, vb.)
- `last_updated`: Son güncelleme zamanı
- `created_at`: Oluşturulma zamanı

### `services` - İstasyon Hizmetleri
- `id`: UUID (Primary Key)
- `station_id`: İstasyon referansı (Foreign Key)
- `name`: Hizmet adı (araba yıkama, market, vb.)
- `icon`: İkon adı
- `created_at`: Oluşturulma zamanı

### `reviews` - Kullanıcı Yorumları
- `id`: UUID (Primary Key)
- `station_id`: İstasyon referansı (Foreign Key)
- `user_id`: Kullanıcı ID'si
- `rating`: Puan (1-5)
- `comment`: Yorum metni
- `created_at`: Oluşturulma zamanı

## Güvenlik (Row Level Security)

Tüm tablolar için RLS (Row Level Security) etkinleştirilmiştir:

- **Okuma**: Herkes okuyabilir (public read)
- **Yazma**: Sadece authenticated kullanıcılar yazabilir
- **Reviews**: Herkes yorum ekleyebilir, sadece kendi yorumlarını düzenleyebilir

## Fonksiyonlar

### `calculate_average_rating(station_uuid UUID)`
Bir istasyonun ortalama puanını hesaplar.

**Kullanım:**
```sql
SELECT calculate_average_rating('station-uuid-here');
```

## API Kullanımı

Supabase client ile kullanım örnekleri:

### İstasyonları Getir
```dart
final response = await supabase
  .from('stations')
  .select('*, services(*)')
  .order('name');
```

### Yakıt Fiyatlarını Getir
```dart
final response = await supabase
  .from('fuel_types')
  .select()
  .order('name');
```

### Yorum Ekle
```dart
await supabase.from('reviews').insert({
  'station_id': stationId,
  'user_id': userId,
  'rating': 5,
  'comment': 'Harika bir istasyon!',
});
```

### İstasyon Yorumlarını Getir
```dart
final response = await supabase
  .from('reviews')
  .select()
  .eq('station_id', stationId)
  .order('created_at', ascending: false);
```

## Sorun Giderme

### Hata: "permission denied for table"
- RLS politikalarının doğru ayarlandığından emin olun
- Supabase anon key'in doğru olduğunu kontrol edin

### Hata: "relation does not exist"
- `schema.sql` scriptinin başarıyla çalıştırıldığından emin olun
- Tablo isimlerinin doğru yazıldığını kontrol edin

### Örnek Veriler Görünmüyor
- `sample_data.sql` scriptini çalıştırdığınızdan emin olun
- SQL Editor'de hata mesajı olup olmadığını kontrol edin

## Veri Yedekleme

Supabase Dashboard'dan:
1. **Database** > **Backups** bölümüne gidin
2. Otomatik yedekleme ayarlarını yapılandırın
3. Manuel yedekleme için **Create Backup** butonunu kullanın

## Veri Silme

Tüm verileri silmek için:
```sql
TRUNCATE TABLE reviews, services, fuel_types, stations CASCADE;
```

⚠️ **Dikkat**: Bu işlem geri alınamaz!
