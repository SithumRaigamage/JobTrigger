//
//  SettingsView.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-07.
//

import SwiftUI

struct SettingsView: View {

    // MARK: - UI State
    @State private var jenkinsURL = ""
    @State private var username = ""
    @State private var password = ""
    @State private var apiToken = ""
    @State private var paramToken = ""

    @State private var showPassword = false
    @State private var showToken = false
    @State private var isLoading = false
    @State private var showConnectionError = false
    @State private var statusMessage = ""

    var body: some View {
        ZStack {

            // 🔹 Connection Error UI
            if showConnectionError {
                VStack(spacing: 20) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("Connection Failed")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Unable to reach the backend server.\nPlease ensure the server is running.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Retry Connection") {
                        // UI only
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()

            } else {

                // 🔹 Main Form
                Form {

                    // Jenkins Config
                    Section(
                        header: Text("Jenkins Configuration"),
                        footer: Text("These credentials are used to authenticate to Jenkins and trigger builds.")
                    ) {

                        LabeledField(title: "Jenkins URL") {
                            TextField("http://localhost:8080", text: $jenkinsURL)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                        }

                        LabeledField(title: "Username") {
                            TextField("Username", text: $username)
                                .autocapitalization(.none)
                        }

                        LabeledField(title: "Password") {
                            HStack {
                                if showPassword {
                                    TextField("Password", text: $password)
                                } else {
                                    SecureField("Password", text: $password)
                                }

                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                }
                            }
                        }

                        LabeledField(title: "API Token") {
                            HStack {
                                if showToken {
                                    TextField("API Token", text: $apiToken)
                                } else {
                                    SecureField("API Token", text: $apiToken)
                                }

                                Button {
                                    showToken.toggle()
                                } label: {
                                    Image(systemName: showToken ? "eye.slash" : "eye")
                                }
                            }
                        }

                        LabeledField(title: "Param Token") {
                            TextField("Param Token", text: $paramToken)
                                .autocapitalization(.none)
                        }
                    }

                    // Actions
                    Section {
                        Button {
                            statusMessage = "Settings saved successfully."
                        } label: {
                            Label("Save Settings", systemImage: "tray.and.arrow.down")
                        }

                        Button(role: .destructive) {
                            statusMessage = "Settings deleted."
                        } label: {
                            Label("Delete Settings", systemImage: "trash")
                        }
                    }

                    // Status Message
                    if !statusMessage.isEmpty {
                        Section {
                            Text(statusMessage)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // 🔹 Loading Overlay
            if isLoading {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()

                ProgressView("Please wait...")
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
        }
        .navigationTitle("Settings")
    }
}

struct LabeledField<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            content
        }
    }
}

    
#Preview {
    SettingsView()
}
