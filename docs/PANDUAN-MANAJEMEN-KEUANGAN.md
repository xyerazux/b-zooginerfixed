# Panduan Penggunaan & Keuangan B-Zooginer
### Panduan Sederhana Pencatatan PO, Cicilan, Keuangan Kelompok, dan Pemantauan

Dokumen ini berisi cara penggunaan aplikasi **B-Zooginer** (Zoo Market 2026) dengan bahasa yang sederhana untuk pengelola dan kasir kelompok.

---

## DAFTAR ISI

1. [A. Gambaran Umum & Aturan Keuangan](#a-gambaran-umum--aturan-keuangan)
2. [B. Arti Angka Keuangan Kelompok](#b-arti-angka-keuangan-kelompok)
3. [C. Cara Input PO Baru & Status Pembayaran (Belum Dibayar, Cicil, Lunas)](#c-cara-input-po-baru--status-pembayaran-belum-dibayar-cicil-lunas)
4. [D. Cara Mencatat Pembayaran Lanjutan & Otomatis Lunas](#d-cara-mencatat-pembayaran-lanjutan--otomatis-lunas)
5. [E. Pengelolaan Keuangan (HPP, Pemasukan Langsung, Pengeluaran, Modal)](#e-pengelolaan-keuangan-hpp-pemasukan-langsung-pengeluaran-modal)
6. [F. Pencocokan Pembayaran Lama (102 Pesanan Lama)](#f-pencocokan-pembayaran-lama-102-pesanan-lama)
7. [G. Pemantauan Pesanan, Perangkat Aktif (Hide/Show), & Halaman di HP](#g-pemantauan-pesanan-perangkat-aktif-hideshow--halaman-di-hp)
8. [H. Peran Akun (Superadmin vs Admin Kelompok) & Ganti Akun](#h-peran-akun-superadmin-vs-admin-kelompok--ganti-akun)
9. [I. Cara Cetak Laporan PDF & Tanya Jawab](#i-cara-cetak-laporan-pdf--tanya-jawab)

---

## A. GAMBARAN UMUM & ATURAN KEUANGAN

Aplikasi B-Zooginer membantu seluruh kelompok usaha di bazar sekolah:

1. **Sistem Tunai (Cash Only):** Seluruh pembayaran dicatat berdasarkan uang tunai yang benar-benar diterima oleh kasir kelompok.
2. **Pemisahan Modal dan Penjualan:** Uang modal awal / patungan anggota hanya menambah **Saldo Kas** dan tidak dihitung sebagai pemasukan penjualan atau keuntungan.
3. **Setiap Kelompok Terpisah:** Admin Kelompok hanya dapat melihat dan mengelola data pesanan serta keuangan kelompoknya sendiri. Superadmin dapat melihat semua kelompok.

---

## B. ARTI ANGKA KEUANGAN KELOMPOK

1. **Total Penjualan:** Nilai total seluruh pesanan PO ditambah pemasukan penjualan langsung di stan.
2. **Uang Masuk Tercatat:** Uang tunai yang benar-benar sudah dibayarkan pembeli dan tercatat di sistem.
3. **Uang yang Belum Dibayar:** Sisa tagihan pesanan PO yang masih harus dibayar pembeli (`Total Pesanan - Total Sudah Dibayar`).
4. **Pemasukan Langsung:** Uang hasil penjualan langsung di stan tanpa melalui formulir PO.
5. **Modal Kelompok:** Uang patungan atau modal awal anggota.
6. **Pengeluaran:** Biaya belanja bahan baku, kemasan, peralatan, transportasi, sewa, dan lain-lain.
7. **HPP (Biaya Modal Produk):** Biaya bahan dan kemasan per 1 porsi menu untuk menghitung laba.
8. **Laba Kotor:** `Total Penjualan - Total HPP`.
9. **Laba Bersih:** `Laba Kotor - Total Pengeluaran`.
10. **Saldo Kas:** `Modal + Uang Masuk Tercatat - Pengeluaran`. Angka ini harus cocok dengan uang fisik tunai di kotak kasir.

---

## C. CARA INPUT PO BARU & STATUS PEMBAYARAN (BELUM DIBAYAR, CICIL, LUNAS)

Saat mengisi formulir **Input PO**, pilih **Status Pembayaran (Tunai)**:

1. **Belum Dibayar:**
   - Pembayaran awal otomatis **Rp 0**.
   - Seluruh nilai pesanan dicatat sebagai uang yang belum dibayar.
2. **Cicil:**
   - Muncul kolom **Jumlah Uang yang Sudah Dibayar**.
   - Isi nominal uang tunai yang sudah diterima (harus lebih dari Rp 0 dan kurang dari total pesanan).
   - Sisa pembayaran dihitung otomatis dan pembayaran awal langsung masuk ke catatan keuangan.
3. **Lunas:**
   - Pembayaran awal otomatis sama dengan total pesanan.
   - Uang masuk langsung tercatat penuh dan status menjadi **Lunas**.

Sebelum menyimpan, periksa kotak **Ringkasan Pesanan & Pembayaran** yang menampilkan Total Pesanan, Sudah Dibayar, Sisa Bayar, dan Status.

---

## D. CARA MENCATAT PEMBAYARAN LANJUTAN & OTOMATIS LUNAS

Aturan status pembayaran dihitung dari total uang yang sudah tercatat masuk:

- Total bayar = **Rp 0** &rarr; **Belum Dibayar**
- Total bayar **> Rp 0** dan **< Total Pesanan** &rarr; **Cicil**
- Total bayar **>= Total Pesanan** &rarr; otomatis berubah menjadi **Lunas**

### Contoh Perhitungan Cicilan:
- Total pesanan: **Rp 100.000**
- Pembayaran pertama saat input PO: **Rp 30.000** &rarr; Status **Cicil**, sisa **Rp 70.000**.
- Pembayaran kedua lewat tombol **Bayar**: **Rp 40.000** &rarr; Status tetap **Cicil**, sisa **Rp 30.000**.
- Pembayaran ketiga lewat tombol **Bayar**: **Rp 30.000** &rarr; Total tercatat **Rp 100.000**, sisa **Rp 0**, status **otomatis menjadi Lunas**.

Untuk melihat rincian total, sudah dibayar, sisa pembayaran, dan daftar tanggal pembayarannya, tekan tombol **Detail** pada pesanan.

---

## E. PENGELOLAAN KEUANGAN (HPP, PEMASUKAN LANGSUNG, PENGELUARAN, MODAL)

- **HPP Produk:** Buka tab **HPP Produk** untuk mengisi biaya modal 1 porsi menu. Contoh: harga jual Rp 15.000 dan biaya modal Rp 8.000, maka laba kotor per porsi adalah Rp 7.000.
- **Kas Masuk:** Menampilkan semua pembayaran PO dan pemasukan langsung dari stan.
- **Pengeluaran:** Buka tab **Pengeluaran** &rarr; klik **+ Catat Pengeluaran** untuk mencatat belanja bahan atau keperluan stan.
- **Modal:** Buka tab **Modal** &rarr; klik **+ Tambah Modal** untuk mencatat modal awal atau tambahan modal anggota.

---

## F. PENCOCOKAN PEMBAYARAN LAMA (102 PESANAN LAMA)

Terdapat **102 pesanan lama (Rp 1.014.000)** yang berstatus Lunas sebelum sistem catatan pembayaran ini aktif. Pesanan lama tersebut **tidak otomatis** dimasukkan ke Saldo Kas sebelum uang fisiknya diperiksa.

1. Klik **Buka Pencocokan Pembayaran Lama** di banner kuning bagian Keuangan.
2. Cocokkan catatan pesanan dengan uang tunai yang diserahkan bendahara kelompok.
3. Klik **Cocokkan Uang** (satu per satu) atau **Cocokkan Semua di Filter Ini**.
4. Setelah dicocokkan, uang baru resmi masuk ke **Uang Masuk Tercatat** dan **Saldo Kas**.

---

## G. PEMANTAUAN PESANAN, PERANGKAT AKTIF (HIDE/SHOW), & HALAMAN DI HP

- **Pemantauan Pesanan & Pembayaran:** Memeriksa kelengkapan data pembeli, status pembayaran (Belum Dibayar, Cicil, Lunas), dan kinerja tiap kelompok.
- **Sembunyikan / Tampilkan (Hide/Show):** Bagian Pemantauan Pesanan, Pengelolaan Keuangan, dan Pemantauan Perangkat Aktif masing-masing memiliki tombol **Sembunyikan** untuk meringkas layar. Status buka/tutup tersimpan otomatis di browser perangkat Anda.
- **Tampilan 5 Data per Halaman di HP:** Agar daftar tidak terlalu panjang di HP, daftar pesanan, daftar pembeli, transaksi keuangan, daftar perangkat, dan daftar akun dibatasi **5 data per halaman**. Gunakan tombol **Sebelumnya** dan **Berikutnya** untuk berpindah halaman.

---

## H. PERAN AKUN (SUPERADMIN VS ADMIN KELOMPOK) & GANTI AKUN

- **Superadmin:** Bisa melihat dan mengelola seluruh kelompok, mengatur akun pengguna, serta memakai fitur **Ganti Akun** untuk masuk ke tampilan kelompok tertentu sementara.
- **Admin Kelompok:** Hanya melihat dan mengelola pesanan serta keuangan milik kelompoknya sendiri.

---

## I. CARA CETAK LAPORAN PDF & TANYA JAWAB

1. Buka menu **Keuangan &rarr; Laporan**.
2. Pilih periode yang diinginkan (Semua Waktu, Hari Ini, Minggu Ini, Bulan Ini, atau Pilih Tanggal).
3. Klik **Cetak Laporan (PDF)** lalu pilih *Save as PDF*.
4. **Pembaruan Data Otomatis:** Pesanan dan pembayaran baru dari perangkat lain tetap otomatis tersinkronkan secara langsung.
