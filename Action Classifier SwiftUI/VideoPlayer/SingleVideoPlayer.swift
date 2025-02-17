//
//  LoopingVideoView.swift
//  TAM Project
//
//  Created by Mathieu DUBART on 20/06/2024.
//

import SwiftUI
import AVKit

class VideoPlayerController: ObservableObject {
    private weak var playerViewController: PlayerViewController?
    
    var onVideoEnd: (() -> Void)?
    
    func setPlayerViewController(_ controller: PlayerViewController) {
        self.playerViewController = controller
        // Add observer for video completion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    
    func play() {
        playerViewController?.playVideo()
    }
    
    func pause() {
        playerViewController?.pauseVideo()
    }
    
    func updateVideo(_ videoName: String) {
        playerViewController?.updateVideoSource(videoName: videoName, format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
    }
    
    @objc private func videoDidFinishPlaying(notification: Notification) {
        // Utilisation de DispatchQueue pour mettre à jour le step après la fin de la vidéo
        DispatchQueue.main.async {
            self.onVideoEnd?()
        }
    }
}

struct SingleVideoPlayer: View {
    var videoName: String
    var format: String
    var frameSize: CGSize
    @ObservedObject var controller: VideoPlayerController
    
    var body: some View {
        VideoPlayerRepresentable(
            videoName: videoName,
            format: format,
            frameSize: frameSize,
            controller: controller
        )
    }
    
    func play() {
        controller.play()
    }
    
    func pause() {
        controller.pause()
    }
    
}

struct VideoPlayerRepresentable: UIViewControllerRepresentable {
    var videoName: String
    var format: String
    var frameSize: CGSize
    var controller: VideoPlayerController
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = PlayerViewController(videoName: videoName, format: format, frameSize: frameSize)
        self.controller.setPlayerViewController(controller)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let playerViewController = uiViewController as? PlayerViewController {
            playerViewController.updateVideoSource(videoName: videoName, format: format, frameSize: frameSize)
        }
    }
}

