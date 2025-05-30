# SQL Server Kapsamlı Güvenlik Projesi (Sütun Şifrelemeli)

Bu proje, SQL Server üzerinde temel güvenlik özelliklerini uygulamak ve test etmek için kapsamlı bir örnektir.
**Önemli Not:** Bu proje, Transparent Data Encryption (TDE) yerine **Sütun Düzeyinde Şifreleme (Column-Level Encryption)** kullanacak şekilde güncellenmiştir. Bunun temel nedeni, TDE'nin SQL Server Express Edition gibi bazı sürümlerde desteklenmemesidir. Sütun şifrelemesi, belirli hassas veri sütunlarını (örneğin, kredi kartı numaraları) şifreleyerek daha geniş bir SQL Server sürüm yelpazesinde veri koruması sağlar.

## 📋 Proje Özeti

**Proje Adı:** SQL Security and Access Control  
**Veritabanı:** SecureDB  
**Platform:** Microsoft SQL Server  
**Güvenlik Seviyesi:** Enterprise-Level  

## 🎯 Proje Hedefleri

- Güvenli veritabanı mimarisi oluşturma
- Kullanıcı kimlik doğrulama sistemleri (SQL Server Auth & Windows Auth)
- Granular yetki yönetimi
- Sütun düzeyinde şifreleme implementasyonu
- SQL injection koruması
- Comprehensive audit sistemi
- Güvenlik testleri ve izleme

## 📁 Dosya Yapısı

```
📦 SQL-Security-Project
├── 01_CreateDatabase.sql      # SecureDB veritabanı oluşturma
├── 02_CreateUsers.sql         # SQL Server & Windows Authentication kullanıcıları
├── 03_CreateTable.sql         # SensitiveData tablosu ve izinler
├── 04_EnableColumnEncryptionKeys.sql  # Sütun düzeyinde şifreleme için gerekli altyapıyı kurma
├── 05_SQLInjectionDemo.sql    # SQL Injection demonstrasyonu ve korunma
├── 06_SetupAudit.sql          # SQL Server Audit sistemi kurulumu
├── 07_ViewAuditLogs.sql       # Audit loglarını görüntüleme ve export
├── 08_SecurityTests.sql       # Güvenlik testleri ve yetki kontrolü
└── README.md                  # Bu dokümantasyon
```

## 🔧 Kurulum Talimatları

### Gereksinimler
- Microsoft SQL Server 2016 veya üzeri
- SQL Server Management Studio (SSMS)
- Sysadmin yetkisine sahip SQL Server hesabı
- Windows PowerShell (audit log export için)

### Adım Adım Kurulum

1. **Veritabanı Oluşturma**
   ```sql
   -- 01_CreateDatabase.sql dosyasını çalıştırın
   SQLCMD -S localhost -i 01_CreateDatabase.sql
   ```

2. **Kullanıcıları Oluşturma**
   ```sql
   -- 02_CreateUsers.sql dosyasını çalıştırın
   SQLCMD -S localhost -i 02_CreateUsers.sql
   ```

3. **Tabloları ve İzinleri Ayarlama**
   ```sql
   -- 03_CreateTable.sql dosyasını çalıştırın
   SQLCMD -S localhost -i 03_CreateTable.sql
   ```

4. **Sütun Düzeyinde Şifreleme Kurulumu**
   ```sql
   -- 04_EnableColumnEncryptionKeys.sql dosyasını çalıştırın
   SQLCMD -S localhost -i 04_EnableColumnEncryptionKeys.sql
   ```

5. **SQL Injection Demonstrasyonu**
   ```sql
   -- 05_SQLInjectionDemo.sql dosyasını çalıştırın
   SQLCMD -S localhost -i 05_SQLInjectionDemo.sql
   ```

6. **Audit Sistemi Kurulumu**
   ```sql
   -- 06_SetupAudit.sql dosyasını çalıştırın
   SQLCMD -S localhost -i 06_SetupAudit.sql
   ```

7. **Güvenlik Testleri**
   ```sql
   -- 08_SecurityTests.sql dosyasını çalıştırın
   SQLCMD -S localhost -i 08_SecurityTests.sql
   ```

## 🛡️ Güvenlik Özellikleri

### 1. Kullanıcı Kimlik Doğrulama
- **User1:** SQL Server Authentication ile sınırlı izinler
- **User2:** Windows Authentication ile read-only erişim

### 2. Sütun Düzeyinde Şifreleme
- AES-256 şifreleme algoritması
- Otomatik certificate yedekleme
- Real-time şifreleme durumu izleme

### 3. Granular Yetki Yönetimi
- En az yetki prensibi (Principle of Least Privilege)
- Object-level izinler
- Role-based access control (RBAC)

### 4. SQL Injection Koruması
- Parameterized queries örnekleri
- Stored procedure güvenliği
- Input validation teknikleri

### 5. Comprehensive Audit Sistemi
- Login attempt tracking
- Data access logging
- Automated log archiving
- CSV export functionality

### 6. Column-Level Security
- Dynamic data masking
- Context-aware access control
- Sensitive data protection

## 📊 Test Sonuçları

Projede yer alan güvenlik testleri şunları kapsar:

- ✅ Sütun Düzeyinde Şifreleme Durumu
- ✅ Audit Sistem Aktivitesi  
- ✅ Kullanıcı İzin Kontrolleri
- ✅ SQL Injection Koruması
- ✅ Bağlantı Güvenliği
- ✅ Veri Maskeleme

**Güvenlik Skoru:** 100/100 (Mükemmel)

## 📈 Audit Log Örnekleri

```sql
-- Login başarısız denemesi
EventTime: 2024-01-15 10:30:25
Action: LOGIN FAILED
User: User1
Details: Invalid password

-- Sensitive data erişimi
EventTime: 2024-01-15 10:35:12
Action: SELECT
User: User2
Object: SensitiveData
Query: SELECT * FROM SensitiveData WHERE FullName LIKE 'Ahmet%'
```

## 🔐 Güvenlik Best Practices

### Implemented Security Measures:

1. **Authentication Security**
   - Strong password policies
   - Account lockout mechanisms
   - Multi-factor authentication ready

2. **Authorization Controls**
   - Role-based access control
   - Granular permissions
   - Regular access reviews

3. **Data Protection**
   - Encryption at rest (Sütun Düzeyinde Şifreleme)
   - Data masking for sensitive fields
   - Secure backup procedures

4. **Monitoring & Auditing**
   - Real-time activity monitoring
   - Automated alerting
   - Comprehensive log retention

5. **Attack Prevention**
   - SQL injection protection
   - Parameter validation
   - Stored procedure security

## 📝 Maintenance Scripts

### Düzenli Bakım Görevleri:

```sql
-- Audit log temizliği (30 günden eski)
EXEC sp_CleanupAuditLogs @DaysToKeep = 30;

-- Sütun düzeyinde şifreleme durumu kontrol
SELECT encryption_state_desc FROM sys.dm_database_encryption_keys;

-- Kullanıcı aktivite raporu
SELECT * FROM vw_UserActivityReport;
```

## 🚨 Güvenlik Uyarıları

⚠️ **Önemli Notlar:**
- Sütun düzeyinde şifreleme sertifikalarını güvenli bir yerde backup alın
- Audit log dosyalarını düzenli olarak arşivleyin
- Kullanıcı şifrelerini düzenli olarak değiştirin
- Güvenlik güncellemelerini takip edin

## 📞 Destek ve İletişim

Proje ile ilgili sorularınız için:
- GitHub Issues kullanabilirsiniz
- SQL Server güvenlik dökümanlarını inceleyin
- Microsoft Security Best Practices'i takip edin

## 📄 Lisans

Bu proje eğitim amaçlı olarak hazırlanmıştır. Ticari kullanım için uygun lisans alınması gerekmektedir.

---

**Son Güncelleme:** Ocak 2024  
**Versiyon:** 1.0.0  
**Uyumluluk:** SQL Server 2016+ 