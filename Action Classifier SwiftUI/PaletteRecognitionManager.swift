//
//  ImageRecognitionManager.swift
//  AutoPictureAndRecognition
//
//  Created by Mathieu DUBART on 22/11/2024.
//

import SwiftUI

class PaletteRecognitionManager:ObservableObject {
    @Published var imageDescription = ""
    @Published var isPalette = false
    
    func recognizeObjectsIn(image: UIImage) -> Void {
        let predictor = PalettePredictor()
        do {
            try predictor.makePredictions(for: image) { predictions in
                guard let preds = predictions else { return }
                let predictionArray = self.formatPredictions(preds)
                if predictionArray.contains("palette"){
                    self.isPalette = true
                }
                print("---> Prediction : \(predictionArray)")
                self.imageDescription = predictionArray.joined(separator: "\n")
            }
        } catch {
            print("Error while trying to recognize image")
        }
    }
    
    /// Converts a prediction's observations into human-readable strings.
    /// - Parameter observations: The classification observations from a Vision request.
    /// - Tag: formatPredictions
    private func formatPredictions(_ predictions: [PalettePredictor.Prediction]) -> [String] {
        // Vision sorts the classifications in descending confidence order.
        let topPredictions: [String] = predictions.prefix(1).map { prediction in
            var name = prediction.classification

            // For classifications with more than one name, keep the one before the first comma.
            if let firstComma = name.firstIndex(of: ",") {
                name = String(name.prefix(upTo: firstComma))
            }
            

//            return "\(name) - \(prediction.confidencePercentage)%"
            return "\(name)"
        }

        return topPredictions
    }
}
