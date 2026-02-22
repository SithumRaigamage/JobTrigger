//
//  SecureToggleField.swift
//  Lab-Trigger-frontend
//
//  Created by Thamindu Dasanayake on 2026-02-08.
//

import SwiftUI

struct SecureToggleField: View {
  let title: String
  let placeholder: String
  @Binding var text: String
  var errorMessage: String? = nil
  var statusIcon: String? = nil
  var statusColor: Color = .secondary

  @State private var isVisible = false

  var body: some View {
    LabeledField(
      title: title,
      errorMessage: errorMessage,
      statusIcon: statusIcon,
      statusColor: statusColor
    ) {
      HStack {
        if isVisible {
          TextField(placeholder, text: $text)
            .textInputAutocapitalization(.never)
        } else {
          SecureField(placeholder, text: $text)
        }

        Button {
          isVisible.toggle()
        } label: {
          Image(systemName: isVisible ? "eye.slash" : "eye")
            .foregroundColor(.secondary)
        }
      }
    }
  }
}
