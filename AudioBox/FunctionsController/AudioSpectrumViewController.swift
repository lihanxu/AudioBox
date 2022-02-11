//
//  AudioSpectrumViewController.swift
//  AudioBox
//
//  Created by anker on 2022/2/11.
//

import UIKit

class AudioSpectrumViewController: UIViewController {
    private enum State {
        case pause
        case playing
    }
    
    @IBOutlet weak var spectrumView: SpectrumView!
    @IBOutlet weak var playButton: UIButton!
    
    private let player: AudioSpectrumPlayer = AudioSpectrumPlayer()
    private var currentState: State = .pause {
        didSet {
            updateUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        player.delegate = self
        updateUI()
    }
    
    private func updateUI() {
        switch currentState {
        case .pause:
            playButton.setTitle("Play", for: .normal)
        case .playing:
            playButton.setTitle("Pause", for: .normal)
        }
    }
    
    @IBAction func playButtonDidClick(_ sender: Any) {
        if currentState == .pause {
            startPlay()
        } else {
            stopPlay()
        }
    }
    
    private func startPlay() {
        currentState = .playing
        let filePath: String = "fascinated.mp3"
        player.play(withFileName: filePath)
    }
    
    private func stopPlay() {
        currentState = .pause
        player.stop()
    }
}

extension AudioSpectrumViewController: AudioSpectrumPlayerDelegate {
    func player(_ player: AudioSpectrumPlayer, didGenerateSpectrum spectra: [[Float]]) {
        DispatchQueue.main.async {
            self.spectrumView.spectra = spectra
        }
    }
}
