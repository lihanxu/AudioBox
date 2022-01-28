//
//  AppDelegate.swift
//  AudioBox
//
//  Created by anker on 2022/1/28.
//

import UIKit
import AVFoundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        do {
            // options: .allowBluetoothA2DP
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, options: [.allowBluetoothA2DP])
//            let hwSampleRate: Double = 48000;
//            try audioSession.setPreferredSampleRate(hwSampleRate)
//            let bufferDuration: TimeInterval = 1024.0 / hwSampleRate;
//            try audioSession.setPreferredIOBufferDuration(bufferDuration)
            try audioSession.setActive(true)
        } catch  {
            print("AVAudioSession setCategory failed!!!")
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

