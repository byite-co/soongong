import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../temp/owned_temp_store.dart';
import '../temp/temp_providers.dart';
import 'study_image_picker.dart';

enum PickerRecoveryState { none, reselect, unavailable }

class OwnedPickerCoordinator {
  OwnedPickerCoordinator({
    required this.store,
    this.channel = const MethodChannel('co.byite.soongong/picker_owner'),
    ImagePicker? picker,
    bool? android,
  }) : picker = picker ?? ImagePicker(),
       android = android ?? Platform.isAndroid {
    store.recoveryReady = () => _recovered;
    store.beforeDelete = (scope, task, revoke) async {
      final state = await channel
          .invokeMapMethod<String, dynamic>(revoke ? 'cancel' : 'status', {
            'scope': scope,
            'task': task,
          })
          .timeout(const Duration(seconds: 5));
      if (state == null || state['unknown'] != false)
        throw const TempStoreUnavailable();
      return state['active'] == false;
    };
  }
  final OwnedTempStore store;
  final MethodChannel channel;
  final ImagePicker picker;
  final bool android;
  Future<PickerRecoveryState>? _recovery;
  bool _picking = false;
  bool _recovered = false;
  PickerRecoveryState state = PickerRecoveryState.none;

  Future<PickerRecoveryState> recover() =>
      _recovery ??= _recover().then((result) {
        state = result;
        if (result == PickerRecoveryState.unavailable) _recovery = null;
        return result;
      });

  Future<PickerRecoveryState> _recover() async {
    try {
      // Single consumer. Never read/restore/send/save recovered bytes. The
      // owned-root scan also covers creation before lost-data registration.
      var found = false;
      if (android)
        found = !(await picker.retrieveLostData().timeout(
          const Duration(seconds: 5),
        )).isEmpty;
      final native = await channel
          .invokeMapMethod<String, dynamic>('recover')
          .timeout(const Duration(seconds: 5));
      if (native == null ||
          native['unknown'] != false ||
          native['active'] != false) {
        return PickerRecoveryState.unavailable;
      }
      _recovered = true;
      if (!(await store.sweep()).complete) {
        return PickerRecoveryState.unavailable;
      }
      return found ? PickerRecoveryState.reselect : PickerRecoveryState.none;
    } on Object {
      return PickerRecoveryState.unavailable;
    }
  }

  Future<StudyPickedImage?> pick(
    ImageSource source, {
    required Future<OwnedTempTask> Function() createTask,
  }) async {
    if (_picking) throw StateError('picker busy');
    if (await recover() == PickerRecoveryState.unavailable) {
      throw const TempStoreUnavailable();
    }
    if (_picking) throw StateError('picker busy');
    _picking = true;
    OwnedTempTask? task;
    var returning = false;
    try {
      task = await createTask();
      task.check();
      await channel.invokeMethod<void>('prepare', task.nativeArguments);
      task.check();
      XFile? file;
      try {
        file = await picker.pickImage(
          source: source,
          requestFullMetadata: false,
        );
      } finally {
        await channel.invokeMethod<void>('release', task.nativeArguments);
      }
      task.check();
      if (file == null) return null;
      if (!task.owns(file.path)) throw const TempStoreUnavailable();
      returning = true;
      return _OwnedPickedImage(file, task);
    } finally {
      _picking = false;
      if (task != null && !returning && !(await task.cleanup()).complete) {
        throw const TempStoreUnavailable();
      }
    }
  }
}

class _OwnedPickedImage implements StudyPickedImage {
  _OwnedPickedImage(this.file, this.task);
  final XFile file;
  final OwnedTempTask task;
  @override
  Future<int> length() async {
    task.check();
    return file.length();
  }

  @override
  Future<Uint8List> readAsBytes() async {
    task.check();
    final bytes = await file.readAsBytes();
    try {
      task.check();
    } on Object {
      bytes.fillRange(0, bytes.length, 0);
      rethrow;
    }
    return bytes;
  }

  @override
  Future<void> cleanup() async {
    if (!(await task.cleanup()).complete) throw const TempStoreUnavailable();
  }
}

final ownedPickerCoordinatorProvider = Provider<OwnedPickerCoordinator>(
  (ref) => OwnedPickerCoordinator(store: ref.watch(ownedTempStoreProvider)),
);
