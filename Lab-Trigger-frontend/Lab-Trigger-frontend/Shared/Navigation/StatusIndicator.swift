//
//  StatusIndicator.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-17.
//

import SwiftUI

struct StatusIndicator: View {
  let color: String
  @State private var isPulsing = false

  var body: some View {
    ZStack {
      Circle()
        .fill(uiColor.opacity(isAnimating ? 0.1 : 0.2))
        .frame(width: 16, height: 16)
        .scaleEffect(isPulsing ? 1.4 : 1.0)
        .opacity(isPulsing ? 0.5 : 1.0)

      Circle()
        .fill(uiColor)
        .frame(width: 8, height: 8)
        .shadow(color: uiColor, radius: isPulsing ? 6 : 4)
    }
    .onAppear {
      if isAnimating {
        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
          isPulsing = true
        }
      }
    }
  }

  private var isAnimating: Bool {
    color.lowercased().contains("_anime")
  }

  private var uiColor: Color {
    let cleanColor = color.lowercased().replacingOccurrences(of: "_anime", with: "")
    switch cleanColor {
    case "blue":
      return .green  // Jenkins Blue = Success (Green)
    case "red":
      return .red
    case "yellow":
      return .orange  // Jenkins Yellow = Unstable (Orange)
    case "aborted", "disabled", "notbuilt":
      return .gray
    default:
      return .gray
    }
  }
}

#Preview {
  VStack {
    StatusIndicator(color: "blue")
    StatusIndicator(color: "red")
    StatusIndicator(color: "yellow")
    StatusIndicator(color: "grey")
  }
}
