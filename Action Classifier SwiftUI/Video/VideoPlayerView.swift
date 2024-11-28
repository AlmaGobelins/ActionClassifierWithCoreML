import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let player1 = AVPlayer(url: Bundle.main.url(forResource: "mexico", withExtension: "mp4")!)
    @ObservedObject var predictionVM = PredictionViewModel()

    var body: some View {
        GeometryReader { geometry in
            VideoPlayer(player: player1)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .onAppear {
                    player1.pause() // Assurez-vous que la vidéo est en pause au départ
                }
                .onDisappear {
                    player1.pause() // Pause la vidéo lorsqu'on quitte la vue
                }
                .onChange(of: predictionVM.predicted) { newValue in
                    if newValue == "handwave" {
//                        player1.seek(to: .zero) // Remet à zéro pour relancer
                        player1.play() // Démarre la lecture
                    }
                }
        }
        .ignoresSafeArea()
    }
}
