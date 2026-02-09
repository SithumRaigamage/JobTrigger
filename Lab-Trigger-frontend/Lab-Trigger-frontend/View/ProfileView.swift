//
//  ProfileView.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-09.
//

import SwiftUI

struct ProfileView: View {
  @StateObject private var viewModel = ProfileViewModel()

  var body: some View {
    List {
      // MARK: - Header Section
      Section {
        VStack(spacing: 16) {
          Image(systemName: "person.crop.circle.fill")
            .font(.system(size: 80))
            .foregroundColor(.blue)
            .padding(.top, 10)

          VStack(spacing: 4) {
            Text(viewModel.userEmail)
              .font(.headline)
            Text("Active User")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
      }
      .listRowBackground(Color.clear)

      // MARK: - Session Section
      Section(header: Text("Current Session")) {
        HStack {
          Label("Active Server", systemImage: "server.rack")
          Spacer()
          Text(viewModel.activeServerName)
            .foregroundColor(.secondary)
        }

        HStack {
          Label("Server URL", systemImage: "link")
          Spacer()
          Text(viewModel.activeServerURL)
            .foregroundColor(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
        }

        HStack {
          Label("Saved Servers", systemImage: "folder")
          Spacer()
          Text("\(viewModel.totalServersCount)")
            .foregroundColor(.secondary)
        }
      }

      // MARK: - Security Section
      Section(header: Text("User Management")) {
        NavigationLink {
          Text("Change Password feature coming soon...")
            .navigationTitle("Change Password")
        } label: {
          Label("Change Password", systemImage: "lock")
        }

        NavigationLink {
          Text("Session security settings...")
            .navigationTitle("Security")
        } label: {
          Label("Security Settings", systemImage: "shield")
        }
      }

      // MARK: - App Info Section
      Section(header: Text("App Information")) {
        HStack {
          Label("Version", systemImage: "info.circle")
          Spacer()
          Text(viewModel.appVersion)
            .foregroundColor(.secondary)
        }

        NavigationLink {
          Text("JobTrigger License Info...")
            .navigationTitle("Licenses")
        } label: {
          Label("Licenses", systemImage: "doc.text")
        }
      }

      // MARK: - Actions Section
      Section {
        Button(role: .destructive) {
          viewModel.signOut()
        } label: {
          HStack {
            Spacer()
            Text("Log Out")
              .fontWeight(.semibold)
            Spacer()
          }
        }
      }
    }
    .navigationTitle("Profile")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    ProfileView()
  }
}
