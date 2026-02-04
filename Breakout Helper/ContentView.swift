//
//  ContentView.swift
//  Breakout Helper
//
//  Created by Matt Greathouse on 2/4/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                MainView()
            }
                .tabItem {
                    Label("Breakout", systemImage: "person.3.fill")
                }

            NavigationStack {
                SettingsView()
            }
                .tabItem {
                    Label("Settings", systemImage: "slider.horizontal.3")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BreakoutStore())
}
