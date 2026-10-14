import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/features/measure/domain/gaze_observation.dart';

void main() {
  test('filter uses seconds and resets after lost frame interval', () {
    final filter = OneEuroSignal();
    expect(filter.sample(0, 1), 0);
    expect(filter.sample(1, 1.2), inExclusiveRange(0, 1));
    expect(filter.sample(0.8, 5), 0.8);
    expect(filter.sample(0.3, 4), 0.3);
    expect(() => filter.sample(double.nan, 6), throwsArgumentError);
  });
  test('lost observations cannot count toward calibration', () {
    final calibration = GazeCalibration()..begin();
    for (var i = 0; i < 10; i++) { calibration.observe(const GazePoint(0.5, 0), i * 0.2); }
    expect(calibration.observe(null, 2), GazeState.unknown);
    expect(calibration.collected, 0);
    for (var i = 0; i < 15; i++) { calibration.observe(const GazePoint(0.5, 0), 2.2 + i * 0.2); }
    expect(calibration.observe(const GazePoint(0.5, 0), 5.2), GazeState.reference);
    expect(calibration.observe(const GazePoint(1, 0), 7), GazeState.outside);
    calibration.reset();
    expect(calibration.observe(const GazePoint(0.5, 0), 8), GazeState.uncalibrated);
  });
  test('ambiguous faces and closed eyes remain unknown', () {
    final points = List.filled(478, const GazePoint(0.5, 0.5));
    expect(eyeSignal(points, 2), isNull);
    expect(eyeSignal(points, 1), isNull);
    points[33] = const GazePoint(0.2, 0.5); points[133] = const GazePoint(0.4, 0.5);
    points[362] = const GazePoint(0.6, 0.5); points[263] = const GazePoint(0.8, 0.5);
    points[468] = const GazePoint(0.3, 0.5); points[473] = const GazePoint(0.7, 0.5);
    points[159] = const GazePoint(0.3, 0.48); points[145] = const GazePoint(0.3, 0.52);
    points[386] = const GazePoint(0.7, 0.48); points[374] = const GazePoint(0.7, 0.52);
    expect(eyeSignal(points, 1)!.x, closeTo(0.5, 0.0001));
    points[145] = points[159];
    expect(eyeSignal(points, 1), isNull);
  });
}
