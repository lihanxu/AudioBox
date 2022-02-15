//
//  AudioChangeViewController.swift
//  AudioBox
//
//  Created by anker on 2022/2/15.
//

import UIKit

class AudioChangeViewController: UIViewController {
    enum State {
        case Pause
        case Playing
    }
    
    @IBOutlet weak var slowButton: UIButton!
    @IBOutlet weak var fastButton: UIButton!
    @IBOutlet weak var pitchUpButton: UIButton!
    @IBOutlet weak var pitchDownButton: UIButton!
    @IBOutlet weak var echoButton: UIButton!
    @IBOutlet weak var reverbButton: UIButton!
    
    private var magician: AudioMagician = AudioMagician()
    private let filePath: URL? = {
        let path = Bundle.main.url(forResource: "fascinated", withExtension: "aac")
        return path
    }()
    private var playingButton: UIButton?
    private var currentState: State = .Pause {
        didSet {
            updateUI()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func updateUI() {
        let enabled = currentState == .Pause
        slowButton.isEnabled = enabled
        fastButton.isEnabled = enabled
        pitchUpButton.isEnabled = enabled
        pitchDownButton.isEnabled = enabled
        echoButton.isEnabled = enabled
        reverbButton.isEnabled = enabled
        playingButton?.isEnabled = true
    }

    @IBAction func slowButtonDidClick(_ sender: Any) {
        playingButton = sender as? UIButton
        if currentState == .Pause {
            currentState = .Playing
            magician.playSound(filePath: filePath!, rate: 0.5)
        } else {
            currentState = .Pause
            magician.stopAudio()
        }
    }
    
    @IBAction func fastButtonDidClick(_ sender: Any) {
        playingButton = sender as? UIButton
        if currentState == .Pause {
            currentState = .Playing
            magician.playSound(filePath: filePath!, rate: 1.5)
        } else {
            currentState = .Pause
            magician.stopAudio()
        }
    }
    
    @IBAction func pitchUpButtonDidClick(_ sender: Any) {
        playingButton = sender as? UIButton
        if currentState == .Pause {
            currentState = .Playing
            magician.playSound(filePath: filePath!, pitch: 1000)
        } else {
            currentState = .Pause
            magician.stopAudio()
        }
    }
    
    @IBAction func pitchDownButtonDidClick(_ sender: Any) {
        playingButton = sender as? UIButton
        if currentState == .Pause {
            currentState = .Playing
            magician.playSound(filePath: filePath!, pitch: -1000)
        } else {
            currentState = .Pause
            magician.stopAudio()
        }
    }
    
    @IBAction func echoButtonDidClick(_ sender: Any) {
        playingButton = sender as? UIButton
        if currentState == .Pause {
            currentState = .Playing
            magician.playSound(filePath: filePath!, echo: true)
        } else {
            currentState = .Pause
            magician.stopAudio()
        }
    }
    
    @IBAction func reverbButtonDidClick(_ sender: Any) {
        playingButton = sender as? UIButton
        if currentState == .Pause {
            currentState = .Playing
            magician.playSound(filePath: filePath!, reverb: true)
        } else {
            currentState = .Pause
            magician.stopAudio()
        }
    }
    
}
