//
//  AudioMagician.swift
//  AudioBox
//
//  Created by anker on 2022/2/15.
//

import UIKit
import AVFoundation

class AudioMagician: NSObject {
    private var audioFile: AVAudioFile?
    private var audioEngine:AVAudioEngine!
    private var audioPlayerNode: AVAudioPlayerNode!
    private var stopTimer: Timer!
    
    func playSound(filePath path: URL, rate: Float? = nil, pitch: Float? = nil, echo: Bool = false, reverb: Bool = false) {
        do {
            audioFile = try AVAudioFile(forReading: path)
        } catch {
            print("Audio Magician open file failed: \(path)")
            return
        }

        // initialize audio engine components
        audioEngine = AVAudioEngine()
        
        // node for playing audio
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attach(audioPlayerNode)
        
        // node for adjusting rate/pitch
        let changeRatePitchNode = AVAudioUnitTimePitch()
        if let pitch = pitch {
            changeRatePitchNode.pitch = pitch
        }
        if let rate = rate {
            changeRatePitchNode.rate = rate
        }
        audioEngine.attach(changeRatePitchNode)
        
        // node for echo
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.multiEcho1)
        audioEngine.attach(echoNode)
        
        // node for reverb
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 50
        audioEngine.attach(reverbNode)
        
        // connect nodes
        if echo == true && reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, reverbNode, audioEngine.outputNode)
        } else if echo == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, audioEngine.outputNode)
        } else if reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, reverbNode, audioEngine.outputNode)
        } else {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, audioEngine.outputNode)
        }
        
        // schedule to play and start the engine!
        audioPlayerNode.stop()
        audioPlayerNode?.scheduleFile(audioFile!, at: nil) {
            
            var delayInSeconds: Double = 0
            
            if let lastRenderTime = self.audioPlayerNode.lastRenderTime, let playerTime = self.audioPlayerNode.playerTime(forNodeTime: lastRenderTime) {
                
                if let rate = rate {
                    delayInSeconds = Double((self.audioFile?.length)! - playerTime.sampleTime) / Double((self.audioFile?.processingFormat.sampleRate)!) / Double(rate)
                } else {
                    delayInSeconds = Double((self.audioFile?.length)! - playerTime.sampleTime) / Double((self.audioFile?.processingFormat.sampleRate)!)
                }
            }
            
            // schedule a stop timer for when audio finishes playing
            self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(AudioMagician.stopAudio), userInfo: nil, repeats: false)
            RunLoop.main.add(self.stopTimer!, forMode: .default)
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("Audio Magiciacn play sound failed!!!")
            return
        }
        
        // play the recording!
        audioPlayerNode.play()
    }
    
    @objc func stopAudio() {
        if let audioPlayerNode = audioPlayerNode {
            audioPlayerNode.stop()
        }
        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }
    
    private func connectAudioNodes(_ nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1], format: audioFile?.processingFormat)
        }
    }
}
