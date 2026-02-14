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

        VStack(spacing: 20) {
          // Header
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
          .padding(.top, 40)
          .padding(.bottom, 20)

          // Form
          VStack(spacing: 0) {
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
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                      Text("Sign In")
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
            .frame(height: 280)  // Constrain form height
            .scrollDisabled(true)
          }

          Spacer()

          // Footer
          HStack {
            Text("Don't have an account?")
            Button {
              viewModel.showSignup = true
            } label: {
              Text("Sign Up")
                .fontWeight(.bold)
            }
          }
          .font(.footnote)
          .padding(.bottom, 20)
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
