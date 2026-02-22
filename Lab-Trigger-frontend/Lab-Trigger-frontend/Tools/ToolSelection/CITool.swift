//
//  CITool.swift
//  Lab-Trigger-frontend
//
//  Defines all supported (and upcoming) CI/CD tools.
//  Add new cases here as new tool integrations are built.
//

import SwiftUI

enum CITool: String, CaseIterable, Identifiable {
  case jenkins
  case githubActions
  case gitlab
  case sonarqube
  case circleci

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .jenkins: return "Jenkins"
    case .githubActions: return "GitHub Actions"
    case .gitlab: return "GitLab CI"
    case .sonarqube: return "SonarQube"
    case .circleci: return "CircleCI"
    }
  }

  var logoAssetName: String {
    switch self {
    case .jenkins: return "jenkins-logo"
    case .githubActions: return "github-actions-logo"
    case .gitlab: return "gitlab-logo"
    case .sonarqube: return "sonarqube-logo"
    case .circleci: return "circleci-logo"
    }
  }

  /// SF Symbol fallback when the asset is not in the catalog yet
  var fallbackSymbol: String {
    switch self {
    case .jenkins: return "gearshape.2.fill"
    case .githubActions: return "arrow.triangle.branch"
    case .gitlab: return "diamond.fill"
    case .sonarqube: return "waveform.path.ecg"
    case .circleci: return "arrow.2.circlepath"
    }
  }

  /// Accent color for each tool's card
  var accentColor: Color {
    switch self {
    case .jenkins: return Color(red: 0.82, green: 0.18, blue: 0.18)  // Jenkins red
    case .githubActions: return Color(red: 0.13, green: 0.13, blue: 0.13)  // GitHub dark
    case .gitlab: return Color(red: 0.90, green: 0.35, blue: 0.16)  // GitLab orange
    case .sonarqube: return Color(red: 0.31, green: 0.60, blue: 0.93)  // SonarQube blue
    case .circleci: return Color(red: 0.09, green: 0.65, blue: 0.58)  // CircleCI teal
    }
  }

  /// Only Jenkins is available in v1.0
  var isAvailable: Bool {
    self == .jenkins
  }
}
