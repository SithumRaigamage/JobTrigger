//
//  NotificationManager.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-09.
//

import Combine
import Foundation

/// Manages the display and dismissal of global notifications/toasts
final class NotificationManager: ObservableObject {

  // MARK: - Published Properties

  @Published var currentNotification: NotificationMessage?

  // MARK: - Properties

  private var dismissTimer: Timer?

  // MARK: - Singleton

  static let shared = NotificationManager()

  private init() {}

  // MARK: - Public Methods

  /// Display a notification
  /// - Parameters:
  ///   - type: The type of notification (success, error, etc.)
  ///   - title: Short bold title
  ///   - message: Detailed message
  ///   - autoDismiss: Whether to dismiss after a delay (default: true)
  func show(type: NotificationType, title: String, message: String, autoDismiss: Bool = true) {
    // Cancel any existing timer
    dismissTimer?.invalidate()

    // Update UI on main thread
    DispatchQueue.main.async {
      self.currentNotification = NotificationMessage(type: type, title: title, message: message)

      if autoDismiss {
        self.dismissTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) {
          [weak self] _ in
          self?.dismiss()
        }
      }
    }
  }

  /// Dismiss the current notification
  func dismiss() {
    dismissTimer?.invalidate()
    dismissTimer = nil

    DispatchQueue.main.async {
      self.currentNotification = nil
    }
  }
}
