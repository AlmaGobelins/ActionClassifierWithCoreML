//
//  WebsocketClient.swift
//  WebSocketClient
//
//  Created by digital on 22/10/2024.
//
// IP Fixe : 192.168.1.99

import SwiftUI
import NWWebSocket
import Network

class WebSocketClient: ObservableObject {
    struct Message: Identifiable, Equatable {
        let id = UUID().uuidString
        let content:String
    }
    
    static let shared:WebSocketClient = WebSocketClient()
    var resetVideoPlayer: (() -> Void)?

    var routes = [String:NWWebSocket]()
    // Macbook pro Mathieu
    var ipAdress: String = "192.168.0.166:8080"
    // Macbook pro Killian
    //var ipAdress: String = "192.168.0.132:8080"
    // Chez Killian
    //var ipAdress: String = "192.168.1.20:8080"
    @Published var receivedMessage: String = ""
    @Published var step: Int = 0
    
    @Published var toggleCoucou: Bool = false
    
    @Published var toggleSugar: Bool = false
    
    @Published var toggleBougieVideo: Bool = false
    
    @Published var papel1Both: Bool = false
    @Published var papel2Both: Bool = false

    @Published var videoName: String = "0_ACCUEIL"
    
    @Published var videoCorrect: Bool = false
    @Published var videoIncorrect: Bool = false

    
    func connectTo(route:String) -> Bool {
        let socketURL = URL(string: "ws://\(ipAdress)/\(route)")
        if let url = socketURL {
            let socket = NWWebSocket(url: url, connectAutomatically: true)
            
            socket.delegate = self
            socket.connect()
            routes[route] = socket
            print("Connected to WSServer @ \(url) -- Routes: \(routes)")
            return true
        }
        
        return false
    }
    
    func sendMessage(_ string: String, toRoute route:String) -> Void {
        self.routes[route]?.send(string: string)
    }
    
    func disconnect(route: String) -> Void {
        routes[route]?.disconnect()
    }
    
    func disconnectFromAllRoutes() -> Void {
        for route in routes {
            route.value.disconnect()
        }
        
        print("Disconnected from all routes.")
    }
}

extension WebSocketClient: WebSocketConnectionDelegate {
    
    func webSocketDidConnect(connection: WebSocketConnection) {
        // Respond to a WebSocket connection event
        print("WebSocket connected")
    }
    
    func webSocketDidDisconnect(connection: WebSocketConnection,
                                closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        // Respond to a WebSocket disconnection event
        print("WebSocket disconnected")
    }
    
    func webSocketViabilityDidChange(connection: WebSocketConnection, isViable: Bool) {
        // Respond to a WebSocket connection viability change event
        print("WebSocket viability: \(isViable)")
    }
    
    func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketConnection, NWError>) {
        // Respond to when a WebSocket connection migrates to a better network path
        // (e.g. A device moves from a cellular connection to a Wi-Fi connection)
    }
    
    func webSocketDidReceiveError(connection: WebSocketConnection, error: NWError) {
        // Respond to a WebSocket error event
        print("WebSocket error: \(error)")
    }
    
    func webSocketDidReceivePong(connection: WebSocketConnection) {
        // Respond to a WebSocket connection receiving a Pong from the peer
        print("WebSocket received Pong")
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        // Respond to a WebSocket connection receiving a `String` message
        print("WebSocket received message: \(string)")
        self.receivedMessage = string
        if string == "ping" {
            self.sendMessage("pong", toRoute: "phoneFireplace")
            self.sendMessage("pong", toRoute: "ipadRoberto")
        }
        
        if string == "papel_1_both" {
            DispatchQueue.main.async {
                self.papel1Both = true
            }
        }
        if string == "papel_2_both" {
            DispatchQueue.main.async {
                self.papel2Both = true
            }
        }
        if string == "next_step" {
            DispatchQueue.main.async {
                self.step += 1
                print("step \(self.step)")
            }
        }
        
        if string == "previous_step" {
            DispatchQueue.main.async {
                self.resetVideoPlayer?()
                self.step -= 1
                print("step \(self.step)")
            }
        }
        
        if string == "trigger_coucou" {
            print("inside trigger coucou")
            DispatchQueue.main.async {
                self.toggleCoucou = true
            }
        }
        
        if string == "trigger_video_correct"{
            print("--> video correct")
            DispatchQueue.main.async {
                self.videoCorrect = true
            }
            
        }
        
        if string == "trigger_video_incorrect"{
            DispatchQueue.main.async {
                self.videoIncorrect = true
            }
        }
        
        if string == "trigger_sugar"{
            DispatchQueue.main.async {
                self.toggleSugar = true
            }
        }
        
        if string == "play_video_bougie"{
            print("play video bougie received")
            DispatchQueue.main.async {
                self.toggleBougieVideo = true
            }
        }
        
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        // Respond to a WebSocket connection receiving a binary `Data` message
        print("WebSocket received Data message \(data)")
    }
}
