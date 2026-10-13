# RC-02 / RC-03 native ownership patch

The app's Dart owner registers `getTemporaryDirectory()/soongong-owned-v1/<scope UUID>/<task UUID>/marker.json` and `payload/` **before** invoking the OS picker or share bridge. Native code validates the existing canonical directories, marker version/IDs/kind/timestamps, and scope `.revoked` / task `.delete`. It never recreates a missing task parent. Source photos are read only; filenames and saved owner references contain only random IDs and fixed suffixes.

## Exact upstream sources

These are path overrides of the existing locked versions, not dependency upgrades. Vendored directories retain upstream LICENSE, README, CHANGELOG, Dart API, codecs, native permission/picker APIs, and native test sources. `UPSTREAM_SOURCES.json` records the SHA-256 of every included original source file; entries absent upstream are additions.

| Package | Exact public archive | SHA-256 |
|---|---|---|
| Android picker | [image_picker_android 0.8.13+23](https://pub.dev/packages/image_picker_android/versions/0.8.13%2B23) | `0a55d645a670d6ae11efa948f955ae904afa472f1344fc15a7ddacc20c1e7219` |
| iOS picker | [image_picker_ios 0.8.13+9](https://pub.dev/packages/image_picker_ios/versions/0.8.13%2B9) | `815921d05ef87d64dc64e9f7f855967614a9a67086d0c60fa27d47a1cd9a8896` |
| Share audit, not vendored | [share_plus 13.3.0](https://pub.dev/packages/share_plus/versions/13.3.0) | `34f00f9becd2743c1fb05363d624f9f70d37f7ccdcdda47450bc0b8c9d327b8c` |
| Path-provider audit, not vendored | [path_provider_foundation 2.6.0](https://pub.dev/packages/path_provider_foundation/versions/2.6.0) | `2a376b7d6392d80cd3705782d2caa734ca4727776db0b6ec36ef3f1855197699` |

Top-level `image_picker` remains 1.2.3. Overrides replace only the two platform implementations. Root analyzer excludes vendored dependency code; application checks remain intact. The new Android test dependencies use the versions already declared by the exact Android picker archive.

## Creation/copy audit and changed boundary

* Android upstream `ImagePickerDelegate.createTemporaryWritableFile` creates a camera file in the global cache before the OS launch/callback; `FileUtils.getPathFromUri` copies a provider stream into cache/randomUUID/original-name, and `ImageResizer` creates another cache file. All three now require an existing prepared task and create inside its payload. Provider names/URIs are not copied into metadata/logs. The camera FileProvider exposes only the owned root and revalidates the owner for each new open.
* Upstream lost-data SharedPreferences hold absolute camera/results paths and do not cover every creation-before-callback crash. The registered marker makes those interrupted files discoverable independently. New preferences contain relative opaque references, not absolute paths. Retrieval does not resize/create a fresh copy. Persisted request codes bind callbacks to their original owner; a late A result cannot become B's pending result. Codes monotonically advance through 16000–64999 and fail closed on exhaustion, rather than reusing an old outstanding code.
* A recovered persisted Android lease, with no in-process producer, is fenced by a synced `.delete` file before its owner is released. A live in-process selection/writer remains active. Legacy unowned absolute lost-data references produce durable `unknown=true`; they are never adopted or arbitrarily deleted. Clearing that legacy uncertainty requires separate verified migration/removal, or OS app-data removal; this patch cannot claim zero residual for it.
* iOS upstream `FLTImagePickerPhotoAssetUtil.temporaryFilePath` writes into `NSTemporaryDirectory()` during camera/PHPicker result processing. Its codec outputs now require a captured owner and use the prepared payload. PHPicker operations carry immutable owner objects; duplicate calls are rejected and delayed operations cannot acquire a new owner's root. Foundation data writes check cancellation/revocation between chunks. Codec operations that cannot be interrupted remain active until they return, so cleanup must report incomplete while they run.
* The locked `path_provider_foundation` 2.6.0 `getTemporaryPath()` uses `NSCachesDirectory`, **not** `NSTemporaryDirectory`. The iOS owner uses canonical `NSCachesDirectory` to match Dart. iOS has no lost-data callback API; on a real fresh process the native in-memory producers are gone, and the Dart marker scanner enumerates interrupted tasks. There is no restoration of interrupted OCR input.
* Android `share_plus` 13.3.0 `Share.kt` copies into `cacheDir/share_plus` and clears that global directory on a subsequent share. The app's owned-share bridge does neither: it grants a read-only URI to the existing task file. New provider opens revalidate the owner. iOS upstream shares the supplied URL directly; the new bridge does likewise, with an iPad popover anchor and a captured attachment object that revalidates when `UIActivityItemSource` later requests its URL. A revoked A attachment returns nil even if its deletion failed.

## Native channel contract

`co.byite.soongong/picker_owner`:

* `prepare({scope,task})`: validate existing picker task, persist Android owner, reject overlapping selection.
* `status({scope,task})`, `cancel({scope,task})`: `{active: bool, unknown: bool}`. Cancellation fences new writes immediately. Android provider streams are closed off the main thread and owner monitor; blocked close/read leaves the task active. Native future completion plus zero writers is required before release.
* `release({scope,task})`: release only after native callback/writers end. Never releases another owner.
* `recover()`: called after Android `ImagePicker.retrieveLostData()` by the serialized Dart coordinator. Fences a dead-process Android lease; reports current live work/legacy uncertainty honestly. iOS reports only current native producers; marker recovery remains the Dart scanner's responsibility.

`co.byite.soongong/owned_share.share({scope,task,relativeName,name,mimeType})` validates an export task and returns `handedOff` for an OS presentation attempt. `relativeName` is `attachment` or `attachment.json/csv/zip/txt`; `name` is a public basename, not a path. `mimeType` is one of application/json, text/csv, application/zip, text/plain. File extension is recommended for receiver compatibility. There is no native share copy and no global-cache clear. The return is not recipient-read confirmation; the Dart TTL and receipt state remain authoritative.

## Verification and limits

`native-check.yml` compiles the app for Android and iPhone device ARM64 without signing/deploying. It also runs `OwnedImageStoreTest` (production owner, real synthetic provider copy/camera file creation, cancellation, recovery, stale callback isolation, symlink and marker fences), `OwnedShareBridgeTest` (actual Intent/provider handoff and late/revoked reads), and a standalone macOS Foundation executable using the **same iOS ownership implementation**, including a child process exiting after write and before callback. The Foundation tests also exercise the real deferred attachment getter after revocation while the file remains. These are not camera hardware, PHPicker UI, recipient-app, backup/restore, or OCR accuracy proofs. The retained upstream package suite is not asserted to have been run by these focused regression jobs.

Local Windows checking uses Java/Kotlin compiler binaries and already-cached Android/Flutter class definitions only; no local Flutter, Dart pub, Gradle build, deployment, personal image, or external AI request is required. Full native build/test outcomes must be taken from exact-head CI; a source scan or this document alone is not PASS evidence.

The app can fence fresh opens and unlink its own paths. It cannot revoke an already-open external camera/receiver descriptor or delete copies a receiver/system has already made. Unlink is not secure erasure. System-managed camera/PHPicker representations and recipient behavior require the separately documented real-device checks; the application-owned copy boundary is what this patch controls. A current live/blocked writer must never be reported as fully cleaned merely because a directory listing is empty.
