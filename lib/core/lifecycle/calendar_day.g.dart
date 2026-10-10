// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_day.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalendarDay)
final calendarDayProvider = CalendarDayProvider._();

final class CalendarDayProvider
    extends $NotifierProvider<CalendarDay, LocalDate> {
  CalendarDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarDayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarDayHash();

  @$internal
  @override
  CalendarDay create() => CalendarDay();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalDate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalDate>(value),
    );
  }
}

String _$calendarDayHash() => r'5dd2a070ad503b41b1bbf9274ddf2be16a385818';

abstract class _$CalendarDay extends $Notifier<LocalDate> {
  LocalDate build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LocalDate, LocalDate>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LocalDate, LocalDate>,
              LocalDate,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
