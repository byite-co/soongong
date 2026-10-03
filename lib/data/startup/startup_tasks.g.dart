// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'startup_tasks.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(userStartupTasks)
final userStartupTasksProvider = UserStartupTasksProvider._();

final class UserStartupTasksProvider
    extends
        $FunctionalProvider<
          UserStartupTasks,
          UserStartupTasks,
          UserStartupTasks
        >
    with $Provider<UserStartupTasks> {
  UserStartupTasksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userStartupTasksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userStartupTasksHash();

  @$internal
  @override
  $ProviderElement<UserStartupTasks> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserStartupTasks create(Ref ref) {
    return userStartupTasks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserStartupTasks value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserStartupTasks>(value),
    );
  }
}

String _$userStartupTasksHash() => r'456dc6897991af7bffdb541258749db66e6d1460';
