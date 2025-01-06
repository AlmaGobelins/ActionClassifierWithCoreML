//
//  FlipDetector.swift
//  SpheroSugarPot
//
//  Created by Mathieu Dubart on 28/11/2024.
//

import Foundation

class FlipDetector {
    private var isFlipped = false
    private let gyroThreshold: Int = 130
    private weak var toyBox: SharedToyBox?
    
    var onFlipDetected: (() -> Void)?
    
    init(toyBox: SharedToyBox) {
        self.toyBox = toyBox
    }
    
    func startMonitoring() {
        isFlipped = false
        toyBox?.onGyroData = { [weak self] gyroData in
            self?.processGyroData(gyroData)
        }
    }
    
    func stopMonitoring() {
        toyBox?.onGyroData = nil
    }
    
    private func processGyroData(_ gyroData: ThreeAxisSensorData<Int>) {
        guard let x = gyroData.x,
              let y = gyroData.y,
              let z = gyroData.z else { return }
        
        if (abs(x) > gyroThreshold || abs(y) > gyroThreshold || abs(z) > gyroThreshold) && !isFlipped {
            isFlipped = true
            print("FLIP DÉTECTÉ! X: \(x), Y: \(y), Z: \(z)")
            onFlipDetected?()
            stopMonitoring() // Arrêt de la détection après le flip
        }
    }
}
