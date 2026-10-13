/// Serializes camera ownership across measurement, gaze and availability
/// probes. A timeout is not proof of native release: uncertainty is sticky
/// for this app process, even if the abandoned Future eventually completes.
class CameraLease {
  static final CameraLease shared = CameraLease();

  Object? _owner;
  bool _failed = false;
  bool get failed => _failed;
  bool get unavailable => _failed || _owner != null;

  Object? acquire() {
    if (unavailable) return null;
    return _owner = Object();
  }

  void fail(Object token) {
    if (identical(_owner, token)) _failed = true;
  }

  void release(Object token) {
    if (identical(_owner, token) && !_failed) _owner = null;
  }
}
