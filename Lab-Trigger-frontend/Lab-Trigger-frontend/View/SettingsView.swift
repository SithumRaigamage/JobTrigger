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
          // MARK: - Servers List Section
          Section(header: Text("Jenkins Servers")) {
            if viewModel.allServers.isEmpty {
              Text("No servers added yet.")
                .foregroundColor(.secondary)
            } else {
              ForEach(viewModel.allServers, id: \.id) { server in
                HStack {
                  VStack(alignment: .leading) {
                    Text(server.serverName)
                      .fontWeight(.medium)
                    Text(server.jenkinsURL)
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }

                  Spacer()

                  if server.isDefault {
                    Text("Active")
                      .font(.caption)
                      .padding(6)
                      .background(Color.green.opacity(0.15))
                      .cornerRadius(6)
                  }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                  viewModel.selectServer(server)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                  Button(role: .destructive) {
                    Task {
                      await viewModel.deleteServer(server)
                    }
                  } label: {
                    Label("Delete", systemImage: "trash")
                  }

                  Button {
                    Task {
                      await viewModel.switchActiveServer(server)
                    }
                  } label: {
                    Label("Set Active", systemImage: "star")
                  }
                  .tint(.yellow)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                  Button {
                    // Edit
                    viewModel.selectServer(server)
                    viewModel.isEditing = true
                    viewModel.isPresentingAddEditSheet = true
                  } label: {
                    Label("Edit", systemImage: "pencil")
                  }
                }
              }
            }

            Button {
              // Prepare for adding a new server
              viewModel.currentCredentialID = nil
              viewModel.serverName = ""
              viewModel.jenkinsURL = ""
              viewModel.username = ""
              viewModel.password = ""
              viewModel.paramToken = ""
              viewModel.isEditing = false
              viewModel.isPresentingAddEditSheet = true
            } label: {
              Label("Add Jenkins Server", systemImage: "plus")
            }
          }

          // MARK: - Backend Status Section
          Section {
            HStack {
              Label(
                "Backend Server", systemImage: viewModel.isBackendConnected ? "wifi" : "wifi.slash")
              Spacer()
              Text(viewModel.isBackendConnected ? "Connected" : "Offline")
                .foregroundColor(viewModel.isBackendConnected ? .green : .red)
                .fontWeight(.medium)
            }

            if !viewModel.isBackendConnected {
              HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                  .foregroundColor(.orange)
                Text("Backend is unreachable. Please start the server to manage configurations.")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
              }
            }
          } header: {
            Text("Connection Status")
          }

          if viewModel.isBackendConnected {
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

              LabeledField(title: "Build Token") {
                TextField(
                  "Build Token (for triggering)",
                  text: $viewModel.paramToken
                )
                .autocapitalization(.none)
                .disableAutocorrection(true)
              }
            }
          }

          // MARK: - Connection Status Section
          if viewModel.isBackendConnected && viewModel.connectionStatus != .notTested {
            Section(header: Text("Jenkins Connection Status")) {
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
                "Test Jenkins Connection",
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
    .onAppear {
      Task {
        await viewModel.loadExistingCredentials()
        await viewModel.loadAllServers()
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
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(role: .destructive) {
          AuthenticationManager.shared.signOut()
        } label: {
          Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
        }
      }
    }
    // Add/Edit sheet for servers
    .sheet(isPresented: $viewModel.isPresentingAddEditSheet) {
      NavigationStack {
        Form {
          LabeledField(title: "Server Name") {
            TextField("My Jenkins Server", text: $viewModel.serverName)
              .autocapitalization(.none)
              .disableAutocorrection(true)
          }

          LabeledField(title: "Jenkins URL") {
            TextField("http://localhost:8080", text: $viewModel.jenkinsURL)
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

          LabeledField(title: "Build Token") {
            TextField("Build Token (for triggering)", text: $viewModel.paramToken)
              .autocapitalization(.none)
              .disableAutocorrection(true)
          }
        }
        .navigationTitle(viewModel.isEditing ? "Edit Server" : "Add Server")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              viewModel.isPresentingAddEditSheet = false
            }
          }

          ToolbarItem(placement: .confirmationAction) {
            Button(viewModel.isEditing ? "Save" : "Add") {
              Task {
                await viewModel.saveServer(isDefault: false)
              }
            }
          }
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    SettingsView()
  }
}
