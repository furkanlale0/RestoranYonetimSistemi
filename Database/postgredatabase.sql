-- ========================================================================
-- 1. YETKİ VE GÜVENLİK SİSTEMİ (ACL)
-- ========================================================================

CREATE TABLE roller (
    id SERIAL PRIMARY KEY,
    rol_adi VARCHAR(50) NOT NULL UNIQUE,
    aciklama VARCHAR(255)
);

CREATE TABLE yetkiler (
    id SERIAL PRIMARY KEY,
    yetki_kodu VARCHAR(100) UNIQUE,
    aciklama VARCHAR(255)
);

CREATE TABLE rol_yetkileri (
    rol_id INT,
    yetki_id INT,
    PRIMARY KEY (rol_id, yetki_id),
    FOREIGN KEY (rol_id) REFERENCES roller(id),
    FOREIGN KEY (yetki_id) REFERENCES yetkiler(id)
);

-- ========================================================================
-- ENUM TANIMLARI (PostgreSQL'de ayrı tanımlanır)
-- ========================================================================

CREATE TYPE talep_turu_enum AS ENUM ('Istifa', 'Izin', 'Avans', 'Sikayet');
CREATE TYPE onay_durumu_enum AS ENUM ('Beklemede', 'Onaylandi', 'Reddedildi');
CREATE TYPE gun_enum AS ENUM ('Pazartesi', 'Sali', 'Carsamba', 'Persembe', 'Cuma', 'Cumartesi', 'Pazar');
CREATE TYPE masa_durum_enum AS ENUM ('Bos', 'Dolu', 'GarsonCagiriyor', 'HesapBekliyor');
CREATE TYPE adisyon_durum_enum AS ENUM ('Acik', 'Odendi', 'Iptal');
CREATE TYPE siparis_durum_enum AS ENUM ('Beklemede', 'Hazirlaniyor', 'Yolda', 'Servis Edildi', 'Iptal');
CREATE TYPE odeme_yontem_enum AS ENUM ('Nakit', 'Kredi Kartı', 'Yemek Çeki', 'Online');

-- ========================================================================
-- 2. PERSONEL
-- ========================================================================

CREATE TABLE personeller (
    id SERIAL PRIMARY KEY,
    rol_id INT,
    kullanici_adi VARCHAR(50) UNIQUE NOT NULL,
    sifre_hash VARCHAR(255) NOT NULL,
    ad VARCHAR(50) NOT NULL,
    soyad VARCHAR(50) NOT NULL,
    tc_no CHAR(11) UNIQUE,
    dogum_tarihi DATE,
    telefon VARCHAR(20),
    e_posta VARCHAR(100),
    adres TEXT,
    memleket VARCHAR(100), 
    kan_grubu VARCHAR(5),
    ise_giris_tarihi DATE NOT NULL, 
    profil_resmi_url VARCHAR(255),
    karanlik_mod_tercihi BOOLEAN DEFAULT FALSE, 
    aktif_mi BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (rol_id) REFERENCES roller(id)
);

CREATE TABLE maas_bilgileri (
    id SERIAL PRIMARY KEY,
    personel_id INT,
    temel_maas DECIMAL(10,2),
    iban VARCHAR(34),
    guncelleme_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (personel_id) REFERENCES personeller(id)
);

CREATE TABLE personel_talepleri (
    id SERIAL PRIMARY KEY,
    personel_id INT,
    talep_turu talep_turu_enum NOT NULL,
    baslik VARCHAR(255),
    icerik TEXT, 
    baslangic_tarihi TIMESTAMP,
    bitis_tarihi TIMESTAMP,
    talep_zamani TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    onay_durumu onay_durumu_enum DEFAULT 'Beklemede',
    yonetici_notu TEXT,
    FOREIGN KEY (personel_id) REFERENCES personeller(id)
);

CREATE TABLE vardiyalar (
    id SERIAL PRIMARY KEY,
    personel_id INT,
    gun gun_enum,
    baslangic_saati TIME,
    bitis_saati TIME,
    FOREIGN KEY (personel_id) REFERENCES personeller(id)
);

CREATE TABLE performans_rozetleri (
    id SERIAL PRIMARY KEY,
    personel_id INT,
    rozet_turu VARCHAR(50),
    kazanma_tarihi DATE,
    FOREIGN KEY (personel_id) REFERENCES personeller(id)
);

-- ========================================================================
-- 3. MENÜ
-- ========================================================================

CREATE TABLE kategoriler (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(100) NOT NULL,
    sira_no INT,
    aktif_mi BOOLEAN DEFAULT TRUE
);

CREATE TABLE urunler (
    id SERIAL PRIMARY KEY,
    kategori_id INT,
    ad VARCHAR(150) NOT NULL, 
    aciklama TEXT,
    fiyat DECIMAL(10,2) NOT NULL, 
    maliyet DECIMAL(10,2),
    kdv_orani INT DEFAULT 10,
    hazirlanma_suresi_dk INT, 
    gorsel_url VARCHAR(255), 
    populer_mi BOOLEAN DEFAULT FALSE, 
    stok_takibi_var_mi BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (kategori_id) REFERENCES kategoriler(id)
);

CREATE TABLE urun_varyasyonlari (
    id SERIAL PRIMARY KEY,
    urun_id INT,
    varyasyon_adi VARCHAR(50),
    ek_fiyat DECIMAL(10,2) DEFAULT 0,
    FOREIGN KEY (urun_id) REFERENCES urunler(id)
);

CREATE TABLE stok_malzemeleri (
    id SERIAL PRIMARY KEY,
    malzeme_adi VARCHAR(100),
    birim VARCHAR(20),
    mevcut_miktar DECIMAL(10,2),
    kritik_seviye DECIMAL(10,2),
    son_guncelleme TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE receteler (
    urun_id INT,
    malzeme_id INT,
    miktar DECIMAL(10,2),
    PRIMARY KEY (urun_id, malzeme_id),
    FOREIGN KEY (urun_id) REFERENCES urunler(id),
    FOREIGN KEY (malzeme_id) REFERENCES stok_malzemeleri(id)
);

-- ========================================================================
-- 4. MASA
-- ========================================================================

CREATE TABLE bolumler (
    id SERIAL PRIMARY KEY,
    bolum_adi VARCHAR(50)
);

CREATE TABLE masalar (
    id SERIAL PRIMARY KEY,
    bolum_id INT,
    masa_no VARCHAR(20) NOT NULL,
    kapasite INT,
    durum masa_durum_enum DEFAULT 'Bos',
    qr_guvenlik_kodu VARCHAR(10),
    FOREIGN KEY (bolum_id) REFERENCES bolumler(id)
);

-- ========================================================================
-- 5. SİPARİŞ
-- ========================================================================

CREATE TABLE adisyonlar (
    id SERIAL PRIMARY KEY,
    masa_id INT,
    garson_id INT,
    acilis_zamani TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    kapanis_zamani TIMESTAMP,
    toplam_tutar DECIMAL(10,2) DEFAULT 0,
    indirim_tutari DECIMAL(10,2) DEFAULT 0,
    durum adisyon_durum_enum DEFAULT 'Acik',
    FOREIGN KEY (masa_id) REFERENCES masalar(id),
    FOREIGN KEY (garson_id) REFERENCES personeller(id)
);

CREATE TABLE siparis_icerik (
    id SERIAL PRIMARY KEY,
    adisyon_id INT,
    urun_id INT,
    adet INT NOT NULL,
    birim_fiyat DECIMAL(10,2),
    siparis_notu TEXT,
    durum siparis_durum_enum DEFAULT 'Beklemede',
    iptal_nedeni TEXT,
    siparis_zamani TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (adisyon_id) REFERENCES adisyonlar(id),
    FOREIGN KEY (urun_id) REFERENCES urunler(id)
);

-- ========================================================================
-- 6. ÖDEME
-- ========================================================================

CREATE TABLE odemeler (
    id SERIAL PRIMARY KEY,
    adisyon_id INT,
    kasiyer_id INT,
    odeme_yontemi odeme_yontem_enum,
    alinan_miktar DECIMAL(10,2),
    para_ustu DECIMAL(10,2),
    islem_zamani TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (adisyon_id) REFERENCES adisyonlar(id),
    FOREIGN KEY (kasiyer_id) REFERENCES personeller(id)
);

-- ========================================================================
-- 7. MÜŞTERİ
-- ========================================================================

CREATE TABLE musteriler (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(50),
    soyad VARCHAR(50),
    telefon VARCHAR(20) UNIQUE,
    toplam_puan INT DEFAULT 0,
    kayit_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE geri_bildirimler (
    id SERIAL PRIMARY KEY,
    adisyon_id INT,
    musteri_id INT,
    puan_servis INT,
    puan_lezzet INT,
    yorum TEXT,
    tarih TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (adisyon_id) REFERENCES adisyonlar(id),
    FOREIGN KEY (musteri_id) REFERENCES musteriler(id)
);

-- ========================================================================
-- 8. LOG
-- ========================================================================

CREATE TABLE islem_loglari (
    id SERIAL PRIMARY KEY,
    personel_id INT,
    islem_turu VARCHAR(50),
    aciklama TEXT,
    tablo_adi VARCHAR(50),
    kayit_id INT,
    ip_adresi VARCHAR(45),
    zaman TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (personel_id) REFERENCES personeller(id)
);