// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(privacyEntitlement)
final privacyEntitlementProvider = PrivacyEntitlementProvider._();

final class PrivacyEntitlementProvider
    extends
        $FunctionalProvider<
          AsyncValue<Entitlement>,
          Entitlement,
          Stream<Entitlement>
        >
    with $FutureModifier<Entitlement>, $StreamProvider<Entitlement> {
  PrivacyEntitlementProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'privacyEntitlementProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$privacyEntitlementHash();

  @$internal
  @override
  $StreamProviderElement<Entitlement> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Entitlement> create(Ref ref) {
    return privacyEntitlement(ref);
  }
}

String _$privacyEntitlementHash() =>
    r'be63596aa6c817438141feacbfe5e5214d240fc1';

/// Corrections inside the sensitivity window (S06 `SensitivityPolicy`).

@ProviderFor(recentCorrections)
final recentCorrectionsProvider = RecentCorrectionsProvider._();

/// Corrections inside the sensitivity window (S06 `SensitivityPolicy`).

final class RecentCorrectionsProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Corrections inside the sensitivity window (S06 `SensitivityPolicy`).
  RecentCorrectionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentCorrectionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentCorrectionsHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return recentCorrections(ref);
  }
}

String _$recentCorrectionsHash() => r'a4c56e2767361229524c397f3f5bf221d3cffe55';

@ProviderFor(livePhotos)
final livePhotosProvider = LivePhotosProvider._();

final class LivePhotosProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Photo>>,
          List<Photo>,
          Stream<List<Photo>>
        >
    with $FutureModifier<List<Photo>>, $StreamProvider<List<Photo>> {
  LivePhotosProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'livePhotosProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$livePhotosHash();

  @$internal
  @override
  $StreamProviderElement<List<Photo>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Photo>> create(Ref ref) {
    return livePhotos(ref);
  }
}

String _$livePhotosHash() => r'4cef6a09cb051bb16d3cbc19fff9e9f4c7ea8d35';

@ProviderFor(privacyRequests)
final privacyRequestsProvider = PrivacyRequestsProvider._();

final class PrivacyRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReadingRequest>>,
          List<ReadingRequest>,
          Stream<List<ReadingRequest>>
        >
    with
        $FutureModifier<List<ReadingRequest>>,
        $StreamProvider<List<ReadingRequest>> {
  PrivacyRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'privacyRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$privacyRequestsHash();

  @$internal
  @override
  $StreamProviderElement<List<ReadingRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ReadingRequest>> create(Ref ref) {
    return privacyRequests(ref);
  }
}

String _$privacyRequestsHash() => r'166c47363d158100614c3a348be86f5b3c20cd84';

@ProviderFor(privacySubjects)
final privacySubjectsProvider = PrivacySubjectsProvider._();

final class PrivacySubjectsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Subject>>,
          List<Subject>,
          Stream<List<Subject>>
        >
    with $FutureModifier<List<Subject>>, $StreamProvider<List<Subject>> {
  PrivacySubjectsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'privacySubjectsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$privacySubjectsHash();

  @$internal
  @override
  $StreamProviderElement<List<Subject>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Subject>> create(Ref ref) {
    return privacySubjects(ref);
  }
}

String _$privacySubjectsHash() => r'a2c6101b11d4fefbc670ce7beb210b516ccacf5d';

@ProviderFor(photoRows)
final photoRowsProvider = PhotoRowsProvider._();

final class PhotoRowsProvider
    extends
        $FunctionalProvider<List<PhotoRow>?, List<PhotoRow>?, List<PhotoRow>?>
    with $Provider<List<PhotoRow>?> {
  PhotoRowsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoRowsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoRowsHash();

  @$internal
  @override
  $ProviderElement<List<PhotoRow>?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<PhotoRow>? create(Ref ref) {
    return photoRows(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PhotoRow>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PhotoRow>?>(value),
    );
  }
}

String _$photoRowsHash() => r'32179bd5dd8a6d20c7d9c42e13163b951cfebd97';

@ProviderFor(shareExport)
final shareExportProvider = ShareExportProvider._();

final class ShareExportProvider
    extends $FunctionalProvider<ShareExport, ShareExport, ShareExport>
    with $Provider<ShareExport> {
  ShareExportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareExportProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareExportHash();

  @$internal
  @override
  $ProviderElement<ShareExport> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ShareExport create(Ref ref) {
    return shareExport(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareExport value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareExport>(value),
    );
  }
}

String _$shareExportHash() => r'3edf7d72b251b647bcfeb1b125febcae019ea39f';

/// Rebuilt when the account (write context) changes; the old instance is
/// disposed so its in-flight work stops.

@ProviderFor(privacyActions)
final privacyActionsProvider = PrivacyActionsProvider._();

/// Rebuilt when the account (write context) changes; the old instance is
/// disposed so its in-flight work stops.

final class PrivacyActionsProvider
    extends $FunctionalProvider<PrivacyActions, PrivacyActions, PrivacyActions>
    with $Provider<PrivacyActions> {
  /// Rebuilt when the account (write context) changes; the old instance is
  /// disposed so its in-flight work stops.
  PrivacyActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'privacyActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$privacyActionsHash();

  @$internal
  @override
  $ProviderElement<PrivacyActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PrivacyActions create(Ref ref) {
    return privacyActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PrivacyActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PrivacyActions>(value),
    );
  }
}

String _$privacyActionsHash() => r'fcff805d1e86969368a2c1f7dd613925b3ea2cdb';
