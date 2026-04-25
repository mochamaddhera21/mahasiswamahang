# Panduan Keamanan Push ke GitHub

## A) Tinjauan Risiko & Rekomendasi

### Risiko Utama
1. **Commit file sensitif (.env)** jika `.gitignore` belum benar
2. **Menimpa remote origin** tanpa sengaja
3. **Push gagal** karena branch protection
4. **Skrip otomatis** melakukan `git add .` — pastikan tidak ada file pribadi

### Rekomendasi Keamanan
1. ✅ Pastikan `.gitignore` berisi: `.env`, `uploads/`, `node_modules/`, `dist/`
2. ✅ Skrip akan menampilkan warning jika file sensitif terdeteksi
3. ✅ Jika remote sudah punya branch protected, push ke branch baru lalu buat PR
4. ⚠️ Mode non-interactive hanya untuk automation yang sudah terbukti aman
5. ✅ Simpan PAT/SSH di tempat aman; gunakan SSH untuk push (lebih aman)

---

## B) Skrip yang Disempurnakan: `push_to_github_safe.sh`

### Fitur:
- ✅ Deteksi file sensitif (.env) dan warning sebelum push
- ✅ Mode interactive (default) dan non-interactive
- ✅ Opsi mengganti remote dengan konfirmasi
- ✅ Opsi skip-release untuk CI/CD
- ✅ Opsi push ke feature branch jika main branch protected

### Penggunaan:

**Mode Interactive (recommended):**
```bash
chmod +x push_to_github_safe.sh
./push_to_github_safe.sh
```

**Mode Non-Interactive (dengan opsi):**
```bash
./push_to_github_safe.sh \
  --remote git@github.com:mochamaddhera21/mahasiswamahang.git \
  --branch main \
  --non-interactive \
  --skip-release
```

**Opsi Tersedia:**
- `--remote <url>` — Override default remote SSH URL
- `--branch <branch>` — Set target branch (default: main)
- `--non-interactive` — Run tanpa prompt (gunakan hati-hati)
- `--skip-release` — Skip tag & release creation
- `--force-remote` — Replace origin tanpa konfirmasi
- `--help` — Tampilkan bantuan

---

## C) Perintah Git One-Liner (Siap-Copy)

Jalankan dari root folder project (magang-backend). Ganti remote URL jika perlu.

### 1) Set .gitignore (jika belum ada)
```bash
cat > .gitignore <<'EOF'
node_modules
dist
.env
.env.*
uploads
.DS_Store
EOF
```

### 2) Init, Add, Commit, Set Branch Main
```bash
git init
git add .
git commit -m "Initial commit: magang backend MVP"
git branch -M main
```

### 3) Add Remote SSH dan Push
```bash
git remote add origin git@github.com:mochamaddhera21/mahasiswamahang.git
git push -u origin main
```

### 4) Create & Push Tag (Optional)
```bash
git tag -a v0.1.0 -m "v0.1.0 initial"
git push origin v0.1.0
```

### ⚠️ Jika Remote Main Branch Protected:
Ganti step 3 dengan:
```bash
git checkout -b feature/initial
git push -u origin feature/initial
# Kemudian buat Pull Request di GitHub UI
```

---

## D) GitHub Actions Workflow: Automated Release

File: `.github/workflows/release.yml`

**Fitur:**
- Trigger: Push tag dengan format `v*.*.*` (contoh: `v0.1.0`, `v1.2.3`)
- Action:
  1. Checkout kode
  2. Setup Node.js 18
  3. Install dependencies (`npm ci`)
  4. Build (jika ada `npm run build`)
  5. Create ZIP artifact
  6. Create GitHub Release & upload ZIP otomatis

### Cara Menggunakan:

1. **Workflow sudah ada di repo**
2. **Push tag untuk trigger release:**
   ```bash
   git tag -a v0.1.0 -m "v0.1.0"
   git push origin v0.1.0
   ```
3. **GitHub Actions akan berjalan otomatis:**
   - Cek di repository → Actions tab
   - Release akan muncul di Releases → Assets
   - ZIP artifact: `magang-backend-v0.1.0.zip`

---

## Checklist Sebelum Push Pertama Kali

- [ ] SSH key sudah ditambahkan ke GitHub (Settings → SSH and GPG keys)
- [ ] `.gitignore` berisi file sensitif (`.env`, `node_modules/`, dst)
- [ ] Tidak ada file pribadi atau password di folder project
- [ ] Jalankan skrip **interactive mode** dulu untuk review
- [ ] Pastikan branch `main` tidak ada atau sudah di-sync
- [ ] Jika push gagal: periksa branch protection settings

---

## Troubleshooting

### Push Failed: "Permission denied (publickey)"
```bash
# Pastikan SSH key ditambahkan:
ssh -T git@github.com
# Output: "Hi username! You've successfully authenticated..."
```

### Push Failed: "branch protection"
```bash
# Push ke feature branch dulu:
git checkout -b feature/init
git push -u origin feature/init
# Buat PR di GitHub
```

### .env atau file sensitif sudah di-commit
```bash
# Remove dari git history (hanya jika sudah di-push ke main):
git rm --cached .env
echo ".env" >> .gitignore
git commit -m "Remove .env from tracking"
git push origin main
# PENTING: Rotate semua secrets/API keys di .env!
```

---

## Referensi
- [GitHub SSH Keys Setup](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [Git .gitignore](https://git-scm.com/docs/gitignore)
- [GitHub Branch Protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)
- [GitHub Actions Workflows](https://docs.github.com/en/actions/quickstart)
