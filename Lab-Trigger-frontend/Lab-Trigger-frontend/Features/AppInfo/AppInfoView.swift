//
//  AppInfoView.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-21.
//

import SwiftUI

struct AppInfoView: View {
  @StateObject private var viewModel = AppInfoViewModel()
  @Environment(\.openURL) var openURL

  var body: some View {
    List {
      if viewModel.isLoading {
        Section {
          HStack {
            Spacer()
            ProgressView("Loading App Info...")
            Spacer()
          }
        }
      } else if let errorMessage = viewModel.errorMessage {
        Section {
          Text("Error: \(errorMessage)")
            .foregroundColor(.red)
        }
      } else if let info = viewModel.appInfo {
        Section {
          VStack(spacing: 12) {
            Image(systemName: "app.badge.fill")
              .resizable()
              .scaledToFit()
              .frame(width: 80, height: 80)
              .foregroundColor(.blue)
              .padding(.top, 20)

            Text("JobTrigger")
              .font(.title)
              .fontWeight(.bold)

            Text("Version \(info.appVersion) (Build \(info.buildNumber))")
              .font(.subheadline)
              .foregroundColor(.secondary)
              .padding(.bottom, 20)
          }
          .frame(maxWidth: .infinity)
        }
        .listRowBackground(Color.clear)

        Section(header: Text("Links")) {
          Button {
            if let url = URL(string: info.privacyPolicyUrl) {
              openURL(url)
            }
          } label: {
            Label("Privacy Policy", systemImage: "shield.lefthalf.filled")
          }

          Button {
            if let url = URL(string: info.termsOfServiceUrl) {
              openURL(url)
            }
          } label: {
            Label("Terms of Service", systemImage: "doc.text")
          }

          Button {
            if let url = URL(string: info.openSourceLicensesUrl) {
              openURL(url)
            }
          } label: {
            Label("Open Source Licenses", systemImage: "building.columns")
          }
        }

        Section(header: Text("Support")) {
          Button {
            let email = info.supportEmail
            if let url = URL(string: "mailto:\(email)") {
              openURL(url)
            }
          } label: {
            Label("Contact Support", systemImage: "envelope")
          }

          Text("For feedback or issues, please contact our support team.")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      } else {
        Section {
          Text("No information available.")
        }
      }
    }
    .navigationTitle("App Information")
    .task {
      await viewModel.fetchAppInfo()
    }
  }
}

#Preview {
  NavigationStack {
    AppInfoView()
  }
}
