# EXT-04 · Whole on-device database encryption

Scope: the **entire on-device Drift SQLite database** (including outbox, snapshots and EXT study documents). This does not claim client-side encryption of Supabase/Postgres, image files, or user-requested exports.

## Applied implementation

- Existing locked sqlite3 3.5.2 native assets select `source: sqlite3mc`; no EOL SQLCipher Flutter library. Explicit ChaCha20-Poly1305, full encrypted header, MAC checking. The application checks the codec pragma and SQL function at runtime, including release builds. It never assumes a successful unknown `PRAGMA key` means encryption happened.
- Per-install 256-bit `Random.secure()` key, scoped to the existing DB filename/flavor. Secure storage is read back after write; no plaintext key file/fallback. iOS uses first-unlock-this-device-only, no synchronization. Auth logout does not delete the key. DB wipe preserves the encrypted container and key.
- Exact legacy path from drift_flutter 0.3.1: `getApplicationDocumentsDirectory()/soongong_<flavor>.sqlite`. All callers now use the encrypted opener; bootstrap completes preparation before any repository startup.
- Before the first conversion: process file lock, WAL checkpoint checked for busy, DELETE journal, exclusive SQLite lock, integrity + foreign-key check. VACUUM snapshot is encrypted as a separate file. Every explicit schema object/table, user_version and a typed multiset digest of all rows are compared. All current app tables have explicit primary keys; implicit SQLite rowids are not application identifiers.
- A flushed, atomically renamed marker records copying/verified stages. Only a reopened and verified encrypted copy can replace the original. Failures between original rename / install / cleanup recover on restart. Original plaintext and its temporary sidecars are removed after revalidation. Cleanup failures block DB access and retry next launch.
- New files are encrypted before Drift creates its schema. Wrong/missing keys, bad codec, corruption, orphaned migration files or secure-storage failures block startup with a retry screen; no auto-reset or empty replacement.
- Copy/hash/rekey runs in an isolate; Drift queries retain a background isolate. Normal encrypted startup validates codec/key/schema without a full table scan. Temp SQL data is in memory. Runtime journal is DELETE so iOS does not need a plaintext WAL-identification header.

## Backup / recovery boundary

Android cloud backup and device transfer are excluded. iOS app Documents are excluded from OS backup because the DB key is device-bound; this also excludes other app-owned documents/photos in that directory. User-created exports are separate explicit actions. Local unsynced records will not transfer to a replacement device. **S13 sync is still Fake**: do not imply server restore exists.

There is no decrypt-to-plaintext rollback switch. Older plaintext-only binaries cannot open the new file. Recover releases by rolling forward with a codec-compatible binary. Never regenerate a missing key, delete files, or restore the plaintext predecessor automatically. Key loss requires a separate, explicit user recovery decision.

The crash harness covers process interruption and write ordering. Dart does not expose portable parent-directory fsync; sudden power loss/storage hardware failure durability needs physical-device fault testing. Secure deletion cannot guarantee erasure of historical flash blocks or pre-existing OS backups. Key strings remain in process memory while the DB is open.

## Required before product release

Android/iOS release-build codec and migration tests (including coexistence with MediaPipe/system SQLite), locked-device/keychain behavior, OS backup/restore, real low-space/kill faults and startup/query benchmarks on supported devices. CI unit/native build results are recorded in EXT-FINAL, not treated as device evidence.

Source: sqlite3 3.5.2 official `doc/hook.md`; SQLite3MultipleCiphers official SQL pragma/function documentation. Bundled MIT notice in `assets/licenses/SQLite3MultipleCiphers-MIT.txt`.
