//
//  AudioEncoderViewController.swift
//  AudioBox
//
//  Created by anker on 2022/2/9.
//

import UIKit

class AudioEncoderViewController: UIViewController {
    private enum State {
        case idle
        case encoding
        case ready
        case playing
    }
    
    private enum EncodeType {
        case WAV
        case AAC
    }

    @IBOutlet weak var desLabel: UILabel!
    @IBOutlet weak var wavButton: UIButton!
    @IBOutlet weak var aacButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    private var currentState: State = .idle {
        didSet {
            updateUI()
        }
    }
    private var currentEncodeType: EncodeType = .WAV
    
    let ffPresenter: FFmpegPresenter = FFmpegPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    private func updateUI() {
        playButton.setTitle("Play", for: .normal)
        switch currentState {
        case .idle:
            desLabel.text = "Try click encode button ~"
            wavButton.isEnabled = true
            aacButton.isEnabled = true
            playButton.isEnabled = false
            break
        case .encoding:
            desLabel.text = "Encoding, please wait..."
            wavButton.isEnabled = false
            aacButton.isEnabled = false
            playButton.isEnabled = false
            break
        case .ready:
            desLabel.text = "Encode done, tye play it!"
            wavButton.isEnabled = true
            aacButton.isEnabled = true
            playButton.isEnabled = true
            break
        case .playing:
            desLabel.text = "playing..."
            wavButton.isEnabled = false
            aacButton.isEnabled = false
            playButton.isEnabled = true
            playButton.setTitle("Pause", for: .normal)
            break
        }
    }

    @IBAction private func wavButtonDidClick(_ sender: Any) {
        if currentState == .idle || currentState == .ready {
            startEncodeWAV()
        }
    }
    
    @IBAction func aacButtonDidClick(_ sender: Any) {
        if currentState == .idle || currentState == .ready {
            startEncodeAAC()
        }
    }
    
    @IBAction private func playButtonDidClick(_ sender: Any) {
        if currentState == .ready {
            startPlay()
        } else if currentState == .playing {
            stopPlay()
        }
    }
    
    private func startEncodeWAV() {
        guard let pcmPath: String = Bundle.main.path(forResource: "fascinated", ofType: "pcm") else {
            print("error: can not find pcm resource.")
            showError()
            return
        }
        let wavPath: String = FileManager.documentsDir() + "/fascinated.wav"
        currentState = .encoding
        ffPresenter.encodePCM(pcmPath, toWAV: wavPath)
        currentState = .ready
    }
    
    private func startEncodeAAC() {
        guard let pcmPath: String = Bundle.main.path(forResource: "fascinated", ofType: "pcm") else {
            print("error: can not find pcm resource.")
            showError()
            return
        }
        let aacPath: String = FileManager.documentsDir() + "/fascinated.aac"
        currentState = .encoding
        ffPresenter.encodePCM(pcmPath, toAAC: aacPath)
        currentState = .ready
    }
    
    private func startPlay() {
        var ret: Bool = false
        switch currentEncodeType {
        case .WAV:
            let wavPath: String = FileManager.documentsDir() + "/fascinated.wav"
            ret = ffPresenter.playWAV(wavPath)
        case .AAC:
            return
        }
        guard ret else {
            return
        }
        currentState = .playing
    }
    
    private func stopPlay() {
        ffPresenter.stopPlay()
        currentState = .ready
    }
}
