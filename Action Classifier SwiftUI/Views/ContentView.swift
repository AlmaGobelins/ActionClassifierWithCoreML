import SwiftUI
import Vision
struct ContentView: View {
    let spherosNames: [String] = ["SB-A729"]
    @State private var spheroIsConnected: Bool = false
    @ObservedObject var predictionVM = PredictionViewModel()
    @ObservedObject var wsClient = WebSocketClient.shared
    @State var connectedToServer: Bool = false
    
    @StateObject private var videoController = VideoPlayerController()
    @StateObject private var videoControllerStep1False = VideoPlayerController()
    @StateObject private var videoControllerStep1True = VideoPlayerController()
    
    @StateObject var bottleRecognitionManager = BottleRecognitionManager()
    @StateObject var panRecognitionManager = PanRecognitionManager()
    
    @State private var videoIsPlaying: Bool = false
    @State private var showCaptureButton: Bool = false
    
    @State private var activeVideo: String? = nil
    
    
    @State private var displayVideo: Bool = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            /*Image(uiImage: predictionVM.currentFrame ?? UIImage())
             .resizable()
             .scaledToFill()
             */
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
            
            ZStack() {
                if wsClient.step == 0 {
                    SingleVideoPlayer(videoName: "0_ACCUEIL", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoController)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .ignoresSafeArea()
                        .onAppear {
                            self.videoController.pause()
                            wsClient.sendMessage("step_0_appeared", toRoute: "ipadRoberto")
                            self.videoController.onVideoEnd = {
                                self.wsClient.step = 1
                                print("-----> STEP \(self.wsClient.step)")
                                wsClient.sendMessage("step_0_end", toRoute: "ipadRoberto")
                            }
                        }
                        .onTapGesture {
                            self.wsClient.step = 1
                        }
                        .onChange(of: predictionVM.confidence) { newValue in
                        }
                        .onChange(of: predictionVM.predicted) { newValue in
                            if newValue == "handwave" {
                                self.videoController.play()
                                wsClient.sendMessage("step_0_start", toRoute: "ipadRoberto")
                                videoIsPlaying = true
                            }
                        }
                }
                
                if wsClient.step == 1 {
                    ZStack {
                        Text("Next Step").foregroundColor(Color.blue).background(Color.white.opacity(0.7)).padding().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        if activeVideo == "1_O_BOISSON" {
                            SingleVideoPlayer(videoName: "1_O_BOISSON", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep1True)
                                .onAppear {
                                    self.videoControllerStep1True.play()
                                    self.videoControllerStep1True.onVideoEnd = {
                                        self.wsClient.step = 2
                                    }
                                }
                        } else if activeVideo == "1_N_BOISSON" {
                            SingleVideoPlayer(videoName: "1_N_BOISSON", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep1False)
                                .onAppear {
                                    self.videoControllerStep1False.play()
                                    self.videoControllerStep1False.onVideoEnd = {
                                        self.wsClient.step = 2
                                    }
                                }
                        }
                    }
                    .onChange(of: predictionVM.predicted) { newValue in
                        if newValue == "handwave" {
                            bottleRecognitionManager.recognizeObjectsIn(image: predictionVM.currentFrame ?? UIImage())
                            print("---> isBottle : \(bottleRecognitionManager.isBottle)")
                            self.activeVideo = bottleRecognitionManager.isBottle ? "1_O_BOISSON" : "1_N_BOISSON"
                        }
                    }.onAppear(){
                        wsClient.sendMessage("step_1_appeared", toRoute: "ipadRoberto")
                    }.onTapGesture {
                        self.wsClient.step = 2
                    }
                }
                if wsClient.step == 2 {
                    ZStack {
                        Text("Next Step").foregroundColor(Color.blue).background(Color.white.opacity(0.7)).padding().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        if activeVideo == "2_O_PAN" {
                            SingleVideoPlayer(videoName: "2_O_PAN", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep1True)
                                .onAppear {
                                    self.videoControllerStep1True.play()
                                    self.videoControllerStep1True.onVideoEnd = {
                                        self.wsClient.step = 3
                                    }
                                }
                        } else if activeVideo == "2_N_PAN" {
                            SingleVideoPlayer(videoName: "2_N_PAN", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep1False)
                                .onAppear {
                                    self.videoControllerStep1False.play()
                                    self.videoControllerStep1False.onVideoEnd = {
                                        self.wsClient.step = 2
                                    }
                                }
                        }
                    }
                    .onAppear(){
                        wsClient.sendMessage("step_3_appeared", toRoute: "ipadRoberto")
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
                            SingleVideoPlayer(videoName: "2_O_PAN", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep1True)
                                .onAppear {
                                    self.videoControllerStep1True.play()
                                    self.videoControllerStep1True.onVideoEnd = {
                                        self.wsClient.step = 4
                                    }
                                }
                        //Remplacer par vidéo sucre false
                        } else if activeVideo == "2_N_PAN" {
                            SingleVideoPlayer(videoName: "2_N_PAN", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep1False)
                                .onAppear {
                                    self.videoControllerStep1False.play()
                                    self.videoControllerStep1False.onVideoEnd = {
                                        self.wsClient.step = 3
                                    }
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
                        self.wsClient.step = 4
                    }
                }
                if wsClient.step == 4 {
                    ZStack {
                        Text("Next Step").foregroundColor(Color.blue).background(Color.white.opacity(0.7)).padding().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        //Remplacer par video bougie
                        //Envoyer depuis Esp un message Step 5
                        if activeVideo == "2_O_PAN" {
                            SingleVideoPlayer(videoName: "2_O_PAN", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep1True)
                                .onAppear {
                                    self.videoControllerStep1True.play()
                                    self.videoControllerStep1True.onVideoEnd = {
                                        self.wsClient.step = 5
                                    }
                                }
                        //Remplacer par vidéo bougie false
                        } else if activeVideo == "2_N_PAN" {
                            SingleVideoPlayer(videoName: "2_N_PAN", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep1False)
                                .onAppear {
                                    self.videoControllerStep1False.play()
                                    self.videoControllerStep1False.onVideoEnd = {
                                        self.wsClient.step = 4
                                    }
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
                        // en websocket, si les 4 tags rfid sont bon alors
                        // message reçu est step_5_true
                        if activeVideo == "5_O_PAPEL" {
                            SingleVideoPlayer(videoName: "5_O_PAPEL", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep1True)
                                .onAppear {
                                    self.videoControllerStep1True.play()
                                    self.videoControllerStep1True.onVideoEnd = {
                                        self.wsClient.step = 6
                                    }
                                }
                        // sinon si il n'y a pas les 4 rfid le message reçu est step_5_false puis lancer vidéo pour retenter
                        } else if activeVideo == "5_N_PAPEL" {
                            SingleVideoPlayer(videoName: "5_N_PAPEL", format: "mp4", frameSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), controller: videoControllerStep1False)
                                .onAppear {
                                    self.videoControllerStep1False.play()
                                    self.videoControllerStep1False.onVideoEnd = {
                                        self.wsClient.step = 5
                                    }
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
            }
        }
        .padding()
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
