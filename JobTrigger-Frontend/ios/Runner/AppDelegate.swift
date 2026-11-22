import Flutter
import PDFKit
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // US-JX-10: show build notifications while the app is in the foreground
    // and route taps back into Flutter (flutter_local_notifications).
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    // The background watch check runs in a headless engine; it needs the same
    // plugins (secure storage, prefs, notifications) as the app.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "JobTriggerPdfPageRenderer") {
      PdfPageRenderer.register(with: registrar.messenger())
    }
  }
}

/// US-STU-02: draws a PDF's pages to PNGs in memory for the super admin's
/// review screen (`lib/core/platform/pdf_page_renderer.dart`). The PDF comes
/// in as bytes and the pages go back as bytes; nothing is written to disk.
enum PdfPageRenderer {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "jobtrigger/pdf", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "renderPages" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let bytes = args["bytes"] as? FlutterStandardTypedData
      else {
        result(FlutterError(code: "bad_args", message: nil, details: nil))
        return
      }
      let maxPages = args["maxPages"] as? Int ?? 10
      let width = CGFloat(args["width"] as? Int ?? 1200)
      DispatchQueue.global(qos: .userInitiated).async {
        let pages = render(bytes.data, maxPages: maxPages, width: width)
        DispatchQueue.main.async {
          if let pages = pages {
            result(pages.map { FlutterStandardTypedData(bytes: $0) })
          } else {
            result(FlutterError(code: "unreadable", message: nil, details: nil))
          }
        }
      }
    }
  }

  private static func render(_ data: Data, maxPages: Int, width: CGFloat) -> [Data]? {
    guard let document = PDFDocument(data: data), document.pageCount > 0 else { return nil }
    var pages: [Data] = []
    for index in 0..<min(document.pageCount, max(1, maxPages)) {
      guard let page = document.page(at: index) else { continue }
      let bounds = page.bounds(for: .mediaBox)
      guard bounds.width > 0, bounds.height > 0 else { continue }
      // Rotated pages are wider than tall once drawn; thumbnail handles that.
      let rotated = page.rotation % 180 != 0
      let (w, h) = rotated ? (bounds.height, bounds.width) : (bounds.width, bounds.height)
      let size = CGSize(width: width, height: width * h / w)
      if let png = page.thumbnail(of: size, for: .mediaBox).pngData() { pages.append(png) }
    }
    return pages.isEmpty ? nil : pages
  }
}
