//
//  BuildLogView.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-20.
//

import SwiftUI

struct BuildLogView: View {
  @StateObject var viewModel: BuildLogViewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 0) {
      // Header for controls
      HStack {
        Text("Build #\(viewModel.buildNumber) Console")
          .font(.headline)
        Spacer()

        Button(action: { viewModel.autoScroll.toggle() }) {
          Label(
            viewModel.autoScroll ? "Auto-scroll ON" : "Auto-scroll OFF",
            systemImage: viewModel.autoScroll ? "chevron.down.circle.fill" : "chevron.down.circle"
          )
          .font(.caption2)
          .foregroundColor(viewModel.autoScroll ? .blue : .secondary)
        }
      }
      .padding()
      .background(Color(UIColor.secondarySystemBackground))

      if let error = viewModel.error {
        VStack(spacing: 16) {
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 40))
            .foregroundColor(.yellow)
          Text("Failed to load logs")
            .font(.headline)
          Text(error)
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)

          Button("Retry") {
            Task {
              await viewModel.startFetching()
            }
          }
          .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
      } else {
        ScrollViewReader { proxy in
          ScrollView {
            VStack(alignment: .leading, spacing: 0) {
              Text(viewModel.logs)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .id("logContent")
            }
          }
          .background(Color.black)
          .onChange(of: viewModel.logs) { _ in
            if viewModel.autoScroll {
              withAnimation {
                proxy.scrollTo("logContent", anchor: .bottom)
              }
            }
          }
        }
      }

      // Footer/Loading indicator
      if viewModel.isLoading && viewModel.logs.isEmpty {
        ProgressView("Loading logs...")
          .padding()
      } else if !viewModel.isFinished {
        HStack {
          ProgressView()
            .scaleEffect(0.7)
          Text("Streaming logs...")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(8)
      }
    }
    .navigationTitle("Logs")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        HStack {
          Button(action: viewModel.copyToClipboard) {
            Image(systemName: "doc.on.doc")
          }
          Button(action: viewModel.shareLogs) {
            Image(systemName: "square.and.arrow.up")
          }
        }
      }
    }
    .onAppear {
      Task {
        await viewModel.startFetching()
      }
    }
    .onDisappear {
      viewModel.stopFetching()
    }
  }
}

struct BuildLogView_Previews: PreviewProvider {
  static var previews: some View {
    BuildLogView(viewModel: BuildLogViewModel(buildURL: "", buildNumber: 123))
  }
}
