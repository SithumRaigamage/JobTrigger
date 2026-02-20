//
//  LoginView.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-09.
//

import SwiftUI

struct LoginView: View {
  @StateObject private var viewModel = LoginViewModel()

  var body: some View {
    NavigationStack {
      ZStack {
        Color(UIColor.systemGroupedBackground)
          .ignoresSafeArea()

        Form {
          Section {
            VStack(spacing: 12) {
              Image(systemName: "bolt.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

              Text("JobTrigger")
                .font(.largeTitle)
                .fontWeight(.bold)

              Text("Sign in to manage your Jenkins builds")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
          }
          .listRowBackground(Color.clear)

          Section {
            LabeledField(title: "Email") {
              TextField("email@example.com", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            }

            SecureToggleField(
              title: "Password",
              placeholder: "Required",
              text: $viewModel.password
            )
          }

          Section {
            Button {
              viewModel.login()
            } label: {
              HStack {
                Spacer()
                if viewModel.isLoading {
                  ProgressView()
                } else {
                  Text("Sign In")
                    .fontWeight(.bold)
                }
                Spacer()
              }
            }
            .disabled(viewModel.isLoading)
          }

          Section {
            Button {
              viewModel.showSignup = true
            } label: {
              HStack {
                Spacer()
                Text("Don't have an account? Sign Up")
                  .font(.footnote)
                Spacer()
              }
            }
          }
        }
      }
      .navigationDestination(isPresented: $viewModel.showSignup) {
        SignupView()
      }
    }
  }
}

#Preview {
  LoginView()
}
