//
//  NotificationMessage.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-09.
//

import Foundation
import SwiftUI

/// Defines the type of notification to display
enum NotificationType: Equatable {
  case success
  case error
  case warning
  case info

  var color: Color {
    switch self {
    case .success: return .green
    case .error: return .red
    case .warning: return .orange
    case .info: return .blue
    }
  }

  var icon: String {
    switch self {
    case .success: return "checkmark.circle.fill"
    case .error: return "xmark.circle.fill"
    case .warning: return "exclamationmark.triangle.fill"
    case .info: return "info.circle.fill"
    }
  }
}

/// Represents a notification message to be displayed in a toast
struct NotificationMessage: Identifiable, Equatable {
  let id = UUID()
  let type: NotificationType
  let title: String
  let message: String
}
