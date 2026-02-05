//
//  ContentView.swift
//  Breakout Helper
//
//  Created by Matt Greathouse on 2/4/26.
//

import SwiftUI

struct ContentView: View {
    private enum Tab: Int {
        case breakout
        case settings
    }

    @AppStorage("selectedTab.v1") private var selectedTab = Tab.breakout.rawValue
    @AppStorage("hasLaunchedBefore.v1") private var hasLaunchedBefore = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                MainView()
            }
            .tabItem {
                Label("Breakout", systemImage: "person.3.fill")
            }
            .tag(Tab.breakout.rawValue)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "slider.horizontal.3")
            }
            .tag(Tab.settings.rawValue)
        }
        .onAppear {
            if !hasLaunchedBefore {
                selectedTab = Tab.settings.rawValue
                hasLaunchedBefore = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BreakoutStore())
}
