//
//  VerbaChallengeApp.swift
//  VerbaChallenge
//
//  Created by Ilya Bykov on 16/11/2024.
//

import ComposableArchitecture
import SwiftUI

@main
struct VerbaChallengeApp: App {
    static let store = Store(initialState: VideoPlayerFeature.State()) {
        VideoPlayerFeature()
            ._printChanges()
    }

    var body: some Scene {
        WindowGroup {
            VideoPlayerView(store: Self.store)
        }
    }
}
