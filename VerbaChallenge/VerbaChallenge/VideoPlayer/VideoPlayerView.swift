import ComposableArchitecture
import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @Bindable var store: StoreOf<VideoPlayerFeature>
    @Dependency(\.videoPlayerService) private var videoPlayerService

    var body: some View {
        VStack {
            GeometryReader { geometry in
                videoPlayer
                    .frame(width: geometry.size.width, height: geometry.size.height)

                let midX = geometry.size.width / 2
                let midY = geometry.size.height / 2
                TextLayerView(text: "Verba", origin: CGPoint(x: midY, y: midY))
                    .opacity(store.isLayerVisible ? 1 : 0)
                    .position(x: midX, y: midY)

                playButton
                    .position(x: midX, y: midY)
            }

            slider
        }
        .contentShape(Rectangle())
        .onTapGesture {
            store.send(.showButton)
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

extension VideoPlayerView {
    var videoPlayer: some View {
        VideoPlayer(player: videoPlayerService.player)
            .disabled(true)
    }

    var slider: some View {
        Slider(
            value: Binding(
                get: {
                    store.currentTime / videoPlayerService.duration
                },
                set: { newValue in
                    store.send(.sliderChanged(newValue * videoPlayerService.duration))
                }
            )
        )
        .padding()
    }

    var playButton: some View {
        Button {
            if store.state.isPlaying {
                store.send(.pause)
            } else {
                store.send(.play)
            }
        } label: {
            Image(systemName: store.state.isPlaying ? "pause.fill" : "play.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .padding(20)
                .foregroundColor(.white)
                .opacity(store.state.isButtonVisible ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.5), value: store.state.isButtonVisible)
    }
}

#if DEBUG
#Preview {
    @Previewable var store: StoreOf<VideoPlayerFeature> = .init(
        initialState: VideoPlayerFeature.State()
    ) {
        VideoPlayerFeature()
    }

    VideoPlayerView(store: store)
}
#endif
