//
//  HomeView.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-07.
//

import SwiftUI

struct HomeView: View {
  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "bolt.fill")
        .font(.system(size: 80))
        .foregroundColor(.blue)

      Text("Welcome to Job Trigger")
        .font(.title)
        .fontWeight(.bold)

      Text("Manage your Jenkins builds with ease.")
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
    .onAppear {
      checkConnectivity()
    }
  }

  private func checkConnectivity() {
    Task {
      do {
        // Simple health check or ping
        let _: EmptyResponse = try await BackendClient.shared.request(
          APIConfig.rootURL, requiresAuth: false)
      } catch {
        NotificationManager.shared.show(
          type: .warning,
          title: "Offline Mode",
          message: "Could not connect to the backend server. Some features may be unavailable."
        )
      }
    }
  }
}

#Preview {
  HomeView()
}
