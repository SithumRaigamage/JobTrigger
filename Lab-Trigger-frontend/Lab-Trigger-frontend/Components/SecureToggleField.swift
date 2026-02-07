//
//  SecureToggleField.swift
//  Lab-Trigger-frontend
//
//  Created by Thamindu Dasanayake on 2026-02-08.
//

import Foundation
import SwiftUI

struct SecureToggleField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    @State private var isVisible = false

    var body: some View {
        LabeledField(title: title) {
            HStack {
                if isVisible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }

                Button {
                    isVisible.toggle()
                } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                }
            }
        }
    }
}
