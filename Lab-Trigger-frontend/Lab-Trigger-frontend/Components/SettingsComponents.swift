//
//  SettingsComponents.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-08.
//

import SwiftUI

// MARK: - Connection Status Components

struct ConnectionStatusIcon: View {
    let status: SettingsViewModel.ConnectionStatus

    var body: some View {
        Group {
            switch status {
            case .notTested:
                EmptyView()
            case .testing:
                ProgressView()
                    .scaleEffect(0.8)
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }
}

struct ConnectionStatusText: View {
    let status: SettingsViewModel.ConnectionStatus

    var body: some View {
        Text(status.message)
            .font(.subheadline)
            .foregroundColor(statusColor)
    }

    private var statusColor: Color {
        switch status {
        case .notTested: return .secondary
        case .testing: return .secondary
        case .success: return .green
        case .failed: return .red
        }
    }
}