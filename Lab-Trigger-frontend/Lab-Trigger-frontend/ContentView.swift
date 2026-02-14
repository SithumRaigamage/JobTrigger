//
//  ContentView.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-07.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var authManager = AuthenticationManager.shared

  var body: some View {
    Group {
      if authManager.isAuthenticated {
        NavBarView()
      } else {
        LoginView()
      }
    }
    .notificationManager()
  }
}

#Preview {
  ContentView()
}
