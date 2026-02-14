//
//  NotificationModifier.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-09.
//

import SwiftUI

struct NotificationModifier: ViewModifier {
  @StateObject private var notificationManager = NotificationManager.shared

  func body(content: Content) -> some View {
    ZStack {
      content

      VStack {
        if let notification = notificationManager.currentNotification {
          ToastView(notification: notification) {
            notificationManager.dismiss()
          }
          .transition(.move(edge: .top).combined(with: .opacity))
          .zIndex(1)
        }
        Spacer()
      }
      .padding(.top, 10)
      .animation(.spring(), value: notificationManager.currentNotification)
    }
  }
}

extension View {
  /// Applies the global notification manager to the view
  func notificationManager() -> some View {
    self.modifier(NotificationModifier())
  }
}
