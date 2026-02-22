//
//  ToastView.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-09.
//

import SwiftUI

struct ToastView: View {
  let notification: NotificationMessage
  var onDismiss: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: notification.type.icon)
        .font(.system(size: 20))
        .foregroundColor(notification.type.color)

      VStack(alignment: .leading, spacing: 2) {
        Text(notification.title)
          .font(.subheadline)
          .fontWeight(.bold)

        Text(notification.message)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      Button {
        onDismiss()
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(.secondary)
      }
    }
    .padding()
    .background(Color(UIColor.secondarySystemGroupedBackground))
    .cornerRadius(12)
    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    .padding(.horizontal)
    .onTapGesture {
      onDismiss()
    }
  }
}

#Preview {
  VStack {
    ToastView(
      notification: NotificationMessage(
        type: .success, title: "Success", message: "Build triggered successfully.")
    ) {}
    ToastView(
      notification: NotificationMessage(
        type: .error, title: "Error", message: "Invalid credentials provided.")
    ) {}
  }
  .padding()
  .background(Color.gray.opacity(0.1))
}
