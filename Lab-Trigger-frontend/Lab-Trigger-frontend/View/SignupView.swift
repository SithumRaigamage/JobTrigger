//
//  SignupView.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-09.
//

import SwiftUI

struct SignupView: View {
  @StateObject private var viewModel = SignupViewModel()
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ZStack {
      Color(UIColor.systemGroupedBackground)
        .ignoresSafeArea()

      VStack(spacing: 20) {
        // Header
        VStack(spacing: 12) {
          Text("Create Account")
            .font(.largeTitle)
            .fontWeight(.bold)

          Text("Get started with JobTrigger today")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.top, 20)

        // Form
        Form {
          Section {
            LabeledField(title: "Email") {
              TextField("email@example.com", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            }

            SecureToggleField(
              title: "Password",
              placeholder: "6+ characters",
              text: $viewModel.password
            )

            SecureToggleField(
              title: "Confirm",
              placeholder: "Re-enter password",
              text: $viewModel.confirmPassword
            )
          }

          Section {
            Button {
              viewModel.signup()
            } label: {
              HStack {
                Spacer()
                if viewModel.isLoading {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                  Text("Create Account")
                    .fontWeight(.semibold)
                }
                Spacer()
              }
            }
            .padding(.vertical, 8)
            .listRowBackground(Color.blue)
            .foregroundColor(.white)
            .disabled(viewModel.isLoading)
          }
        }

        Spacer()
      }
    }
    .navigationTitle("Sign Up")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    SignupView()
  }
}
