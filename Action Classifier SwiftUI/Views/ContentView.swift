import SwiftUI
import Vision
struct ContentView: View {
    let spherosNames: [String] = ["SB-A729"]
    @State private var spheroIsConnected: Bool = false
    @ObservedObject var predictionVM = PredictionViewModel()
    @ObservedObject var wsClient = WebSocketClient.shared
    @State var connectedToServer: Bool = false
    
    @StateObject private var videoController = VideoPlayerController()
    @StateObject var imageRecognitionManager = ImageRecognitionManager()
    
    @State private var videoIsPlaying: Bool = false
    @State private var showCaptureButton: Bool = false
    
    @State private var displayVideo: Bool = false
    
    var predictionLabels: some View {
        VStack {
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
            
            VStack {
                if wsClient.step == 1 {
                    SingleVideoPlayer(videoName: "intro", format: "MP4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoController)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .ignoresSafeArea()
                        .onAppear {
                            self.videoController.pause()
                            self.videoController.onVideoEnd = {
                                self.wsClient.step = 2
                                print("-----> STEP \(self.wsClient.step)")
                                wsClient.sendMessage("Step 2", toRoute: "allumerFeu")
                            }
                        }
                        .onChange(of: predictionVM.predicted) { newValue in
                            if newValue == "handwave" {
                                self.videoController.play()
                                videoIsPlaying = true
                            }
                        }
                }
                
                if wsClient.step == 2 {
                    
                    VStack{
                        if !self.displayVideo {
                            Text("Detect object").onTapGesture {
                                imageRecognitionManager.recognizeObjectsIn(image: predictionVM.currentFrame ?? UIImage())
                                print("---> Recognition : \(imageRecognitionManager.isBottle)")
                            }
                            .onChange(of: imageRecognitionManager.isBottle) { nV in
                                self.displayVideo = nV
                                print("DisplayVideo new value : \(displayVideo)")
                            }
                        }
                        
                        if (self.displayVideo) {
                            SingleVideoPlayer(videoName: "step2", format: "MP4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoController)
                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                                .ignoresSafeArea()
                                .onAppear {
                                    self.videoController.play()
                                    self.videoController.onVideoEnd = {
                                        print("-----> Print end ")
                                    }
                                }
                        }
                        
                    }
                    
                    /*
                                        VStack {
                                            if imageRecognitionManager.isBottle {
                                                Text("Bottle Here")
                                                SingleVideoPlayer(videoName: "step2", format: "MP4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoController)
                                                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                                                    .ignoresSafeArea()
                                                    .onAppear {
                                                        self.videoController.pause()
                                                        self.videoController.onVideoEnd = {
                                                            self.wsClient.step = 5
                                                            print("-----> STEP \(self.wsClient.step)")
                                                            wsClient.sendMessage("Step 2", toRoute: "allumerFeu")
                                                        }
                                                    }
                    
                                            } else {
                                                Text("Bottle not Here")
                                            }
                                        }.onChange(of: predictionVM.predicted) { newValue in
                                            if newValue == "handwave" {
                                                self.videoController.play()
                                                videoIsPlaying = true
                                            }
                                        }
                    */
                    
                }
                if wsClient.step == 3 {
                    VStack {
                        SingleVideoPlayer(videoName: "step2", format: "MP4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoController)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                            .ignoresSafeArea()
                            .onAppear {
                                self.videoController.play()
                                self.videoController.onVideoEnd = {
                                    self.wsClient.step = 3
                                }
                            }
                        
                    }
                }
            }
        }
        .padding()
        .onAppear {
            predictionVM.updateUILabels(with: .startingPrediction)
            connectedToServer = wsClient.connectTo(route: "ipadRoberto")
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
