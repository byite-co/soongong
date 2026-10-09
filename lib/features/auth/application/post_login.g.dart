// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_login.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One-shot message the next screen shows as a toast (home reads it once).

@ProviderFor(PendingToast)
final pendingToastProvider = PendingToastProvider._();

/// One-shot message the next screen shows as a toast (home reads it once).
final class PendingToastProvider
    extends $NotifierProvider<PendingToast, String?> {
  /// One-shot message the next screen shows as a toast (home reads it once).
  PendingToastProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingToastProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingToastHash();

  @$internal
  @override
  PendingToast create() => PendingToast();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$pendingToastHash() => r'db39b3f655064497bff527363350ee7c29b80078';

/// One-shot message the next screen shows as a toast (home reads it once).

abstract class _$PendingToast extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(postLoginRoutine)
final postLoginRoutineProvider = PostLoginRoutineProvider._();

final class PostLoginRoutineProvider
    extends
        $FunctionalProvider<
          PostLoginRoutine,
          PostLoginRoutine,
          PostLoginRoutine
        >
    with $Provider<PostLoginRoutine> {
  PostLoginRoutineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postLoginRoutineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postLoginRoutineHash();

  @$internal
  @override
  $ProviderElement<PostLoginRoutine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PostLoginRoutine create(Ref ref) {
    return postLoginRoutine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostLoginRoutine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostLoginRoutine>(value),
    );
  }
}

String _$postLoginRoutineHash() => r'5b8824a8cee09825b902caf70f4e9bac5eada534';
