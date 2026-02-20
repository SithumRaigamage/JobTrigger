//
//  NavBarView.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-07.
//

import SwiftUI

struct NavBarView: View {
  @State private var selectedTab = 0
  @StateObject private var activeManager = ActiveServerManager.shared

  var body: some View {
    TabView(selection: $selectedTab) {
      NavigationStack {
        HomeView()
          .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              NavigationLink {
                ProfileView()
              } label: {
                Image(systemName: "person.circle")
              }
            }
          }
      }
      .tabItem {
        Label("Home", systemImage: "house")
      }
      .tag(0)

      NavigationStack {
        GlobalHistoryView()
          .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              NavigationLink {
                ProfileView()
              } label: {
                Image(systemName: "person.circle")
              }
            }
          }
      }
      .tabItem {
        Label("History", systemImage: "clock.fill")
      }
      .tag(1)

      NavigationStack {
        SettingsView()
          .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              NavigationLink {
                ProfileView()
              } label: {
                Image(systemName: "person.circle")
              }
            }
          }
      }
      .tabItem {
        Label("Settings", systemImage: "gear")
      }
      .tag(2)
    }
    .onAppear {
      Task {
        await ActiveServerManager.shared.loadInitialServer()
      }
    }
  }
}

#Preview {
  NavBarView()
}
