//
//  AppConfig.swift
//  Lab-Trigger-frontend
//
//  Reads runtime configuration from Config.plist.
//  To change the backend URL, edit Config.plist — no source code change needed.
//

import Foundation

enum AppConfig {

  // MARK: - Backend Base URL

  /// The root URL of the Node.js backend, read from Config.plist at runtime.
  static let backendBaseURL: URL = {
    guard
      let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
      let dict = NSDictionary(contentsOfFile: path),
      let urlString = dict["BackendBaseURL"] as? String,
      let url = URL(string: urlString)
    else {
      fatalError("❌ Config.plist is missing or 'BackendBaseURL' is not a valid URL.")
    }
    return url
  }()
}
