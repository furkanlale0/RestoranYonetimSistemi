
-- 0. VERİTABANINI OLUŞTUR VE SEÇ
CREATE DATABASE IF NOT EXISTS restdatabase;
USE restdatabase;
-- ========================================================================
-- 1. YETKİ VE GÜVENLİK SİSTEMİ (ACL)
-- ========================================================================

CREATE TABLE roller (
    id INT PRIMARY KEY AUTO_INCREMENT,
    rol_adi VARCHAR(50) NOT NULL UNIQUE, -- Admin, Garson, Kasiyer, Vale vb.
    aciklama VARCHAR(255)
);

CREATE TABLE yetkiler (
    id INT PRIMARY KEY AUTO_INCREMENT,
    yetki_kodu VARCHAR(100) UNIQUE, -- 'MASA_SIL', 'ODEME_IPTAL' vb.
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
-- 2. PERSONEL VE İNSAN KAYNAKLARI (DETAYLI)
-- ========================================================================

CREATE TABLE personeller (
    id INT PRIMARY KEY AUTO_INCREMENT,
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
    id INT PRIMARY KEY AUTO_INCREMENT,
    personel_id INT,
    temel_maas DECIMAL(10,2),
    iban VARCHAR(34),
    guncelleme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (personel_id) REFERENCES personeller(id)
);

CREATE TABLE personel_talepleri (
    id INT PRIMARY KEY AUTO_INCREMENT,
    personel_id INT,
    talep_turu ENUM('Istifa', 'Izin', 'Avans', 'Sikayet') NOT NULL, 
    baslik VARCHAR(255),
    icerik TEXT, 
    baslangic_tarihi DATETIME,
    bitis_tarihi DATETIME,
    talep_zamani DATETIME DEFAULT CURRENT_TIMESTAMP,
    onay_durumu ENUM('Beklemede', 'Onaylandi', 'Reddedildi') DEFAULT 'Beklemede', 
    yonetici_notu TEXT,
    FOREIGN KEY (personel_id) REFERENCES personeller(id)
);

CREATE TABLE vardiyalar (
    id INT PRIMARY KEY AUTO_INCREMENT,
    personel_id INT,
    gun ENUM('Pazartesi', 'Sali', 'Carsamba', 'Persembe', 'Cuma', 'Cumartesi', 'Pazar'), 
    baslangic_saati TIME,
    bitis_saati TIME,
    FOREIGN KEY (personel_id) REFERENCES personeller(id)
);

CREATE TABLE performans_rozetleri (
    id INT PRIMARY KEY AUTO_INCREMENT,
    personel_id INT,
    rozet_turu VARCHAR(50), -- 'Ayın Elemanı', 'En Hızlı', 'Müşteri Favorisi' [cite: 35]
    kazanma_tarihi DATE,
    FOREIGN KEY (personel_id) REFERENCES personeller(id)
);

-- ========================================================================
-- 3. MENÜ, STOK VE TEDARİKÇİ YÖNETİMİ
-- ========================================================================

CREATE TABLE kategoriler (
    id INT PRIMARY KEY AUTO_INCREMENT,
    ad VARCHAR(100) NOT NULL,
    sira_no INT,
    aktif_mi BOOLEAN DEFAULT TRUE
);

CREATE TABLE urunler (
    id INT PRIMARY KEY AUTO_INCREMENT,
    kategori_id INT,
    ad VARCHAR(150) NOT NULL, 
    aciklama TEXT,
    fiyat DECIMAL(10,2) NOT NULL, 
    maliyet DECIMAL(10,2), -- Kar analizi için 
    kdv_orani INT DEFAULT 10,
    hazirlanma_suresi_dk INT, 
    gorsel_url VARCHAR(255), 
    populer_mi BOOLEAN DEFAULT FALSE, 
    stok_takibi_var_mi BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (kategori_id) REFERENCES kategoriler(id)
);

CREATE TABLE urun_varyasyonlari (
    id INT PRIMARY KEY AUTO_INCREMENT,
    urun_id INT,
    varyasyon_adi VARCHAR(50), -- 'Küçük Boy', '1.5 Porsiyon'
    ek_fiyat DECIMAL(10,2) DEFAULT 0,
    FOREIGN KEY (urun_id) REFERENCES urunler(id)
);

CREATE TABLE stok_malzemeleri (
    id INT PRIMARY KEY AUTO_INCREMENT,
    malzeme_adi VARCHAR(100),
    birim VARCHAR(20), -- 'KG', 'Litre', 'Adet'
    mevcut_miktar DECIMAL(10,2),
    kritik_seviye DECIMAL(10,2), -- Stok uyarısı için 
    son_guncelleme DATETIME DEFAULT CURRENT_TIMESTAMP
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
-- 4. MASA VE QR SİSTEMİ
-- ========================================================================

CREATE TABLE bolumler (
    id INT PRIMARY KEY AUTO_INCREMENT,
    bolum_adi VARCHAR(50) -- 'Bahçe', 'VIP Salon', 'Teras'
);

CREATE TABLE masalar (
    id INT PRIMARY KEY AUTO_INCREMENT,
    bolum_id INT,
    masa_no VARCHAR(20) NOT NULL, 
    kapasite INT,
    durum ENUM('Bos', 'Dolu', 'GarsonCagiriyor', 'HesapBekliyor') DEFAULT 'Bos', 
    qr_guvenlik_kodu VARCHAR(10), 
    FOREIGN KEY (bolum_id) REFERENCES bolumler(id)
);

-- ========================================================================
-- 5. SİPARİŞ VE ADİSYON SİSTEMİ
-- ========================================================================

CREATE TABLE adisyonlar (
    id INT PRIMARY KEY AUTO_INCREMENT,
    masa_id INT,
    garson_id INT, -- Masayı açan garson [cite: 25]
    acilis_zamani DATETIME DEFAULT CURRENT_TIMESTAMP,
    kapanis_zamani DATETIME,
    toplam_tutar DECIMAL(10,2) DEFAULT 0, 
    indirim_tutari DECIMAL(10,2) DEFAULT 0, 
    durum ENUM('Acik', 'Odendi', 'Iptal') DEFAULT 'Acik',
    FOREIGN KEY (masa_id) REFERENCES masalar(id),
    FOREIGN KEY (garson_id) REFERENCES personeller(id)
);

CREATE TABLE siparis_icerik (
    id INT PRIMARY KEY AUTO_INCREMENT,
    adisyon_id INT,
    urun_id INT,
    adet INT NOT NULL, 
    birim_fiyat DECIMAL(10,2), -- Satış anındaki fiyatı dondurmak için
    siparis_notu TEXT,
    durum ENUM('Beklemede', 'Hazirlaniyor', 'Yolda', 'Servis Edildi', 'Iptal') DEFAULT 'Beklemede', 
    iptal_nedeni TEXT,
    siparis_zamani DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (adisyon_id) REFERENCES adisyonlar(id),
    FOREIGN KEY (urun_id) REFERENCES urunler(id)
);

-- ========================================================================
-- 6. ÖDEME VE FİNANSAL KAYITLAR
-- ========================================================================

CREATE TABLE odemeler (
    id INT PRIMARY KEY AUTO_INCREMENT,
    adisyon_id INT,
    kasiyer_id INT,
    odeme_yontemi ENUM('Nakit', 'Kredi Kartı', 'Yemek Çeki', 'Online'), 
    alinan_miktar DECIMAL(10,2),
    para_ustu DECIMAL(10,2), 
    islem_zamani DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (adisyon_id) REFERENCES adisyonlar(id),
    FOREIGN KEY (kasiyer_id) REFERENCES personeller(id)
);

-- ========================================================================
-- 7. MÜŞTERİ SADAKAT VE GERİ BİLDİRİM
-- ========================================================================

CREATE TABLE musteriler (
    id INT PRIMARY KEY AUTO_INCREMENT,
    ad VARCHAR(50),
    soyad VARCHAR(50),
    telefon VARCHAR(20) UNIQUE,
    toplam_puan INT DEFAULT 0, -- Sadakat sistemi için
    kayit_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE geri_bildirimler (
    id INT PRIMARY KEY AUTO_INCREMENT,
    adisyon_id INT,
    musteri_id INT,
    puan_servis INT, -- 1-5 arası
    puan_lezzet INT,
    yorum TEXT, 
    tarih DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (adisyon_id) REFERENCES adisyonlar(id),
    FOREIGN KEY (musteri_id) REFERENCES musteriler(id)
);

-- ========================================================================
-- 8. DENETİM VE SİSTEM LOGLARI
-- ========================================================================

CREATE TABLE islem_loglari (
    id INT PRIMARY KEY AUTO_INCREMENT,
    personel_id INT,
    islem_turu VARCHAR(50), -- 'URUN_SILME', 'SIFRE_DEGISIM', 'ADMIN_GIRIS' 
    aciklama TEXT, 
    tablo_adi VARCHAR(50),
    kayit_id INT,
    ip_adresi VARCHAR(45),
    zaman DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (personel_id) REFERENCES personeller(id)
);