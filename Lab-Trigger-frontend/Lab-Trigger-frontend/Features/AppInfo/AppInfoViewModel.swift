//
//  AppInfoViewModel.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-21.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AppInfoViewModel: ObservableObject {
  @Published var appInfo: AppInfo?
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let backendClient = BackendClient.shared

  func fetchAppInfo() async {
    isLoading = true
    errorMessage = nil

    do {
      let info: AppInfo = try await backendClient.request(APIConfig.appInfo, requiresAuth: false)
      self.appInfo = info
    } catch {
      print("❌ [AppInfoViewModel] Error fetching app info: \(error)")
      self.errorMessage = error.localizedDescription
    }

    isLoading = false
  }
}
