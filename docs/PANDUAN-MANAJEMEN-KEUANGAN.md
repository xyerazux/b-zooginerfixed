# Panduan Manajemen Keuangan & Akuntansi B-Zooginer
### Sistem Pengelolaan Keuangan, Kas Terverifikasi, Monitoring Pesanan, dan Rekonsiliasi

Dokumen ini merupakan panduan resmi penggunaan sistem Manajemen Keuangan & Akuntansi serta Pusat Monitoring untuk aplikasi **B-Zooginer** (Zoo Market 2026).

---

## DAFTAR ISI

1. [A. Gambaran Umum & Prinsip Akuntansi](#a-gambaran-umum--prinsip-akuntansi)
2. [B. Rumus Keuangan & Perbedaan Kas Riil vs Omzet vs Modal](#b-rumus-keuangan--perbedaan-kas-riil-vs-omzet-vs-modal)
3. [C. Alur Operasional Manajemen Keuangan](#c-alur-operasional-manajemen-keuangan)
   - [1. Pengaturan HPP (Harga Pokok Penjualan) Produk](#1-pengaturan-hpp-harga-pokok-penjualan-produk)
   - [2. Kas Masuk Pembayaran PO (Lunas, DP, Pelunasan)](#2-kas-masuk-pembayaran-po-lunas-dp-pelunasan)
   - [3. Pendapatan Penjualan Manual (Luar Sistem PO)](#3-pendapatan-penjualan-manual-luar-sistem-po)
   - [4. Pencatatan Beban / Pengeluaran Operasional](#4-pencatatan-beban--pengeluaran-operasional)
   - [5. Setoran Modal Mandiri Kelompok](#5-setoran-modal-mandiri-kelompok)
4. [D. Audit & Rekonsiliasi Kas Historis (102 Pesanan Phase 1–4)](#d-audit--rekonsiliasi-kas-historis-102-pesanan-phase-14)
5. [E. Fitur Pusat Monitoring Kelengkapan & Pembayaran](#e-fitur-pusat-monitoring-kelengkapan--pembayaran)
6. [F. Fitur Minimalkan Panel (Hide/Show Monitoring & Keuangan)](#f-fitur-minimalkan-panel-hideshow-monitoring--keuangan)
7. [G. Pembagian Peran & Hak Akses (Superadmin vs Admin Kelompok)](#g-pembagian-peran--hak-akses-superadmin-vs-admin-kelompok)
8. [H. Panduan Ekspor & Cetak Laporan (Laba Rugi & Arus Kas)](#h-panduan-ekspor--cetak-laporan-laba-rugi--arus-kas)
9. [I. Tips Operasional & Troubleshooting](#i-tips-operasional--troubleshooting)

---

## A. GAMBARAN UMUM & PRINSIP AKUNTANSI

Aplikasi B-Zooginer dikembangkan untuk mendukung kegiatan bazar/pasar sekolah (Zoo Market) yang melibatkan 6 kelompok usaha. Sistem pencatatan keuangan pada Phase 5 dirancang dengan prinsip:

1. **Double-Entry & Auditable Ledger:** Setiap mutasi kas (masuk/keluar/modal/koreksi) memiliki jejak waktu, nominal, identitas pencatat, dan nomor id unik (*idempotency key*).
2. **Strict Cash Basis for Real Cash:** Saldo kas fisik riil hanya bertambah jika ada kas nyata yang diverifikasi masuk ke tangan kasir atau rekening kelompok.
3. **Pemisahan Tegas Antara Modal dan Pendapatan:** Uang modal awal kelompok bukan merupakan omzet penjualan dan tidak boleh dimasukkan ke dalam perhitungan laba rugi.
4. **Isolasi Multi-Kelompok (Multi-Tenancy):** Admin Kelompok 1 sampai 6 hanya memiliki akses ke pembukuan kelompoknya masing-masing melalui *Row-Level Security* (RLS). Superadmin memegang peran audit konsolidasi global.

---

## B. RUMUS KEUANGAN & PERBEDAAN KAS RIIL VS OMZET VS MODAL

Penting bagi seluruh pengelola untuk membedakan tiga konsep utama berikut:

| Konsep | Definisi | Rumus Perhitungan | Pengaruh ke Saldo Kas |
| :--- | :--- | :--- | :--- |
| **Omzet Penjualan (Total Sales)** | Nilai total transaksi kotor dari pesanan PO ditambah penjualan langsung di stan. | $\text{Omzet} = \text{Total PO} + \text{Pendapatan Manual}$ | **Tidak Langsung.** Omzet adalah nilai transaksi, bisa berwujud kas atau piutang. |
| **Modal Kelompok (Capital)** | Dana awal atau patungan anggota kelompok untuk modal kerja. | $\sum \text{Setoran Modal}$ | **Menambah Saldo Kas**, tetapi **TIDAK** menambah omzet maupun laba. |
| **Saldo Kas Riil (Ending Cash)** | Uang fisik tunai / saldo rekening yang nyata dipegang bendahara saat ini. | $\text{Saldo Kas} = \text{Modal} + \text{Kas Masuk Terverifikasi} - \text{Pengeluaran}$ | **Tolok ukur fisik utama.** Harus cocok dengan uang fisik di dompet/kasir. |

### 10 Indikator Utama (KPI Cards):
1. **Total Penjualan (Omzet):** Nilai bruto seluruh PO + manual revenue.
2. **Uang Diterima (Terverifikasi):** Hanya uang yang sudah tercatat masuk ke buku kas.
3. **Total Piutang:** Tagihan pesanan yang belum lunas (`Total PO - Pembayaran Terverifikasi`).
4. **Pendapatan Manual:** Kas masuk dari penjualan langsung di stan (luar nomor PO).
5. **Modal Kelompok:** Total dana investasi mandiri anggota.
6. **Total Beban/Pengeluaran:** Total belanja bahan baku, operasional, kemasan, sewa stan, dll.
7. **Total HPP Terjual:** Beban pokok penjualan dihitung dari `Qty Terjual × HPP per Unit`.
8. **Laba Kotor (Gross Profit):** $\text{Omzet Penjualan} - \text{Total HPP}$.
9. **Laba Bersih (Net Profit):** $\text{Laba Kotor} - \text{Total Beban Pengeluaran}$.
10. **Saldo Kas Riil (Real Cash Balance):** $\text{Modal} + \text{Kas Terverifikasi} - \text{Total Pengeluaran}$.

---

## C. ALUR OPERASIONAL MANAJEMEN KEUANGAN

### 1. Pengaturan HPP (Harga Pokok Penjualan) Produk
- Buka tab **🏷️ HPP Produk**.
- Masukkan estimasi modal produksi per porsi untuk setiap menu makanan/minuman/bundling.
- Bila ada kenaikan atau penurunan harga bahan baku di pasar, ubah HPP. Sistem otomatis mencatat log riwayat perubahan (*HPP History*) untuk audit.
- **Peringatan HPP:** Jika ada pesanan yang menu-nya belum diisi HPP, sistem menampilkan banner peringatan agar laba kotor tidak terdistorsi.

### 2. Kas Masuk Pembayaran PO (Lunas, DP, Pelunasan)
- Setiap kali pembeli membayar PO, admin dapat mengklik tombol **💰 Bayar** pada tabel pesanan atau tombol **+ Catat Kas PO** pada tab Kas Masuk.
- Pilih jenis pembayaran:
  - **Full (Lunas Sekaligus):** Pembeli membayar lunas 100%. Status pesanan otomatis menjadi `Lunas`.
  - **DP (Uang Muka):** Pembeli membayar sebagian. Pesanan berstatus `DP` dan sisanya masuk ke piutang.
  - **Repayment (Pelunasan):** Pembeli melunasi sisa DP.
- Setiap pembayaran tersimpan di tabel `bzooginer_order_payments` dengan *idempotency key* unik dan nama user pencatat.

### 3. Pendapatan Penjualan Manual (Luar Sistem PO)
- Digunakan saat bazar berlangsung ketika ada pembeli datang langsung ke stan tanpa memesan lewat PO website.
- Buka tab **📥 Kas Masuk & PO** &rarr; klik **+ Pendapatan Manual**.
- Masukkan kategori (Penjualan Langsung Stan, Tip, atau Lainnya), nominal uang, dan keterangan.

### 4. Pencatatan Beban / Pengeluaran Operasional
- Buka tab **📤 Pengeluaran** &rarr; klik **+ Catat Pengeluaran**.
- Pilih kategori pengeluaran:
  - Belanja Bahan Baku
  - Operasional & Transportasi
  - Kemasan & Packaging
  - Sewa Stan / Tempat
  - Konsumsi & Lain-lain
- Masukkan nominal, tanggal, dan deskripsi nota. Pengeluaran otomatis mengurangi Saldo Kas Riil dan Laba Bersih.

### 5. Setoran Modal Mandiri Kelompok
- Buka tab **💼 Modal** &rarr; klik **+ Setor Modal**.
- Masukkan nama penyetor (misal: "Iuran Anggota Kelompok 3"), nominal, dan tanggal.
- Saldo Kas Riil langsung bertambah, tetapi Omzet dan Laba Bersih tetap bersih dan tidak tercampur.

---

## D. AUDIT & REKONSILIASI KAS HISTORIS (102 PESANAN PHASE 1–4)

### Latar Belakang Masalah
Pada Phase 1 sampai 4, pesanan dapat ditandai 'Lunas' melalui tombol toggle sederhana sebelum buku kas (*ledger*) diimplementasikan. Terdapat **102 pesanan bernilai Rp 1.014.000** yang berstatus Lunas di data pesanan lama namun belum tercatat di tabel `bzooginer_order_payments`.

### Mengapa Perlu Rekonsiliasi?
Jika sistem otomatis menganggap Rp 1.014.000 sebagai kas nyata tanpa verifikasi, saldo kas aplikasi akan langsung melonjak padahal bendahara belum tentu memegang uang fisiknya.

### Alur Rekonsiliasi yang Aman:
1. Pada tab **📊 Dashboard**, jika terdapat pesanan historis yang belum direkonsiliasi, muncul banner audit:
   > ⚠️ **Audit Kas: Terdapat 102 pesanan (Rp 1.014.000) berstatus Lunas sebelum Phase 5 belum tercatat di buku kas riil.**
2. Klik tombol **📋 Buka Rekonsiliasi Kas Historis**.
3. Cocokkan catatan pesanan dengan uang fisik yang diserahkan kasir kelompok.
4. **Verifikasi Satuan:** Klik `✓ Verifikasi Kas` pada baris pesanan terkait.
5. **Verifikasi Sekaligus (Batch):** Klik `⚡ Rekonsiliasi Seluruh Pesanan di Filter Ini` untuk memverifikasi seluruh pesanan kelompok tersebut sekaligus.
6. Sistem membuat entri kas resmi dengan flag `is_historical_reconciliation = true` dan `idempotency_key = recon_{order.id}`.
7. Dana otomatis berpindah dari status *'Belum Rekonsiliasi'* ke **Saldo Kas Riil**.

---

## E. FITUR PUSAT MONITORING KELENGKAPAN & PEMBAYARAN

Pusat Monitoring (Phase 4) bertugas menjaga kualitas data transaksi sebelum bazar dimulai:

1. **Tab Kelengkapan Data:**
   - Memeriksa nama pembeli, nomor telepon/WhatsApp, kelas/kategori (Guru, Staf, Kelas X/XI/XII, Umum), dan rincian variasi produk.
   - Status: **Lengkap** (hijau) atau **Perlu Dilengkapi** (merah).
2. **Tab Status Pembayaran:**
   - Menyajikan rekapitulasi pembayaran tunai (Cash Only).
   - Memisahkan status **Lunas**, **DP**, dan **Belum Lunas**.
3. **Tab Kinerja Kelompok:**
   - Menampilkan total omzet, total pesanan, dan persentase kelengkapan data per kelompok untuk memicu transparansi kerja sama tim.

---

## F. FITUR MINIMALKAN PANEL (HIDE/SHOW MONITORING & KEUANGAN)

Agar tampilan dashboard tetap rapi dan tidak terlalu panjang di layar ponsel (*mobile-friendly*), baik Pusat Monitoring maupun Manajemen Keuangan dilengkapi tombol **Sembunyikan / Tampilkan (Hide/Show)**:

- **Letak Tombol:** Terletak di sebelah tab switcher menu masing-masing modul.
- **Kondisi Diminimalkan (Collapsed):**
  - Konten tabel dan grafik disembunyikan.
  - Tampil banner ringkasan (*summary bar*) yang tetap menampilkan angka-angka kunci (Total Omzet, Kas Terverifikasi, Saldo Kas Riil).
  - Terdapat tombol `Buka Modul ▾` untuk membuka kembali dengan sekali klik.
- **Penyimpanan State:** Status buka/tutup disimpan di `localStorage` per peramban (`bzooginer_monitoring_collapsed` dan `bzooginer_finance_collapsed`).

---

## G. PEMBAGIAN PERAN & HAK AKSES (SUPERADMIN VS ADMIN KELOMPOK)

| Hak Akses / Kemampuan | Superadmin 👑 | Admin Kelompok (1–6) 👤 |
| :--- | :---: | :---: |
| **Melihat Laporan Seluruh Kelompok (Konsolidasi)** | ✅ Ya | ❌ Tidak (hanya kelompoknya) |
| **Filter Periode & Kustom Tanggal** | ✅ Ya | ✅ Ya |
| **Input & Koreksi HPP Produk** | ✅ Ya | ✅ Ya (kelompoknya) |
| **Catat Kas Masuk PO & Manual** | ✅ Ya | ✅ Ya (kelompoknya) |
| **Catat Beban Pengeluaran** | ✅ Ya | ✅ Ya (kelompoknya) |
| **Setor Modal Kelompok** | ✅ Ya | ✅ Ya (kelompoknya) |
| **Rekonsiliasi Kas Historis** | ✅ Ya (semua kelompok) | ✅ Ya (kelompoknya) |
| **Koreksi / Batalkan Transaksi Kas (Reversal)** | ✅ Ya | ❌ Tidak |
| **Fitur Impersonasi (Login Sebagai Kelompok)** | ✅ Ya | ❌ Tidak |
| **Kelola Akun & Reset Password** | ✅ Ya | ❌ Tidak |

---

## H. PANDUAN EKSPOR & CETAK LAPORAN (LABA RUGI & ARUS KAS)

1. Buka tab **📑 Laba Rugi & Arus Kas**.
2. Pilih filter periode yang ingin dicetak:
   - *Hari Ini* (untuk setoran kas harian saat bazar)
   - *Minggu Ini* (rekap mingguan persiapan bazar)
   - *Semua Waktu* (laporan pertanggungjawaban akhir kegiatan)
   - *Kustom Tanggal...* (rentang hari tertentu)
3. Klik tombol **🖨️ Cetak / Simpan PDF**.
4. Sistem otomatis memicu dialog cetak peramban (*Print Dialog*):
   - Elemen antarmuka seperti tombol, navigasi, dan header menu otomatis disembunyikan via CSS `@media print`.
   - Layout dokumen rapi dengan format kertas A4, font tajam, dan tabel bergaris bersih.
   - Pilih *'Save as PDF'* untuk menyimpan laporan dalam bentuk berkas PDF resmi.

---

## I. TIPS OPERASIONAL & TROUBLESHOOTING

1. **Berpindah Tab Browser:**
   - Anda dapat berpindah tab peramban dengan bebas. Sistem telah diamankan sehingga proses penyegaran token di latar belakang (*background token refresh*) tidak akan me-refresh halaman atau mengeluarkan Anda dari sesi admin.
2. **Koreksi Salah Input Nominal:**
   - Jika admin salah memasukkan angka pengeluaran atau pendapatan, hubungi Superadmin. Superadmin dapat menekan tombol **Batalkan** pada riwayat transaksi untuk melakukan *reversal* akuntansi yang aman tanpa menghapus jejak audit.
3. **Memantau Rekan yang Sedang Membuka Web:**
   - Klik menu **Perangkat Aktif** di navigasi atas. Fitur Presence & Live Sync memungkinkan Anda melihat berapa banyak perangkat yang sedang membuka sistem secara bersamaan.
4. **Pembaruan Data Otomatis (Realtime):**
   - Transaksi kas, HPP, atau pembayaran yang diinput oleh rekan di stan lain akan langsung ter-update di layar Anda secara instan tanpa perlu menekan tombol refresh browser.
