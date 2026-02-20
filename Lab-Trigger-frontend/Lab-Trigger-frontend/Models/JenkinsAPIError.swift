//
//  JenkinsAPIError.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-08.
//

import Foundation

// MARK: - API Errors

enum JenkinsAPIError: LocalizedError {
  case invalidURL
  case invalidCredentials
  case networkError(Error)
  case serverError(Int)
  case decodingError(Error)
  case unknown

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid Jenkins URL. Please check the URL format."
    case .invalidCredentials:
      return "Invalid credentials. Please check your username and password."
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    case .serverError(let code):
      return "Server error (HTTP \(code)). Please try again later."
    case .decodingError(let error):
      return "Failed to parse server response: \(error.localizedDescription)"
    case .unknown:
      return "An unknown error occurred."
    }
  }
}
