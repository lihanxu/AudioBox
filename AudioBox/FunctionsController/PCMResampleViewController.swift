//
//  PCMResampleViewController.swift
//  AudioBox
//
//  Created by anker on 2022/2/9.
//

import UIKit

class PCMResampleViewController: UIViewController {
    private enum State {
        case idle
        case resampling
        case ready
        case playing
    }

    @IBOutlet weak var desLabel: UILabel!
    @IBOutlet weak var button36: UIButton!
    @IBOutlet weak var button48: UIButton!
    @IBOutlet weak var button96: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    private let ffPresenter: FFmpegPresenter = FFmpegPresenter()
    private var currentPath: String?
    private var currentSampleRate: Int = 48
    private var currentState: State = .idle {
        didSet {
            updateUI()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    private func updateUI() {
        playButton.setTitle("Play", for: .normal)
        switch currentState {
        case .idle:
            desLabel.text = "Try click resample button ~"
            playButton.isEnabled = false
            button36.isEnabled = true
            button48.isEnabled = true
            button96.isEnabled = true
        case .resampling:
            desLabel.text = "resampling, please wait..."
            playButton.isEnabled = false
            button36.isEnabled = false
            button48.isEnabled = false
            button96.isEnabled = false
        case .ready:
            desLabel.text = "resample done, try play ~"
            playButton.isEnabled = true
            button36.isEnabled = true
            button48.isEnabled = true
            button96.isEnabled = true
        case .playing:
            desLabel.text = "playing..."
            playButton.isEnabled = true
            playButton.setTitle("Pause", for: .normal)
            button36.isEnabled = false
            button48.isEnabled = false
            button96.isEnabled = false
        }
    }
    
    @IBAction func resampleButtonDidClick(_ sender: Any) {
        guard let button = sender as? UIButton else {
            return
        }
        if button === self.button36 {
            currentSampleRate = 36
        } else if button === self.button48 {
            currentSampleRate = 48
        } else if button === self.button96 {
            currentSampleRate = 96
        }
        startResample(to: currentSampleRate)
    }
    
    @IBAction func playButtonDidClick(_ sender: Any) {
        if currentState == .ready {
            startPlay()
        } else if currentState == .playing {
            stopPlay()
        }
    }
    
    private func startResample(to sampleRate: Int) {
        guard let pcmPath: String = Bundle.main.path(forResource: "fascinated", ofType: "pcm") else {
            print("error: can not find pcm resource.")
            showError()
            return
        }
        currentState = .resampling
        currentPath = FileManager.documentsDir() + "/fascinated_\(sampleRate).pcm"
        ffPresenter.resamlePCM(pcmPath, toSampleRate: sampleRate * 1000, saveTo: currentPath!)
        currentState = .ready
    }
    
    private func startPlay() {
        let ret: Bool = ffPresenter.playResamplePCM()
        if ret == false {
            showError()
            return
        }
        currentState = .playing
    }
    
    private func stopPlay() {
        guard currentState == .playing else {
            return
        }
        ffPresenter.stopPlay()
        currentState = .ready
    }
}
