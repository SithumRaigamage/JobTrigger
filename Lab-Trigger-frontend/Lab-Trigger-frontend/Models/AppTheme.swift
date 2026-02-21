//
//  AppTheme.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-21.
//

import SwiftUI

enum AppTheme: Int, CaseIterable, Identifiable {
  case system = 0
  case light = 1
  case dark = 2

  var id: Int { self.rawValue }

  var title: String {
    switch self {
    case .system: return "System"
    case .light: return "Light"
    case .dark: return "Dark"
    }
  }

  var colorScheme: ColorScheme? {
    switch self {
    case .system: return nil
    case .light: return .light
    case .dark: return .dark
    }
  }
}
