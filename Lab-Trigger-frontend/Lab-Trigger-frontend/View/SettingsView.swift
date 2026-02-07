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
                    Section(
                        header: Text("Jenkins Configuration"),
                        footer: Text(
                            "These credentials are used to authenticate to Jenkins and trigger builds."
                        )
                    ) {

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
                            placeholder: "Password",
                            text: $viewModel.password
                        )

                        SecureToggleField(
                            title: "API Token",
                            placeholder: "API Token",
                            text: $viewModel.apiToken
                        )

                        LabeledField(title: "Param Token") {
                            TextField(
                                "Param Token",
                                text: $viewModel.paramToken
                            )
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        }
                    }

                    Section {
                        Button {
                            viewModel.saveSettings()
                        } label: {
                            Label(
                                "Save Settings",
                                systemImage: "tray.and.arrow.down"
                            )
                        }

                        Button(role: .destructive) {
                            viewModel.deleteSettings()
                        } label: {
                            Label("Delete Settings", systemImage: "trash")
                        }
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
    SettingsView()
}
