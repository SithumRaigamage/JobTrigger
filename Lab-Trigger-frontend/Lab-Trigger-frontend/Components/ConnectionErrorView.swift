//
//  ConnectionErrorView.swift
//  Lab-Trigger-frontend
//
//  Created by Thamindu Dasanayake on 2026-02-08.
//

import SwiftUI

struct ConnectionErrorView: View {
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("Connection Failed")
                .font(.title2)
                .fontWeight(.bold)

            Text("Unable to reach the backend server.\nPlease ensure the server is running.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry Connection", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
