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

      Form {
        Section {
          VStack(spacing: 12) {
            Image(systemName: "person.badge.plus")
              .font(.system(size: 60))
              .foregroundColor(.blue)

            Text("Create Account")
              .font(.largeTitle)
              .fontWeight(.bold)

            Text("Join JobTrigger to simplify your builds")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 20)
        }
        .listRowBackground(Color.clear)

        Section(header: Text("Account Details")) {
          LabeledField(
            title: "Email",
            errorMessage: viewModel.showErrors && !viewModel.isEmailValid
              ? "Invalid email format" : nil
          ) {
            TextField("email@example.com", text: $viewModel.email)
              .keyboardType(.emailAddress)
              .autocapitalization(.none)
              .disableAutocorrection(true)
          }

          SecureToggleField(
            title: "Password",
            placeholder: "6+ characters",
            text: $viewModel.password,
            errorMessage: viewModel.showErrors && !viewModel.isPasswordValid
              ? "Min 6 characters required" : nil
          )

          SecureToggleField(
            title: "Confirm Password",
            placeholder: "Match password",
            text: $viewModel.confirmPassword,
            errorMessage: viewModel.showErrors && !viewModel.passwordsMatch
              ? "Passwords do not match" : nil
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
              } else {
                Text("Create Account")
                  .fontWeight(.bold)
              }
              Spacer()
            }
          }
          .disabled(viewModel.isLoading)
        }

        Section {
          Button {
            dismiss()
          } label: {
            HStack {
              Spacer()
              Text("Already have an account? Sign In")
                .font(.footnote)
              Spacer()
            }
          }
        }
      }
    }
    .navigationTitle("Sign Up")
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(true)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button {
          dismiss()
        } label: {
          Image(systemName: "chevron.left")
            .foregroundColor(.blue)
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    SignupView()
  }
}
