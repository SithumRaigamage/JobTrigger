//
//  SettingsViewModel.swift
//  Lab-Trigger-frontend
//
//  Created by Thamindu Dasanayake on 2026-02-08.
//

import Foundation
import Combine

final class SettingsViewModel: ObservableObject {

    // MARK: - Form Data
    @Published var jenkinsURL = ""
    @Published var username = ""
    @Published var password = ""
    @Published var apiToken = ""
    @Published var paramToken = ""

    // MARK: - UI State
    @Published var isLoading = false
    @Published var showConnectionError = false
    @Published var alert: SettingsAlert?

    // MARK: - Actions
    func saveSettings() {
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            self.alert = .success
        }
    }

    func deleteSettings() {
        alert = .deleted
    }

    func retryConnection() {
        showConnectionError = false
    }
}
