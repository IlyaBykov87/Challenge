//
//  VideoPlayerService.swift
//  VerbaChallenge
//
//  Created by Ilya Bykov on 16/11/2024.
//

import ComposableArchitecture
@preconcurrency import AVFoundation

protocol VideoPlayerServiceProtocol {
    var duration: Double { get }
    var player: AVPlayer { get }
    func play()
    func pause()
    func seek(to time: Double)

    func addTimeObserver() -> AsyncStream<Double>
    func removeTimeObserver()
}

final class VideoPlayerService: VideoPlayerServiceProtocol {
    var player: AVPlayer
    private var timeObserver: Any?

    var duration: Double = 0

    init(player: AVPlayer) {
        self.player = player
        fetchDuration()
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func seek(to timeInSeconds: Double) {
        player.seek(
            to: CMTime(seconds: timeInSeconds, preferredTimescale: 1),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }

    func addTimeObserver() -> AsyncStream<Double> {
        AsyncStream { continuation in
            let interval: CMTime = CMTimeMakeWithSeconds(0.1, preferredTimescale: Int32(NSEC_PER_SEC))
            timeObserver = player.addPeriodicTimeObserver(
                forInterval: interval,
                queue: .main
            ) { time in
                continuation.yield(time.seconds)
            }

            continuation.onTermination = { [weak self] _ in
                self?.removeTimeObserver()
            }
        }
    }

    func removeTimeObserver() {
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
    }
}

extension VideoPlayerService {
    private func fetchDuration() {
        Task {
            do {
                duration = try await player.currentItem?.asset.load(.duration).seconds ?? 0.0
            }
        }
    }
}

extension DependencyValues {
    var videoPlayerService: VideoPlayerServiceProtocol {
        get { self[VideoPlayerServiceKey.self] }
        set { self[VideoPlayerServiceKey.self] = newValue }
    }
}

private enum VideoPlayerServiceKey: DependencyKey {
    static let liveValue: VideoPlayerServiceProtocol = VideoPlayerService(
        player: AVPlayer(url: Bundle.main.url(forResource: "cat", withExtension: "mp4")!)
    )
}
