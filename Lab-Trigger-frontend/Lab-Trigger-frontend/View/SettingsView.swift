//
//  SettingsView.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-07.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        ZStack {
            // 🔹 Connection Error UI
            if viewModel.showConnectionError {
                ConnectionErrorView {
                    viewModel.retryConnection()
                }
            } else {
                Form {
                    // MARK: - Server Configuration Section
                    Section(
                        header: Text("Jenkins Configuration"),
                        footer: Text(
                            "These credentials are used to authenticate to Jenkins and trigger builds. Credentials are stored locally in a JSON file."
                        )
                    ) {
                        LabeledField(title: "Server Name") {
                            TextField(
                                "My Jenkins Server",
                                text: $viewModel.serverName
                            )
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        }

                        LabeledField(title: "Jenkins URL") {
                            TextField(
                                "http://localhost:8080",
                                text: $viewModel.jenkinsURL
                            )
                            .keyboardType(.URL)
                            .textContentType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        }

                        LabeledField(title: "Username") {
                            TextField("Username", text: $viewModel.username)
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }

                        SecureToggleField(
                            title: "Password",
                            placeholder: "Password (optional)",
                            text: $viewModel.password
                        )

                        // API Token field removed

                        LabeledField(title: "Build Token") {
                            TextField(
                                "Build Token (for triggering)",
                                text: $viewModel.paramToken
                            )
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        }
                    }
                    
                    // MARK: - Connection Status Section
                    if viewModel.connectionStatus != .notTested {
                        Section(header: Text("Connection Status")) {
                            HStack {
                                ConnectionStatusIcon(status: viewModel.connectionStatus)
                                ConnectionStatusText(status: viewModel.connectionStatus)
                            }
                        }
                    }

                    // MARK: - Actions Section
                    Section {
                        // Test Connection Button
                        Button {
                            viewModel.testConnection()
                        } label: {
                            Label(
                                "Test Connection",
                                systemImage: "network"
                            )
                        }
                        .disabled(viewModel.isLoading)
                        
                        // Save with Validation Button
                        Button {
                            viewModel.saveSettings()
                        } label: {
                            Label(
                                "Save & Validate",
                                systemImage: "checkmark.shield"
                            )
                        }
                        .disabled(viewModel.isLoading)
                        
                        // Save without Validation (Dev mode)
                        Button {
                            viewModel.saveWithoutValidation()
                        } label: {
                            Label(
                                "Save Without Validation",
                                systemImage: "tray.and.arrow.down"
                            )
                        }
                        .disabled(viewModel.isLoading)
                        .foregroundColor(.orange)
                    }
                }
            }

            // 🔹 Loading Overlay
            if viewModel.isLoading {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()

                ProgressView("Please wait...")
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
        }
        .navigationTitle("Settings")
        .alert(item: $viewModel.alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
