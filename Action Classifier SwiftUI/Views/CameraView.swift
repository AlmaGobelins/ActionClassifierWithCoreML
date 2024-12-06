//
//  CameraView.swift
//  AutoPictureAndRecognition
//
//  Created by Mathieu DUBART on 22/11/2024.
//

import AVFoundation
import SwiftUI
import UIKit

import SwiftUI
import AVFoundation

struct CameraView {
    @Binding var image: UIImage?
    
    class Coordinator: NSObject {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func didCapturePhoto(_ image: UIImage) {
            parent.image = image
        }
    }
}

