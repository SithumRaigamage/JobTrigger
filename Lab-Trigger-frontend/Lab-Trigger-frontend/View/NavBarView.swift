//
//  NavBarView.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-07.
//

import SwiftUI

struct NavBarView: View {
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }.tag(0)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }.tag(1)
            }
            .navigationTitle(selectedTab == 0 ? "Home" : "Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Profile action - TODO: Implement profile view
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
            }
        }
    }
}

#Preview {
    NavBarView()
}
