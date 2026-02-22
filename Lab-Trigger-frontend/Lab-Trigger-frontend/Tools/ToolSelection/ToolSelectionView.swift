//
//  ToolSelectionView.swift
//  Lab-Trigger-frontend
//
//  Displayed after login, before the main NavBarView.
//  Lets the user select a CI/CD tool. Only Jenkins is currently available.
//

import SwiftUI

struct ToolSelectionView: View {

  @AppStorage("selectedTool") private var selectedTool: String = ""

  // Grid: 2 columns
  private let columns = [
    GridItem(.flexible(), spacing: 16),
    GridItem(.flexible(), spacing: 16),
  ]

  var body: some View {
    ZStack {
      // Background gradient
      LinearGradient(
        colors: [
          Color(UIColor.systemBackground),
          Color(UIColor.secondarySystemBackground),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack(spacing: 0) {
        // Header
        headerSection
          .padding(.top, 60)
          .padding(.horizontal, 24)

        // Tool Grid
        ScrollView {
          LazyVGrid(columns: columns, spacing: 16) {
            ForEach(CITool.allCases) { tool in
              ToolCard(tool: tool) {
                guard tool.isAvailable else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                  selectedTool = tool.rawValue
                }
              }
            }
          }
          .padding(.horizontal, 24)
          .padding(.vertical, 32)
        }
      }
    }
  }

  // MARK: - Subviews

  private var headerSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Choose Your Tool")
        .font(.system(size: 32, weight: .bold, design: .rounded))
        .foregroundStyle(.primary)

      Text("Select a CI/CD platform to get started")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - Tool Card

private struct ToolCard: View {

  let tool: CITool
  let onTap: () -> Void

  @State private var isPressed = false

  var body: some View {
    Button(action: onTap) {
      ZStack(alignment: .topTrailing) {
        VStack(spacing: 16) {
          // Logo / icon
          toolLogo
            .frame(width: 72, height: 72)

          // Name
          Text(tool.displayName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(tool.isAvailable ? .primary : .secondary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 12)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(
          color: tool.isAvailable
            ? tool.accentColor.opacity(0.15)
            : Color.black.opacity(0.04),
          radius: 12, x: 0, y: 4
        )
        .opacity(tool.isAvailable ? 1.0 : 0.6)
        .scaleEffect(isPressed && tool.isAvailable ? 0.96 : 1.0)

        // "Coming Soon" badge — shown for unavailable tools
        if !tool.isAvailable {
          comingSoonBadge
            .padding(10)
        }

        // Checkmark ring for available tool
        if tool.isAvailable {
          availableBadge
            .padding(10)
        }
      }
    }
    .buttonStyle(.plain)
    .simultaneousGesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in
          if tool.isAvailable { withAnimation(.easeIn(duration: 0.1)) { isPressed = true } }
        }
        .onEnded { _ in
          withAnimation(.easeOut(duration: 0.2)) { isPressed = false }
        }
    )
    .disabled(!tool.isAvailable)
  }

  // MARK: - Logo

  @ViewBuilder
  private var toolLogo: some View {
    if UIImage(named: tool.logoAssetName) != nil {
      Image(tool.logoAssetName)
        .resizable()
        .scaledToFit()
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    } else {
      // Fallback SF Symbol with tool accent color
      ZStack {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(tool.accentColor.opacity(0.12))
        Image(systemName: tool.fallbackSymbol)
          .font(.system(size: 30, weight: .medium))
          .foregroundStyle(tool.accentColor)
      }
    }
  }

  // MARK: - Badges

  private var comingSoonBadge: some View {
    Text("Soon")
      .font(.system(size: 9, weight: .bold))
      .foregroundStyle(.white)
      .padding(.horizontal, 7)
      .padding(.vertical, 3)
      .background(Capsule().fill(Color.secondary))
  }

  private var availableBadge: some View {
    Image(systemName: "checkmark.circle.fill")
      .font(.system(size: 18))
      .foregroundStyle(tool.accentColor)
      .background(Circle().fill(Color(UIColor.systemBackground)).padding(2))
  }

  // MARK: - Card Background

  private var cardBackground: some View {
    RoundedRectangle(cornerRadius: 20, style: .continuous)
      .fill(Color(UIColor.secondarySystemGroupedBackground))
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .strokeBorder(
            tool.isAvailable
              ? tool.accentColor.opacity(0.25)
              : Color.gray.opacity(0.1),
            lineWidth: 1.5
          )
      )
  }
}

#Preview {
  ToolSelectionView()
}
