//
//  CustomCameraViewController.swift
//  AutoPictureAndRecognition
//
//  Created by Mathieu Dubart on 23/11/2024.
//

import AVFoundation
import SwiftUI
import UIKit

class CustomCameraViewController: UIViewController {
    private var captureSession: AVCaptureSession!
    private var photoOutput: AVCapturePhotoOutput!
    var delegate: CameraView.Coordinator?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        // Définir les styles de présentation dans l'initialisation
        self.modalPresentationStyle = .overCurrentContext
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        view.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSession()
        
        // Prendre la photo après un court délai (ici 2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.capturePhoto()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // S'assurer que la vue reste à sa taille normale
        view.frame = UIScreen.main.bounds
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        // position: .front pour caméra avant et .back pour caméra arrière
        if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            do {
                let input = try AVCaptureDeviceInput(device: frontCamera)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                }
                
                photoOutput = AVCapturePhotoOutput()
                if captureSession.canAddOutput(photoOutput) {
                    captureSession.addOutput(photoOutput)
                }
            } catch {
                print("Erreur lors de la configuration de la caméra: \(error.localizedDescription)")
            }
        }
    }
    
    private func startSession() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    private func stopSession() {
        captureSession?.stopRunning()
    }
    
    private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CustomCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print("Erreur lors de la capture: \(error!.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            // S'assurer que la vue est à sa taille normale avant de fermer
            self?.view.frame = UIScreen.main.bounds
            self?.delegate?.didCapturePhoto(image)
            
            // Attendre un court instant avant de fermer pour éviter l'animation de zoom
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.dismiss(animated: true)
            }
        }
    }
}
