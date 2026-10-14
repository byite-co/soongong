import Flutter
import UIKit
import CoreVideo
import MediaPipeTasksVision

final class GazeBridge {
  private let channel: FlutterMethodChannel
  private let queue = DispatchQueue(label: "co.byite.soongong.gaze")
  private var engine: FaceLandmarker?
  private var run: String?
  private var lastTime = -1

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "co.byite.soongong/gaze", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, reply in
      guard let self = self else { reply(FlutterError(code: "gaze_closed", message: nil, details: nil)); return }
      self.queue.async {
        do {
          guard let args = call.arguments as? [String: Any], let requested = args["run"] as? String else { throw BridgeError.invalid }
          var output: Any?
          switch call.method {
          case "open":
            self.engine = nil; self.run = nil
            let asset = FlutterDartProject.lookupKey(forAsset: "assets/models/face_landmarker.task")
            guard let path = Bundle.main.path(forResource: asset, ofType: nil) else { throw BridgeError.invalid }
            let options = FaceLandmarkerOptions()
            options.baseOptions.modelAssetPath = path
            options.runningMode = .video
            options.numFaces = 2
            self.engine = try FaceLandmarker(options: options)
            self.run = requested; self.lastTime = -1
          case "close":
            if self.run == requested { self.engine = nil; self.run = nil }
          case "frame":
            guard self.run == requested, let engine = self.engine,
              let time = args["time"] as? Int, time > self.lastTime,
              let w = args["width"] as? Int, let h = args["height"] as? Int,
              let stride = args["stride"] as? Int, let rotation = args["rotation"] as? Int,
              let bytes = args["bytes"] as? FlutterStandardTypedData,
              w > 0, h > 0, w <= 2000, h <= 2000, w * h <= 2000000,
              stride >= w * 4, stride <= w * 4 + 1024, bytes.data.count == stride * h
            else { throw BridgeError.invalid }
            self.lastTime = time
            let orientation: UIImage.Orientation
            switch rotation { case 0: orientation = .up; case 90: orientation = .right
              case 180: orientation = .down; case 270: orientation = .left
              default: throw BridgeError.invalid }
            var pixelBuffer: CVPixelBuffer?
            guard CVPixelBufferCreate(kCFAllocatorDefault, w, h, kCVPixelFormatType_32BGRA, nil, &pixelBuffer) == kCVReturnSuccess,
              let buffer = pixelBuffer else { throw BridgeError.invalid }
            CVPixelBufferLockBaseAddress(buffer, [])
            defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
            guard let base = CVPixelBufferGetBaseAddress(buffer) else { throw BridgeError.invalid }
            bytes.data.withUnsafeBytes { source in
              for row in 0..<h { memcpy(base.advanced(by: row * CVPixelBufferGetBytesPerRow(buffer)), source.baseAddress!.advanced(by: row * stride), w * 4) }
            }
            let image = try MPImage(pixelBuffer: buffer, orientation: orientation)
            let faces = try engine.detect(videoFrame: image, timestampInMilliseconds: time).faceLandmarks
            output = ["run": requested, "time": time, "faces": faces.count,
              "points": faces.count == 1 ? faces[0].map { [Double($0.x), Double($0.y)] } : []]
          default: throw BridgeError.invalid
          }
          DispatchQueue.main.async { reply(output) }
        } catch {
          DispatchQueue.main.async { reply(FlutterError(code: "gaze_unavailable", message: "On-device gaze unavailable", details: nil)) }
        }
      }
    }
  }
  private enum BridgeError: Error { case invalid }
}
