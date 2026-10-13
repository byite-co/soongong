import Flutter
import UIKit
import UniformTypeIdentifiers
import image_picker_ios

/// Direct file URL handoff. The app does not make a second share cache copy.
final class OwnedShareBridge {
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "co.byite.soongong/owned_share", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "share" else { result(FlutterMethodNotImplemented); return }
      let failed = { result(FlutterError(code: "owned_share_unavailable", message: nil, details: nil)) }
      guard let args = call.arguments as? [String: Any],
        let scope = args["scope"] as? String, let task = args["task"] as? String,
        let name = args["name"] as? String, let mime = args["mimeType"] as? String else { failed(); return }
      let relative = args["relativeName"] as? String ?? "attachment"
      guard relative.range(of: #"^attachment(?:\.(?:json|csv|zip|txt))?$"#, options: .regularExpression) != nil,
        !name.isEmpty, name.count <= 120, name != ".", name != "..",
        !name.contains("/"), !name.contains("\\"), name.rangeOfCharacter(from: .controlCharacters) == nil,
        ["application/json", "text/csv", "application/zip", "text/plain"].contains(mime),
        let payload = FIPOwnedImageStore.payload(scope: scope, task: task, kind: "export") else { failed(); return }
      let url = URL(fileURLWithPath: payload).appendingPathComponent(relative)
      guard url.path == url.resolvingSymlinksInPath().path,
        let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey]),
        values.isRegularFile == true, values.isSymbolicLink == false else { failed(); return }
      guard var controller = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
        .flatMap({ $0.windows }).first(where: { $0.isKeyWindow })?.rootViewController else { failed(); return }
      while let presented = controller.presentedViewController { controller = presented }
      guard FIPOwnedImageStore.payload(scope: scope, task: task, kind: "export") != nil else { failed(); return }
      let attachment = FIPOwnedShareAttachment(scope: scope, task: task, relativeName: relative)
      let sheet = UIActivityViewController(activityItems: [OwnedShareItem(attachment: attachment, name: name, mime: mime)], applicationActivities: nil)
      if let popover = sheet.popoverPresentationController {
        popover.sourceView = controller.view
        popover.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 1, height: 1)
        popover.permittedArrowDirections = []
      }
      controller.present(sheet, animated: true)
      // Presentation is an OS handoff attempt, not proof that a recipient read the file.
      result("handedOff")
    }
  }
}

private final class OwnedShareItem: NSObject, UIActivityItemSource {
  let attachment: FIPOwnedShareAttachment
  let name: String
  let mime: String
  init(attachment: FIPOwnedShareAttachment, name: String, mime: String) { self.attachment = attachment; self.name = name; self.mime = mime }
  func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any { attachment.url as Any? ?? name }
  func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? { attachment.url }
  func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String { name }
  func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String { UTType(mimeType: mime)?.identifier ?? UTType.data.identifier }
}
