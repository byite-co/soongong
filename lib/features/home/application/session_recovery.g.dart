// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_recovery.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionRecoveryHandler)
final sessionRecoveryHandlerProvider = SessionRecoveryHandlerProvider._();

final class SessionRecoveryHandlerProvider
    extends
        $FunctionalProvider<
          SessionRecoveryHandler,
          SessionRecoveryHandler,
          SessionRecoveryHandler
        >
    with $Provider<SessionRecoveryHandler> {
  SessionRecoveryHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionRecoveryHandlerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionRecoveryHandlerHash();

  @$internal
  @override
  $ProviderElement<SessionRecoveryHandler> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SessionRecoveryHandler create(Ref ref) {
    return sessionRecoveryHandler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionRecoveryHandler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionRecoveryHandler>(value),
    );
  }
}

String _$sessionRecoveryHandlerHash() =>
    r'afd3332d014c4d2e77a44f811cbee051e04f5325';

/// Asked once per app run; a dismissed sheet is not re-shown until the next
/// launch (prototype: "다음 실행 때 다시 묻습니다").

@ProviderFor(RecoveryPrompted)
final recoveryPromptedProvider = RecoveryPromptedProvider._();

/// Asked once per app run; a dismissed sheet is not re-shown until the next
/// launch (prototype: "다음 실행 때 다시 묻습니다").
final class RecoveryPromptedProvider
    extends $NotifierProvider<RecoveryPrompted, bool> {
  /// Asked once per app run; a dismissed sheet is not re-shown until the next
  /// launch (prototype: "다음 실행 때 다시 묻습니다").
  RecoveryPromptedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recoveryPromptedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recoveryPromptedHash();

  @$internal
  @override
  RecoveryPrompted create() => RecoveryPrompted();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$recoveryPromptedHash() => r'29400ae3e9d54890619d3d44a1c0532c7ff06b56';

/// Asked once per app run; a dismissed sheet is not re-shown until the next
/// launch (prototype: "다음 실행 때 다시 묻습니다").

abstract class _$RecoveryPrompted extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
