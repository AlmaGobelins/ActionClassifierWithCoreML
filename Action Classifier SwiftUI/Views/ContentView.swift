import SwiftUI
import Vision
struct ContentView: View {
    let spherosNames: [String] = ["SB-A729"]
    @State private var spheroIsConnected: Bool = false
    @ObservedObject var predictionVM = PredictionViewModel()
    @ObservedObject var wsClient = WebSocketClient.shared
    @State var connectedToServer: Bool = false
    
    @StateObject private var videoControllerStep0 = VideoPlayerController()
    @StateObject private var videoControllerStep1Success = VideoPlayerController()
    @StateObject private var videoControllerStep1Failure = VideoPlayerController()
    @StateObject private var videoControllerStep2Success = VideoPlayerController()
    @StateObject private var videoControllerStep2Failure = VideoPlayerController()
    @StateObject private var videoControllerStep3Success = VideoPlayerController()
    @StateObject private var videoControllerStep3Failure = VideoPlayerController()
    @StateObject private var videoControllerStep4Success = VideoPlayerController()
    @StateObject private var videoControllerStep4Failure = VideoPlayerController()
    @StateObject private var videoControllerStep5Success = VideoPlayerController()
    @StateObject private var videoControllerStep5Failure = VideoPlayerController()
    @StateObject private var videoControllerStep6Success = VideoPlayerController()
    @StateObject private var videoControllerStep6Failure = VideoPlayerController()
    
    @StateObject var bottleRecognitionManager = BottleRecognitionManager()
    @StateObject var panRecognitionManager = PanRecognitionManager()
    
    @State private var videoIsPlaying: Bool = false
    @State private var showCaptureButton: Bool = false
    
    @State private var activeVideo: String?
    @State private var canRetry = false
    
    @State private var videoPlayCount = 0


    @State private var displayVideo: Bool = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .ignoresSafeArea()
            
            Image("roberto_placeholder")
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .scaledToFill()
                .ignoresSafeArea()
            
            Text("Step : \(wsClient.step)")
                .padding()
                .foregroundColor(Color.red)
                .background(Color.white.opacity(0.7))
                .cornerRadius(10)
                .padding([.top, .leading], 16)
            HStack{
                Spacer()
                Text("Previous")
                    .onTapGesture {
                        self.wsClient.step -= 1
                    }
                    .padding()
                    .foregroundColor(Color.red)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(10)
                    .padding([.top, .trailing], 16)
                
            }
        
            ZStack() {
                // Step 0: Vidéo d'accueil
                if wsClient.step == 0 {
                    SingleVideoPlayer(videoName: "0_ACCUEIL", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep0)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .onAppear {
                            self.videoControllerStep0.pause()
                            wsClient.sendMessage("step_0_appeared", toRoute: "ipadRoberto")
                            self.videoControllerStep0.onVideoEnd = {
                                self.wsClient.step = 1
                                print("-----> STEP \(self.wsClient.step)")
                                wsClient.sendMessage("step_0_end", toRoute: "ipadRoberto")
                            }
                        }
                        .onDisappear() {
                            self.videoControllerStep0.onVideoEnd = nil
                        }
                        .onTapGesture {
                            self.wsClient.step = 1
                        }
                        .onChange(of: predictionVM.predicted) { newValue in
                            if newValue == "handwave" {
                                self.videoControllerStep0.play()
                                wsClient.sendMessage("step_0_start", toRoute: "ipadRoberto")
                            }
                        }
                }
                
                // Step 1: Vidéo de boisson
                if wsClient.step == 1 {
                    ZStack {
                        Text("Next Step")
                            .foregroundColor(Color.blue)
                            .background(Color.white.opacity(0.7))
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        
                        if activeVideo == "1_O_BOISSON" {
                            SingleVideoPlayer(
                                videoName: "1_O_BOISSON",
                                format: "mp4",
                                frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height),
                                controller: videoControllerStep1Success
                            )
                            .id(videoPlayCount) // Force le rafraîchissement
                            .onAppear {
                                self.videoControllerStep1Success.play()
                                self.videoControllerStep1Success.onVideoEnd = {
                                    DispatchQueue.main.async {
                                        self.wsClient.step = 2
                                        print("video step 1 success")
                                    }
                                }
                            }
                            .onDisappear() {
                                self.videoControllerStep1Success.onVideoEnd = nil
                            }
                        } else if activeVideo == "1_N_BOISSON" {
                            SingleVideoPlayer(
                                videoName: "1_N_BOISSON",
                                format: "mp4",
                                frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height),
                                controller: videoControllerStep1Failure
                            )
                            .id(videoPlayCount) // Force le rafraîchissement
                            .onAppear {
                                self.videoControllerStep1Failure.play()
                                self.videoControllerStep1Failure.onVideoEnd = {
                                    DispatchQueue.main.async {
                                        self.canRetry = true  // Active la possibilité de réessayer
                                        print("video step 1 failure")
                                    }
                                }
                            }
                            .onDisappear() {
                                self.videoControllerStep1Failure.onVideoEnd = nil
                            }
                        }
                    }
                    .onChange(of: predictionVM.predicted) { newValue in
                        if newValue == "handwave" {
                            if canRetry {
                                // Réinitialise l'état pour un nouveau test
                                self.canRetry = false
                                self.videoPlayCount += 1 // Incrémente le compteur pour forcer le rafraîchissement
                                bottleRecognitionManager.recognizeObjectsIn(image: predictionVM.currentFrame ?? UIImage())
                                self.activeVideo = bottleRecognitionManager.isBottle ? "1_O_BOISSON" : "1_N_BOISSON"
                            } else if activeVideo == nil {
                                // Premier essai
                                bottleRecognitionManager.recognizeObjectsIn(image: predictionVM.currentFrame ?? UIImage())
                                self.activeVideo = bottleRecognitionManager.isBottle ? "1_O_BOISSON" : "1_N_BOISSON"
                            }
                        }
                    }
                    .onTapGesture {
                        self.wsClient.step = 2
                    }
                }
                
                if wsClient.step == 2 {
                    ZStack {
                        Text("Next Step").foregroundColor(Color.blue).background(Color.white.opacity(0.7)).padding().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        if activeVideo == "2_O_PAN" {
                            SingleVideoPlayer(videoName: "2_O_PAN", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep2Success)
                                .onAppear {
                                    self.videoControllerStep2Success.play()
                                    self.videoControllerStep2Success.onVideoEnd = {
                                        self.wsClient.step = 3
                                    }
                                }.onDisappear() {
                                    self.videoControllerStep2Success.onVideoEnd = nil
                                }
                        } else if activeVideo == "2_N_PAN" {
                            SingleVideoPlayer(videoName: "2_N_PAN", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep2Failure)
                                .onAppear {
                                    self.videoControllerStep2Failure.play()
                                    self.videoControllerStep2Failure.onVideoEnd = {
                                        self.wsClient.step = 2
                                    }
                                }.onDisappear() {
                                    self.videoControllerStep2Failure.onVideoEnd = nil
                                }
                        }
                    }
                    .onAppear(){
                        wsClient.sendMessage("step_3_appeared", toRoute: "ipadRoberto")
                    }
                    .onChange(of: predictionVM.predicted) { newValue in
                        if newValue == "handwave" {
                            panRecognitionManager.recognizeObjectsIn(image: predictionVM.currentFrame ?? UIImage())
                            print("---> isPan : \(panRecognitionManager.isPan)")
                            self.activeVideo = panRecognitionManager.isPan ? "2_O_PAN" : "2_N_PAN"
                        }
                    }
                    .onTapGesture {
                        self.wsClient.step = 3
                    }
                }
                
                if wsClient.step == 3 {
                    ZStack {
                        Text("Next Step").foregroundColor(Color.blue).background(Color.white.opacity(0.7)).padding().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        //Remplacer par video sucre
                      //Envoyer depuis Esp un message Step 3
                        if activeVideo == "2_O_PAN" {
                            SingleVideoPlayer(videoName: "2_O_PAN", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep3Success)
                                .onAppear {
                                    self.videoControllerStep3Success.play()
                                    self.videoControllerStep3Success.onVideoEnd = {
                                        self.wsClient.step = 4
                                    }
                                }.onDisappear() {
                                    self.videoControllerStep3Success.onVideoEnd = nil
                                }
                        //Remplacer par vidéo sucre false
                        } else if activeVideo == "2_N_PAN" {
                            SingleVideoPlayer(videoName: "2_N_PAN", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep3Failure)
                                .onAppear {
                                    self.videoControllerStep3Failure.play()
                                    self.videoControllerStep3Failure.onVideoEnd = {
                                        self.wsClient.step = 3
                                    }
                                }.onDisappear() {
                                    self.videoControllerStep3Failure.onVideoEnd = nil
                                }
                        }
                    }
                    .onAppear(){
                        wsClient.sendMessage("step_3_appeared", toRoute: "ipadRoberto")
                    }
                    .onTapGesture {
                        self.wsClient.step = 4
                    }
                }
                
                if wsClient.step == 4 {
                    ZStack {
                        Text("Next Step").foregroundColor(Color.blue).background(Color.white.opacity(0.7)).padding().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        //Remplacer par video bougie
                         //Envoyer depuis Esp un message Step 5
                        if activeVideo == "2_O_PAN" {
                            SingleVideoPlayer(videoName: "2_O_PAN", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep4Success)
                                .onAppear {
                                    self.videoControllerStep4Success.play()
                                    self.videoControllerStep4Success.onVideoEnd = {
                                        self.wsClient.step = 5
                                    }
                                }.onDisappear() {
                                    self.videoControllerStep4Success.onVideoEnd = nil
                                }
                        //Remplacer par vidéo bougie false
                        } else if activeVideo == "2_N_PAN" {
                            SingleVideoPlayer(videoName: "2_N_PAN", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep4Failure)
                                .onAppear {
                                    self.videoControllerStep4Failure.play()
                                    self.videoControllerStep4Failure.onVideoEnd = {
                                        self.wsClient.step = 4
                                    }
                                }.onDisappear() {
                                    self.videoControllerStep4Failure.onVideoEnd = nil
                                }
                        }
                    }
                    .onAppear(){
                        wsClient.sendMessage("step_4_appeared", toRoute: "ipadRoberto")
                    }
                    .onTapGesture {
                        self.wsClient.step = 5
                    }
                }
                
                if wsClient.step == 5 {
                    ZStack {
                        Text("Next Step").foregroundColor(Color.blue).background(Color.white.opacity(0.7)).padding().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        if activeVideo == "5_O_PAPEL" {
                            SingleVideoPlayer(videoName: "5_O_PAPEL", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep5Success)
                                .onAppear {
                                    self.videoControllerStep5Success.play()
                                    self.videoControllerStep5Success.onVideoEnd = {
                                        self.wsClient.step = 6
                                    }
                                }.onDisappear() {
                                    self.videoControllerStep5Success.onVideoEnd = nil
                                }
                        } else if activeVideo == "5_N_PAPEL" {
                            SingleVideoPlayer(videoName: "5_N_PAPEL", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep5Failure)
                                .onAppear {
                                    self.videoControllerStep5Failure.play()
                                    self.videoControllerStep5Failure.onVideoEnd = {
                                        self.wsClient.step = 5
                                    }
                                }.onDisappear() {
                                    self.videoControllerStep5Failure.onVideoEnd = nil
                                }
                        }
                    }
                    .onTapGesture {
                        self.wsClient.step = 6
                    }
                    .onAppear(){
                        wsClient.sendMessage("step_5_appeared", toRoute: "ipadRoberto")
                    }
                }
                
                if wsClient.step == 6 {
                    ZStack {
                        Text("Next Step").foregroundColor(Color.blue).background(Color.white.opacity(0.7)).padding().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        if activeVideo == "6_O_OBJET" {
                            SingleVideoPlayer(videoName: "6_O_OBJET", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep6Success)
                                .onAppear {
                                    self.videoControllerStep6Success.play()
                                    self.videoControllerStep6Success.onVideoEnd = {
                                        self.wsClient.step = 7
                                    }
                                }.onDisappear() {
                                    self.videoControllerStep6Success.onVideoEnd = nil
                                }
                        } else if activeVideo == "6_N_OBJET" {
                            SingleVideoPlayer(videoName: "6_N_OBJET", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep6Failure)
                                .onAppear {
                                    self.videoControllerStep6Failure.play()
                                    self.videoControllerStep6Failure.onVideoEnd = {
                                        self.wsClient.step = 6
                                    }
                                }.onDisappear() {
                                    self.videoControllerStep6Failure.onVideoEnd = nil
                                }
                        }
                    }
                    .onAppear(){
                        wsClient.sendMessage("step_6_appeared", toRoute: "ipadRoberto")
                    }
                    .onChange(of: predictionVM.predicted) { newValue in
                        if newValue == "handwave" {
                            panRecognitionManager.recognizeObjectsIn(image: predictionVM.currentFrame ?? UIImage())
                            print("---> isPan : \(panRecognitionManager.isPan)")
                            self.activeVideo = panRecognitionManager.isPan ? "6_O_OBJET" : "6_N_OBJET"
                        }
                    }
                    .onTapGesture {
                        self.wsClient.step = 7
                    }
                }
            }
        }
        .padding()
        .ignoresSafeArea()
        .onAppear {
            predictionVM.updateUILabels(with: .startingPrediction)
            wsClient.connectTo(route: "ipadRoberto")
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
