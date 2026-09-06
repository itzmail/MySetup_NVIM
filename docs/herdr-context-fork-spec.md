# Spec: Fork herdr-context.nvim

> Base repo: `makyinmars/herdr-context.nvim` (MIT License)
> Tujuan: melengkapi kekurangan dengan tetap full Lua, tanpa dependency Rust/compiled binary.

---

## 1. Fitur Existing (base, jangan diubah arsitekturnya)

Ini fitur yang sudah ada di upstream — dipertahankan sebagai fondasi:

- **Provider system** — sumber context yang bisa di-stage:
  - Visual selection
  - LSP symbol (function/class di bawah cursor)
  - Git hunk (via MiniDiff / git diff)
  - Diagnostics (LSP errors/warnings)
  - Quickfix / Trouble list
  - API `register_provider()` untuk custom provider
- **Composer/preset system** — mode staging siap pakai: `debug`, `review`, `explain`, dst.
- **Byte budget enforcement** — `max_payload_bytes`, reject (bukan truncate) kalau context kelebihan.
- **Transport aman** — kirim ke Herdr via `herdr pane send-text` sebagai satu argv element (anti shell-injection), bracketed-paste untuk multiline.
- **Staging terpisah dari submit** — compose dulu, baru user yang trigger kirim (gak auto-submit).
- **History staging** in-memory.
- **Live agent presence** — socket + polling fallback untuk tau status agent (idle/busy/dll).
- **Safety layer dasar** — exclude pattern (`.env`, `*.pem`) + secret pattern matching + double-confirm sebelum staging.
- **Test suite** — `make test` dan `make test-live` untuk provider timeout, LSP symbol, MiniDiff, git diff parsing.

---

## 2. Fitur Baru yang Akan Dibangun

### 2.1 Enhanced Secret Detection (prioritas tertinggi, low effort)

- [x] Tambah pattern baru: GCP service account key (JSON `"type": "service_account"`), GitHub PAT (`gh[pousr]_`), Slack token (`xox[baprs]-`), JWT structure (`eyJ...eyJ...`). SSH private key variants sudah tercover oleh pattern generic `-----BEGIN .-PRIVATE KEY-----` yang sudah ada sebelumnya.
- [x] **Entropy-based detection** — `safety.shannon_entropy()` menghitung Shannon entropy per token (`%S+`); flag kalau ≥ threshold (default 4.5 bits/char, `entropy_threshold`) dan panjang token ≥ `entropy_min_length` (default 20).
- [x] Context-aware check — high-entropy token cuma di-flag kalau baris yang sama mengandung salah satu `entropy_keywords` (`key`, `secret`, `token`, `password`, `credential`).
- [x] Config opsional untuk custom pattern per-project — `opts.safety.secret_patterns` dan `opts.safety.entropy_*` bisa di-override lewat `setup()` (replace penuh via `vim.tbl_deep_extend("force", ...)`, bukan append — gabungkan manual dengan default kalau mau menambah bukan mengganti).
- [x] Test case untuk tiap pattern + entropy edge case (false positive/negative) — lihat `tests/run.lua`, 5 test baru: pattern baru (PAT/Slack/GCP), JWT, entropy+keyword proximity, `shannon_entropy()` unit test, dan short-token-below-minimum guard.

### 2.2 Touched-Files Module (opt-in, modul terpisah)

> Catatan: upstream sudah punya `picker.lua`, tapi itu picker untuk *pilih target agent* (pane/tab/workspace) — bukan fitur ini. Modul baru ini pakai nama berbeda (mis. `touched_files.lua`) supaya gak ketuker.

- [x] ~~Baca output agent via `herdr agent read --source recent-unwrapped`, parse file yang disentuh~~ — **Won't do.** Riset langsung terhadap scrollback nyata (`herdr agent read <pane> --source visible --format text`) menunjukkan Claude Code CLI — tool utama yang dipakai — **tidak pernah mencetak nama file** yang di-`Edit`/`Write`/`Read` ke layar; yang tampil cuma ringkasan generik ("Ran 1 shell command", "Searched for 1 pattern") tanpa argumen. Ini bukan soal regex kurang canggih — datanya memang tidak ada di scrollback. Herdr API juga tidak punya endpoint terstruktur (`agent explain`/snapshot) yang mengembalikan file yang diedit. Fitur ini butuh sumber data yang belum ada; dicoret sampai ada endpoint terstruktur di Herdr sendiri.
- [ ] ~~Sisa sub-item (picker, diff stats, config toggle)~~ — tidak relevan tanpa sumber data di atas.

> Ide lanjutan yang muncul dari diskusi ini: "cursor sharing" real-time (nvim menampilkan indikator visual + opsi focus ke posisi baris yang sedang diedit agent, plus dashboard semua agent yang sedang berjalan). Riset lanjutan (2026-08-18) menemukan jalur teknis konkret: **Agent Client Protocol (ACP)** — protokol RPC terbuka (dipakai Zed untuk fitur "follow the agent") yang punya field resmi `ToolCallLocation { path, line }` dikirim lewat notifikasi `session/update` tiap tool call, didesain eksplisit untuk "follow-along" features (lihat agentclientprotocol.com/protocol/tool-calls). Neovim sudah terdaftar resmi sebagai ACP editor (zed.dev/acp/editor/neovim), dan sudah ada plugin nvim ACP client dewasa (CodeCompanion.nvim, agentic.nvim) yang mendukung Claude/Codex/Copilot/Gemini/Cursor-agent sebagai ACP agent.
>
> **Ini BUKAN scope `herdr-watch.nvim`** — arsitekturnya beda total: Herdr memantau proses terminal dari luar (lifecycle status only, terbukti tidak punya data file:line — lihat item di atas), sedangkan ACP mengharuskan agent dijalankan sebagai subprocess ACP yang di-spawn langsung dari nvim (bukan CLI biasa di pane terminal Herdr). Kalau mau dikejar, ini proyek terpisah — entah pakai plugin ACP client yang sudah ada, atau bikin sendiri. Belum masuk scope kerja apa pun, dicatat sebagai jalur riset yang sudah tervalidasi untuk direvisit nanti.

### 2.3 Reliability — Live Presence

> Catatan: exponential backoff untuk reconnect socket **sudah ada** di upstream (`watch.lua` — `reconnect_delay = math.min(reconnect_delay * 2, cfg.presence.reconnect_max_ms)`). Item itu dicoret dari scope, sisa fokus di bawah ini.

- [x] ~~Heartbeat/health-check berkala~~ — **Won't do.** Protokol socket Herdr tidak punya method `ping`/heartbeat native (cuma `events.subscribe` dan request generik JSON-RPC). Satu-satunya cara "heartbeat" yang realistis adalah memanggil `herdr.snapshot()` berkala, tapi itu spawn proses eksternal (`vim.system()`) tiap panggilan — biayanya jauh lebih besar dari manfaatnya untuk kasus silent-hang yang jarang terjadi, sementara `on_error`/`on_close` di `socket.lua`/`watch.lua` sudah menangkap mayoritas disconnect (FIN/RST) secara reaktif dan gratis.
- [x] Notifikasi eksplisit ke user (`vim.notify`) saat data presence stale/disconnect — `notifications.lua` sudah subscribe ke autocmd `HerdrContextConnected`/`HerdrContextDisconnected` (dipancarkan `state.lua`, sudah ada sebelumnya, tidak perlu event baru). Toggle baru `presence.notifications.disconnected` (default `false`, konsisten dengan toggle lain), WARN saat disconnect, INFO saat reconnect.

### 2.4 Defensive Coding terhadap Herdr API

- [x] Version check saat startup — `herdr.version_meets_minimum()` membandingkan `snapshot.version` dengan `opts.min_herdr_version` (default `"0.7.5"`, sesuai README); `:checkhealth` menampilkan `health.warn` kalau versi terhubung di bawah minimum. Versi yang tidak bisa di-parse (`"unknown"`/nil) diperlakukan sebagai unknown, bukan gagal.
- [x] Graceful degradation kalau env var (`HERDR_PANE_ID`, `HERDR_TAB_ID`, `HERDR_WORKSPACE_ID`, `HERDR_SOCKET_PATH`) gak ketemu — sudah terpenuhi oleh implementasi existing: `targets.lua`/`state.lua` fallback ke snapshot/nil tanpa crash, `health.lua` sudah `health.warn` per env var yang kosong. Tidak ada kode tambahan.
- [x] Abstraksi layer untuk komunikasi ke Herdr (satu titik integrasi) — sudah terpenuhi oleh `herdr.lua` existing (semua command Herdr CLI/JSON lewat modul ini). Tidak ada kode tambahan.

### 2.5 Housekeeping

- [x] Rename package → `herdr-watch.nvim` (fork user: `itzmail/herdr-watch.nvim`).
- [x] Update README: jelasin ini fork dari `makyinmars/herdr-context.nvim`, apa yang beda.
- [x] Pastikan `LICENSE` (MIT) tetap ada & attribution ke upstream jelas.
- [x] Setiap fitur baru wajib punya test yang konsisten dengan gaya test suite yang sudah ada.

### 2.6 Live Cursor Dashboard (riset selesai 2026-08-18, diimplementasikan 2026-08-19)

> Asal ide: "multiplayer nvim" — dashboard semua AI agent yang lagi jalan (Claude Code, Codex, dll di pane terminal terpisah, dijalankan seperti biasa — bukan lewat ACP/agentic.nvim), bisa jump/focus ke posisi file:line yang sedang disentuh tiap agent, toggle follow-mode on/off, switch antar agent. Ini FITUR TAMBAHAN untuk `herdr-watch.nvim`, bukan proyek terpisah — riset di bawah sudah membuktikan jalurnya lewat API resmi Herdr, bukan hack.

**Riset yang sudah dilakukan (dan kenapa jalur lain dicoret):**

- ❌ **Herdr socket/API standar** (`agent_status`, `session.snapshot`) — dibuktikan langsung dari `herdr api schema --json` (protokol v19): `PaneInfo` cuma punya `cwd`/`agent_status`/`terminal_title`, tidak ada file/line/cursor sama sekali. Kata "cursor" di schema itu nama editor Cursor (`IntegrationTarget` enum), false lead.
- ❌ **ACP (Agent Client Protocol)** — protokol resmi yang dipakai Zed untuk fitur "follow the agent" (field `ToolCallLocation{path,line}` di `session/update`), dan Neovim sudah jadi ACP editor resmi (CodeCompanion.nvim, agentic.nvim sebagai client). **TAPI** ini mengharuskan agent dijalankan sebagai subprocess ACP yang di-spawn dari nvim (`agentic.nvim` + `claude-agent-acp`/`codex-acp` CLI terpisah) — bukan skenario kamu (Claude Code/Codex dipakai biasa di terminal, nvim cuma nonton dari luar). Dicoret untuk fitur ini, tapi tetap valid sebagai proyek berbeda kalau suatu saat mau chat-interface-in-nvim.
- ✅ **Hook native tiap CLI agent + endpoint metadata generik Herdr** — jalur yang dipakai, detail di bawah.

**Sumber data (per-agent, hook custom — TIDAK mengedit file hook yang di-manage Herdr):**

- **Claude Code**: hook `PostToolUse` dengan matcher `Edit|Write`. Payload punya `tool_input.file_path` (dan `tool_input.old_string`/line context tergantung tool) — terbukti terstruktur, sudah diamati langsung dari transcript sesi ini sendiri.
- **Codex**: hook `PostToolUse` dengan matcher `apply_patch` (alias `Edit`/`Write` juga match, tapi `tool_name` yang dilaporkan selalu `"apply_patch"`). Payload `tool_input.command` berisi patch content (format `apply_patch`, ada header path per hunk) — perlu diparse, tidak langsung berbentuk `file_path` seperti Claude. Dikonfirmasi resmi di `developers.openai.com/codex/hooks` (tool coverage table): `apply_patch` **memang** trigger `PreToolUse`/`PostToolUse`, hasil pencarian web awal yang bilang "PreToolUse Bash only" itu keliru/basi.
- Herdr sendiri sudah punya pola persis ini — `~/.claude/hooks/herdr-agent-state.sh` dan `~/.codex/hooks.json` (`SessionStart` saja) adalah bukti hidup bahwa integrasi hook-per-agent itu memang cara resmi Herdr bekerja. Hook baru ditambahkan sebagai entry terpisah di `hooks.json`/`~/.claude/settings.json`, tidak mengubah file yang di-manage Herdr (komentar file itu eksplisit bilang begitu).

**Transport (method Herdr resmi, sudah diverifikasi dari `herdr api schema --json`):**

- Kirim: `pane.report_metadata` — `{pane_id, source, tokens: {file: "...", line: "..."}, ttl_ms}`. `tokens` adalah object generik (maks 16 key, key pattern `[A-Za-z0-9_-]{1,32}`, TTL sampai 24 jam) — didesain resmi untuk metadata custom per-pane, bukan endpoint yang disalahgunakan.
- Baca: field `tokens` muncul balik di `PaneInfo.tokens` lewat `session.snapshot` maupun `pane.get` — round-trip terverifikasi lewat schema (`event.$defs.PaneInfo` dan `success_response.$defs.PaneInfo` sama-sama punya `tokens`/`state_labels`).
- **Batasan penting**: `events.subscribe` (dipakai `watch.lua` untuk push update) cuma punya 3 kind — `pane.output_matched`, `pane.agent_status_changed`, `pane.scroll_changed`. **Tidak ada push notification untuk perubahan `tokens`.** Dashboard ini harus **polling** `session.snapshot` berkala (mis. tiap 1-2 detik saat dashboard/follow-mode aktif), bukan instant-push seperti status agent sekarang. Cukup untuk use-case ini (edit file tidak berubah tiap milidetik), tapi bukan real-time sub-detik.
- `tokens` cuma menyimpan value terakhir (overwrite) — kalau agent multi-edit cepat, cuma "posisi paling baru" yang kebaca, bukan riwayat.

**Implementasi (selesai 2026-08-19):**

- [x] Hook custom Claude Code (`~/.claude/hooks/herdr-cursor-report.sh`, entry `PostToolUse` matcher `Edit|Write` di `~/.claude/settings.json`) → kirim `pane.report_metadata` dengan `source: "claude-code-cursor"`. File hook Herdr yang di-manage (`herdr-agent-state.sh`) tidak disentuh.
- [x] Hook custom Codex (`~/.codex/herdr-cursor-report.sh`, entry `PostToolUse` matcher `apply_patch` di `~/.codex/hooks.json`) → parse header `*** Update/Add/Delete File: <path>` dari payload `tool_input.command`, kirim `pane.report_metadata` dengan `source: "codex-cursor"`. Line number tidak tersedia di payload Codex (selalu `"0"`), dicatat sebagai keterbatasan bawaan, bukan bug.
- [x] `herdr.lua`: `M.session_snapshot(config, opts, callback)` — wrapper socket-first baru (pola sama `read_agent`'s `opts.socket_request` injection), kirim `session.snapshot`, unwrap `result.snapshot`.
- [x] `config.lua`: block `cursor_dashboard = { enabled = false, poll_interval_ms = 1500 }` + validasi (`vim.validate` + positive-integer check, pola sama `presence.*`).
- [x] `lua/herdr-watch/cursor.lua` — modul state+polling baru (bukan bagian dari `state.lua`): timer `uv.new_timer()` dengan idiom `generation` guard dan `close_timer` dari `watch.lua`, baca `snapshot.panes[].tokens`, emit autocmd `HerdrCursorUpdated` cuma saat file/line pane berubah (dedup).
- [x] `lua/herdr-watch/ui/dashboard.lua` — vsplit scratch buffer (resep sama `ui/agents.lua`): render daftar pane+file:line, keymap `<CR>` jump, `f` toggle follow-mode (auto-jump saat `HerdrCursorUpdated` untuk pane yang di-follow), `r` refresh, `q`/`<Esc>` close (stop polling on `BufWipeout`).
- [x] `init.lua`: expose `M.cursor_dashboard()`. Keymap baru `<leader>aw` di `~/.config/nvim/lua/plugins/herdr-context.lua`.
- [x] Test: `tests/run.lua` — `session_snapshot` (sukses + socket unavailable), `cursor.lua` polling (emit-on-change, dedup saat tokens sama), validasi config `cursor_dashboard.poll_interval_ms`. Parser regex Codex diverifikasi terpisah (6 kasus termasuk multi-hunk dan non-patch command) karena hidup di luar repo plugin (`~/.codex/`).
- [x] `make test-lua` (85/85) dan `stylua --check` tetap hijau setelah semua perubahan; `:checkhealth herdr-watch` tidak menunjukkan regresi.

---

## 3. Non-Goals (biar Claude Code gak over-engineer)

- ❌ Tidak menambahkan komponen Rust/compiled binary — tetap pure Lua.
- ❌ Tidak membangun sidebar nvim persisten ala `herdr-nvim` (ChmaraX) — cukup picker ringan.
- ❌ Tidak mengubah core provider/composer API yang sudah ada — fitur baru harus additive, bukan breaking change.

---

## 4. Urutan Pengerjaan yang Disarankan

1. Enhanced secret detection (§2.1) — quick win, isolated ke `safety.lua`.
2. Test suite untuk fitur di atas.
3. Defensive coding terhadap Herdr API (§2.4) — fondasi biar fitur berikutnya lebih aman.
4. Reliability live presence (§2.3).
5. File visibility/picker module (§2.2) — paling kompleks, kerjakan terakhir sebagai modul opt-in.
6. Housekeeping & rename (§2.5) — kapan saja, idealnya sebelum publish.
