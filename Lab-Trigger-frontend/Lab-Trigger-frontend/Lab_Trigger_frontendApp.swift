//
//  Lab_Trigger_frontendApp.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-07.
//

import SwiftUI

@main
struct Lab_Trigger_frontendApp: App {
  @AppStorage("appTheme") private var storedTheme: Int = AppTheme.system.rawValue

  var body: some Scene {
    WindowGroup {
      ContentView()
        .preferredColorScheme(AppTheme(rawValue: storedTheme)?.colorScheme)
    }
  }
}
