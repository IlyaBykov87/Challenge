//
//  VerbaChallengeTests.swift
//  VerbaChallengeTests
//
//  Created by Ilya Bykov on 16/11/2024.
//

import ComposableArchitecture
import Testing

@testable import VerbaChallenge

@MainActor
struct VerbaChallengeTests {
    @Test
    func testResetHideButtonTimer() async {
        let clock = TestClock()
        let store = TestStore(initialState: VideoPlayerFeature.State()) {
            VideoPlayerFeature()
        }
        withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.resetHideButtonTimer)
        await clock.advance(by: .seconds(3))
        await store.receive(.hideButton) {
            $0.isButtonVisible = false
        }
    }
}
