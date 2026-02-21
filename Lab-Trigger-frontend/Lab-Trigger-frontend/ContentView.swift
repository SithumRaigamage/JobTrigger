//
//  ContentView.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-07.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var authManager = AuthenticationManager.shared
  @AppStorage("appTheme") private var storedTheme: Int = AppTheme.system.rawValue

  var body: some View {
    Group {
      if authManager.isAuthenticated {
        NavBarView()
      } else {
        LoginView()
      }
    }
    .notificationManager()
    .preferredColorScheme(AppTheme(rawValue: storedTheme)?.colorScheme)
  }
}

#Preview {
  ContentView()
}
