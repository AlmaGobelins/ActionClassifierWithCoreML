//
//  SharedToyBox.swift
//  SpheroManager
//
//  Created by AL on 01/09/2019.
//  Copyright © 2019 AL. All rights reserved.
//

import Foundation

class SharedToyBox {
    static let instance = SharedToyBox()
    
    private var searchCallBack: ((Error?) -> ())?
    
    // Callbacks pour les données des capteurs
    var onAccelerometerData: ((ThreeAxisSensorData<Double>) -> Void)?
    var onGyroData: ((ThreeAxisSensorData<Int>) -> Void)?
    var onOrientationData: ((AttitudeSensorData) -> Void)?
    
    let box = ToyBox()
    var boltsNames = [String]()
    var bolts: [BoltToy] = []
    
    var bolt: BoltToy? {
        get {
            return bolts.first
        }
    }
    
    init() {
        box.addListener(self)
    }
    
    func searchForBoltsNamed(_ names: [String], doneCallBack: @escaping (Error?) -> ()) {
        searchCallBack = doneCallBack
        boltsNames = names
        box.start()
    }
    
    func stopScan() {
        box.stopScan()
    }
    
    // Fonction pour activer les capteurs
    func startSensors() {
        guard let bolt = bolt else { return }
        
        bolt.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .accelerometer, .gyro, .orientation, .locator))
        bolt.sensorControl.interval = 100 // Mise à jour toutes les 100ms
        
        bolt.sensorControl.onDataReady = { [weak self] data in
            if let acceleroDatas = data.accelerometer?.filteredAcceleration {
                self?.onAccelerometerData?(acceleroDatas)
            }
            if let gyroDatas = data.gyro?.rotationRate {
                self?.onGyroData?(gyroDatas)
            }
            if let orientation = data.orientation {
                self?.onOrientationData?(orientation)
            }
        }
    }
    
    // Fonction pour désactiver les capteurs
    func stopSensors() {
        bolt?.sensorControl.disable()
    }
}

extension SharedToyBox: ToyBoxListener {
    func toyBoxReady(_ toyBox: ToyBox) {
        box.startScan()
    }
    
    func toyBox(_ toyBox: ToyBox, discovered descriptor: ToyDescriptor) {
        print("discovered \(descriptor.name)")
        
        if bolts.count >= boltsNames.count {
            box.stopScan()
        } else {
            if boltsNames.contains(descriptor.name ?? "") {
                let bolt = BoltToy(peripheral: descriptor.peripheral, owner: toyBox)
                bolts.append(bolt)
                toyBox.connect(toy: bolt)
            }
        }
    }
    
    func toyBox(_ toyBox: ToyBox, readied toy: Toy) {
        print("readied")
        if let b = toy as? BoltToy {
            if let i = self.bolts.firstIndex(where: { $0.identifier == b.identifier }) {
                self.bolts[i] = b
            }
            
            if bolts.count >= boltsNames.count {
                DispatchQueue.main.async {
                    self.searchCallBack?(nil)
                }
            }
            
            b.setBackLed(color: .blue)
            b.setFrontLed(color: .red)
            
            // Démarrer automatiquement les capteurs quand le Bolt est prêt
            startSensors()
        }
    }
    
    func toyBox(_ toyBox: ToyBox, putAway toy: Toy) {
        print("put away")
        stopSensors()
    }
}
