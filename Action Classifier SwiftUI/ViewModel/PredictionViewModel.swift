//
//  PredictionViewModel.swift
//  Action Classifier SwiftUI
//
//  Created by Gianluca Orpello on 02/03/23.
//

import SwiftUI
import Vision
import CoreML

class PredictionViewModel: ObservableObject {
    
    // Published Variables
    
    @Published var currentFrame: UIImage?
    @Published var predicted: String = ""
    @Published var confidence: String = ""
    
    
    private var model: VNCoreMLModel?
    private var visionRequest: VNCoreMLRequest?
    
    /// Captures the frames from the camera and creates a frame publisher.
    var videoCapture: VideoCapture!
    
    /// Builds a chain of Combine publishers from a frame publisher.
    ///
    /// The video-processing chain provides the view controller with:
    /// - Each video camera frame as a `CGImage`.
    /// - A `Pose` array of any people `Vision` observed in that frame.
    /// - Action predictions from the prominent person's poses over time.
    var videoProcessingChain: VideoProcessingChain!
    
    /// Maintains the aggregate time for each action the model predicts.
    /// - Tag: actionFrameCounts
    var actionFrameCounts = [String: Int]()
    
    init() {
        // Set the view controller as the video-processing chain's delegate.
        videoProcessingChain = VideoProcessingChain()
        videoProcessingChain.delegate = self
        
        // Begin receiving frames from the video capture.
        videoCapture = VideoCapture()
        videoCapture.delegate = self
    }
    

    // Handle the prediction results
    private func handlePredictionResults(request: VNRequest, error: Error?) {
        if let results = request.results as? [VNClassificationObservation], let topResult = results.first {
            DispatchQueue.main.async {
                self.predicted = topResult.identifier
                self.confidence = String(format: "%.2f", topResult.confidence)
            }
        } else {
            print("Failed to classify image.")
        }
    }
    /// Updates the user interface's labels with the prediction and its
    /// confidence.
    /// - Parameters:
    ///   - label: The prediction label.
    ///   - confidence: The prediction's confidence value.
    func updateUILabels(with prediction: ActionPrediction) {
        // Update the UI's prediction label on the main thread.
        DispatchQueue.main.async {
            self.predicted = prediction.label
            //print("Predicted: \(self.predicted)")
        }
        
        // Update the UI's confidence label on the main thread.
        let confidenceString = prediction.confidenceString ?? "Observing..."
        DispatchQueue.main.async { self.confidence = confidenceString }
    }
    
    /// Add the incremental duration to an action's total time.
    /// - Parameters:
    ///   - actionLabel: The name of the action.
    ///   - duration: The incremental duration of the action.
    private func addFrameCount(_ frameCount: Int, to actionLabel: String) {
        // Add the new duration to the current total, if it exists.
        let totalFrames = (actionFrameCounts[actionLabel] ?? 0) + frameCount
        
        // Assign the new total frame count for this action.
        actionFrameCounts[actionLabel] = totalFrames
    }
    
    /// Draws poses as wireframes on top of a frame, and updates the user
    /// interface with the final image.
    /// - Parameters:
    ///   - poses: An array of human body poses.
    ///   - frame: An image.
    /// - Tag: drawPoses
    private func drawPoses(_ poses: [Pose]?, onto frame: CGImage) {
        // Create a default render format at a scale of 1:1.
        let renderFormat = UIGraphicsImageRendererFormat()
        renderFormat.scale = 1.0
        
        // Create a renderer with the same size as the frame.
        let frameSize = CGSize(width: frame.width, height: frame.height)
        let poseRenderer = UIGraphicsImageRenderer(size: frameSize,
                                                   format: renderFormat)
        
        // Draw the frame first and then draw pose wireframes on top of it.
        let frameWithPosesRendering = poseRenderer.image { rendererContext in
            // The`UIGraphicsImageRenderer` instance flips the Y-Axis presuming
            // we're drawing with UIKit's coordinate system and orientation.
            let cgContext = rendererContext.cgContext
            
            // Get the inverse of the current transform matrix (CTM).
            let inverse = cgContext.ctm.inverted()
            
            // Restore the Y-Axis by multiplying the CTM by its inverse to reset
            // the context's transform matrix to the identity.
            cgContext.concatenate(inverse)
            
            // Draw the camera image first as the background.
            let imageRectangle = CGRect(origin: .zero, size: frameSize)
            cgContext.draw(frame, in: imageRectangle)
            
            // Create a transform that converts the poses' normalized point
            // coordinates `[0.0, 1.0]` to properly fit the frame's size.
            let pointTransform = CGAffineTransform(scaleX: frameSize.width,
                                                   y: frameSize.height)
            
            guard let poses = poses else { return }
            
            // Draw all the poses Vision found in the frame.
            for pose in poses {
                // Draw each pose as a wireframe at the scale of the image.
                pose.drawWireframeToContext(cgContext, applying: pointTransform)
            }
        }
        
        // Update the UI's full-screen image view on the main thread.
        
        DispatchQueue.main.async { self.currentFrame = frameWithPosesRendering }
    }
    
}

extension PredictionViewModel: VideoCaptureDelegate {
    
    func videoCapture(_ videoCapture: VideoCapture, didCreate framePublisher: FramePublisher) {
        
        updateUILabels(with: .startingPrediction)
        
        // Build a new video-processing chain by assigning the new frame publisher.
        videoProcessingChain.upstreamFramePublisher = framePublisher
    }
    
}

extension PredictionViewModel: VideoProcessingChainDelegate {
    
    func videoProcessingChain(_ chain: VideoProcessingChain,
                              didPredict actionPrediction: ActionPrediction,
                              for frames: Int) {
        
        if actionPrediction.isModelLabel {
            // Update the total number of frames for this action.
            addFrameCount(frames, to: actionPrediction.label)
        }
        
        // Present the prediction in the UI.
        DispatchQueue.main.async { self.updateUILabels(with: actionPrediction) }
        
    }
    
    func videoProcessingChain(_ chain: VideoProcessingChain,
                              didDetect poses: [Pose]?,
                              in frame: CGImage) {
        self.drawPoses(poses, onto: frame)
    }
    
}
