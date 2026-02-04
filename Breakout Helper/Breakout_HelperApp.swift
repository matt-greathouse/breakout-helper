//
//  Breakout_HelperApp.swift
//  Breakout Helper
//
//  Created by Matt Greathouse on 2/4/26.
//

import SwiftUI

@main
struct Breakout_HelperApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = BreakoutStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.resetIfNeeded()
            }
        }
    }
}
