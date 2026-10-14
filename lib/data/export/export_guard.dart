/// Revalidated before preparing a file and immediately before OS handoff.
/// The synchronous check closes the gap after the final database read.
class ExportGuard {
  ExportGuard({required this.validate, required this.isCurrent});

  final Future<void> Function() validate;
  final bool Function() isCurrent;

  void checkNow() {
    if (!isCurrent()) throw StateError('export cancelled');
  }

  Future<void> check() async {
    checkNow();
    await validate();
    checkNow();
  }
}
