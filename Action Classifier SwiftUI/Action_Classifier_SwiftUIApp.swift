//
//  Action_Classifier_SwiftUIApp.swift
//  Action Classifier SwiftUI
//
//  Created by Gianluca Orpello on 02/03/23.
//

import SwiftUI

@main
struct Action_Classifier_SwiftUIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear{
                    // Disable the idle timer to prevent the screen from locking.
                    UIApplication.shared.isIdleTimerDisabled = true
                }
        }
    }
}
