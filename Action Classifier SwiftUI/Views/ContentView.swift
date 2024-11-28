//
//  ContentView.swift
//  Action Classifier SwiftUI
//
//  Created by Gianluca Orpello on 02/03/23.
//

import SwiftUI
import Vision
struct ContentView: View {
    @ObservedObject var predictionVM = PredictionViewModel()

    var switchCamera: some View {
        HStack {
            Button {
                predictionVM.videoCapture.toggleCameraSelection()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
            }
            .padding(.leading)
            
            Spacer()
        }
    }
    
    var predictionLabels: some View {
        VStack {
            switchCamera
            Spacer()
            Text("Prediction: \(predictionVM.predicted)")
            Text("Confidence: \(predictionVM.confidence)")
        }
    }
    
    var body: some View {
        ZStack {
            Image(uiImage: predictionVM.currentFrame ?? UIImage())
                .resizable()
                .scaledToFill()
            predictionLabels
            VideoPlayerView() // Pass the binding
                .edgesIgnoringSafeArea(.all)
        }
        .padding()
        .onAppear {
            predictionVM.updateUILabels(with: .startingPrediction)
        }
        .onReceive(
            NotificationCenter
                .default
                .publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                    predictionVM.videoCapture.updateDeviceOrientation()
                }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
