//
//  LabeledField.swift
//  Lab-Trigger-frontend
//
//  Created by Thamindu Dasanayake on 2026-02-08.
//

import SwiftUI

struct LabeledField<Content: View>: View {
  let title: String
  let content: Content
  let errorMessage: String?
  let statusIcon: String?
  let statusColor: Color

  init(
    title: String,
    errorMessage: String? = nil,
    statusIcon: String? = nil,
    statusColor: Color = .secondary,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.errorMessage = errorMessage
    self.statusIcon = statusIcon
    self.statusColor = statusColor
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(title)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(.secondary)

        Spacer()

        if let icon = statusIcon {
          Image(systemName: icon)
            .font(.caption)
            .foregroundColor(statusColor)
        }
      }

      content
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .overlay(
          RoundedRectangle(cornerRadius: 10)
            .stroke(errorMessage != nil ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
        )

      if let error = errorMessage {
        Text(error)
          .font(.caption2)
          .foregroundColor(.red)
          .padding(.horizontal, 4)
      }
    }
  }
}
