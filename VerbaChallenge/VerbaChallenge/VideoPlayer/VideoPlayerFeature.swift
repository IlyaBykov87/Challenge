import ComposableArchitecture

@Reducer
struct VideoPlayerFeature {
    private let hideButtonTimerInterval = 3.0
    private let sliderSeekInterval = 0.1
    private let startLayerTime = 5.0
    private let endLayerTime = 10.0

    @ObservableState
    struct State: Equatable {
        var isPlaying = false
        var isButtonVisible = true
        var isLayerVisible = false
        var currentTime = 0.0
    }

    enum Action: Equatable {
        case onAppear
        case onDisappear
        case play
        case pause
        case sliderChanged(Double)
        case showButton
        case showTextLayer
        case hideTextLayer

        // internal
        case seekToTime(Double)
        case updateCurrentTime(Double)
        case hideButton
        case resetHideButtonTimer
    }

    enum CancelID {
        case hideButtonTimer
        case sliderSeek
        case timeObserver
    }

    struct ThrottleToken: Hashable {}

    @Dependency(\.videoPlayerService) var videoPlayerService
    @Dependency(\.continuousClock) var clock
    @Dependency(\.mainQueue) var mainQueue

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                videoPlayerService.seek(to: .zero)
                return .none

            case .onDisappear:
                videoPlayerService.removeTimeObserver()
                return .none

            case .play:
                state.isPlaying = true
                videoPlayerService.play()
                return .merge(
                    .run { send in
                        for await time in videoPlayerService.addTimeObserver() {
                            await send(.updateCurrentTime(time))
                        }
                    }
                    .cancellable(id: CancelID.timeObserver, cancelInFlight: true),
                    .send(.resetHideButtonTimer)
                )

            case .pause:
                state.isPlaying = false
                videoPlayerService.pause()
                videoPlayerService.removeTimeObserver()
                return .merge(
                    .cancel(id: CancelID.timeObserver),
                    .send(.resetHideButtonTimer)
                )

            case .sliderChanged(let timeInSeconds):
                state.isPlaying = false
                state.currentTime = timeInSeconds
                videoPlayerService.pause()
                videoPlayerService.removeTimeObserver()
                return .merge(
                    .cancel(id: CancelID.timeObserver),
                    .run { send in
                        await send(.seekToTime(timeInSeconds))
                    }
                    .throttle(id: ThrottleToken(), for: 0.05, scheduler: mainQueue, latest: true)
                    .cancellable(id: CancelID.sliderSeek, cancelInFlight: true)
                )

            case .showTextLayer:
                state.isLayerVisible = true
                return .none

            case .hideTextLayer:
                state.isLayerVisible = false
                return .none

            case .seekToTime(let timeInSeconds):
                videoPlayerService.seek(to: timeInSeconds)
                return .send(.updateCurrentTime(timeInSeconds))

            case .updateCurrentTime(let timeInSeconds):
                state.currentTime = timeInSeconds
                if timeInSeconds >= startLayerTime && timeInSeconds <= endLayerTime {
                    if !state.isLayerVisible {
                        return .send(.showTextLayer)
                    }
                } else if state.isLayerVisible {
                    return .send(.hideTextLayer)
                }
                return .none

            case .showButton:
                state.isButtonVisible = true
                return .send(.resetHideButtonTimer)

            case .hideButton:
                state.isButtonVisible = false
                return .none

            case .resetHideButtonTimer:
                state.isButtonVisible = true
                return .run { send in
                    try await clock.sleep(for: .seconds(hideButtonTimerInterval))
                    await send(.hideButton)
                }
                .cancellable(id: CancelID.hideButtonTimer, cancelInFlight: true)
            }
        }
    }
}
