// ProfileCache (S05b): the last profile the server confirmed for the account
// this database is bound to, kept in `sync_meta` so an offline restart with
// a stored session can still reach the app. Only facts the router needs
// (onboarding_done · consent versions · verified_at); never a birth date.
// Cleared with the database on an account switch (`AccountBinding`).

import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../db/app_database.dart';
import '../repositories/repository_providers.dart';
import 'auth_models.dart';

part 'profile_cache.g.dart';

class CachedProfile {
  const CachedProfile({
    required this.userId,
    required this.onboardingDone,
    required this.verifiedAt,
    this.consentAccountVersion,
    this.consentReadingVersion,
    this.consentReadingActive = false,
    this.purgeEpoch = 0,
  });

  factory CachedProfile.fromSnapshot(ProfileSnapshot p, DateTime verifiedAt) => CachedProfile(
        userId: p.userId,
        onboardingDone: p.onboardingDone,
        verifiedAt: verifiedAt.toUtc(),
        consentAccountVersion: p.consentAccountVersion,
        consentReadingVersion: p.consentReadingVersion,
        consentReadingActive: p.readingConsentActive,
        purgeEpoch: p.purgeEpoch,
      );

  factory CachedProfile.fromJson(Map<String, dynamic> json) => CachedProfile(
        userId: json['user_id'] as String,
        onboardingDone: json['onboarding_done'] == true,
        verifiedAt: DateTime.parse(json['verified_at'] as String).toUtc(),
        consentAccountVersion: json['consent_account_version'] as String?,
        consentReadingVersion: json['consent_reading_version'] as String?,
        consentReadingActive: json['consent_reading_active'] == true,
        purgeEpoch: (json['purge_epoch'] as num?)?.toInt() ?? 0,
      );

  final String userId;
  final bool onboardingDone;
  final DateTime verifiedAt;
  final String? consentAccountVersion;
  final String? consentReadingVersion;
  final bool consentReadingActive;
  final int purgeEpoch;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'user_id': userId,
        'onboarding_done': onboardingDone,
        'verified_at': verifiedAt.toUtc().toIso8601String(),
        'consent_account_version': consentAccountVersion,
        'consent_reading_version': consentReadingVersion,
        'consent_reading_active': consentReadingActive,
        'purge_epoch': purgeEpoch,
      };

  /// What the router needs, as a snapshot. Timestamps are the verification
  /// time (the cache does not keep the originals).
  ProfileSnapshot toSnapshot() => ProfileSnapshot(
        userId: userId,
        onboardingDone: onboardingDone,
        purgeEpoch: purgeEpoch,
        consentAccountVersion: consentAccountVersion,
        consentAccountAt: consentAccountVersion == null ? null : verifiedAt,
        consentReadingVersion: consentReadingVersion,
        consentReadingAt: consentReadingActive ? verifiedAt : null,
      );
}

class ProfileCache {
  ProfileCache(this._db);

  final AppDatabase _db;

  static const String key = 'profile_cache';

  Future<CachedProfile?> read() async {
    final row = await (_db.select(_db.syncMeta)..where((m) => m.key.equals(key))).getSingleOrNull();
    if (row == null) return null;
    try {
      return CachedProfile.fromJson(Map<String, dynamic>.from(jsonDecode(row.value) as Map));
    } on Object {
      return null;
    }
  }

  Future<void> write(ProfileSnapshot profile, {required DateTime verifiedAt}) =>
      _db.into(_db.syncMeta).insertOnConflictUpdate(
            SyncMetaCompanion.insert(
              key: key,
              value: jsonEncode(CachedProfile.fromSnapshot(profile, verifiedAt).toJson()),
            ),
          );

  Future<void> clear() => (_db.delete(_db.syncMeta)..where((m) => m.key.equals(key))).go();
}

@Riverpod(keepAlive: true)
ProfileCache profileCache(Ref ref) => ProfileCache(ref.watch(appDatabaseProvider));
