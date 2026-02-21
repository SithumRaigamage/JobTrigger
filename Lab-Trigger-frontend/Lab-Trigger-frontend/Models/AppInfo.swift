//
//  AppInfo.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-21.
//

import Foundation

struct AppInfo: Codable, Identifiable {
  var id: String { _id ?? UUID().uuidString }

  let _id: String?
  let appVersion: String
  let buildNumber: String
  let privacyPolicyUrl: String
  let termsOfServiceUrl: String
  let supportEmail: String
  let openSourceLicensesUrl: String
  let createdAt: Date?
  let updatedAt: Date?
}
