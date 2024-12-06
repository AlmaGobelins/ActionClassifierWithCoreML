//
//  PlayerViewController.swift
//  TAM Project
//
//  Created by Mathieu DUBART on 20/06/2024.
//

import Foundation
import AVKit
import SwiftUI

class PlayerViewController: UIViewController {
    private var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    private var playerItem: AVPlayerItem!
    private var playerObserver: Any?
    
    init(videoName: String, format: String = "mp4", frameSize: CGSize) {
        super.init(nibName: nil, bundle: nil)
        setupPlayer(videoName: videoName, format: format, frameSize: frameSize)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.addSublayer(playerLayer)
        
        // Add observer to detect when video finishes playing
        playerObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.player.seek(to: .zero)
            self?.player.pause()
        }

        player.play()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        player.pause()
        
        // Remove observer when view disappears
        if let observer = playerObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func setupPlayer(videoName: String, format: String, frameSize: CGSize) {
        if let videoURL = Bundle.main.url(forResource: videoName, withExtension: format) {
            self.playerItem = AVPlayerItem(url: videoURL)
            self.player = AVPlayer(playerItem: playerItem)
            
            // Initialize playerLayer here
            self.playerLayer = AVPlayerLayer(player: player)
            self.playerLayer.frame = CGRect(origin: .zero, size: frameSize)
            self.playerLayer.videoGravity = .resizeAspectFill
        }
    }
    
    func updateVideoSource(videoName: String, format: String = "mp4", frameSize: CGSize) {
        if let videoURL = Bundle.main.url(forResource: videoName, withExtension: format) {
            let newPlayerItem = AVPlayerItem(url: videoURL)
            player.replaceCurrentItem(with: newPlayerItem)
            playerLayer.frame = CGRect(origin: .zero, size: frameSize)
            player.play()
        }
    }
    
    func playVideo() {
        player.play()
    }
    
    func pauseVideo() {
        player.pause()
    }
}
