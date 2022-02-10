//
//  AudioDecoderViewController.swift
//  AudioBox
//
//  Created by anker on 2022/2/10.
//

import UIKit

class AudioDecoderViewController: UIViewController {
    private enum State {
        case idle
        case decoding
        case ready
        case playing
    }
    
    private enum DecodeType {
        case AAC
    }
    
    @IBOutlet weak var desLabel: UILabel!
    @IBOutlet weak var aacButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    let ffPresenter: FFmpegPresenter = FFmpegPresenter()
    private var currentEncodeType: DecodeType = .AAC
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
            desLabel.text = "Try click decode button ~"
            aacButton.isEnabled = true
            playButton.isEnabled = false
            break
        case .decoding:
            desLabel.text = "Decoding, please wait..."
            aacButton.isEnabled = false
            playButton.isEnabled = false
            break
        case .ready:
            desLabel.text = "Decode done, tye play it!"
            aacButton.isEnabled = true
            playButton.isEnabled = true
            break
        case .playing:
            desLabel.text = "playing..."
            aacButton.isEnabled = false
            playButton.isEnabled = true
            playButton.setTitle("Pause", for: .normal)
            break
        }
    }
    
    @IBAction func accButtonDidClick(_ sender: Any) {
        if currentState == .idle || currentState == .ready {
            startDecodeAAC()
        }
    }
    

    @IBAction func playButtonDidClick(_ sender: Any) {
        if currentState == .ready {
            startPlay()
        } else if currentState == .playing {
            stopPlay()
        }
    }
    
    private func startDecodeAAC() {
        guard let aacPath: String = Bundle.main.path(forResource: "fascinated", ofType: "aac") else {
            print("error: can not find fascinated.aac resource.")
            showError()
            return
        }
        let pcmPath: String = FileManager.documentsDir() + "/fascinated_decode.pcm"
        currentState = .decoding
        ffPresenter.decodeAAC(aacPath, saveTo: pcmPath)
        currentState = .ready
    }
    
    private func startPlay() {
        var ret: Bool = false
        switch currentEncodeType {
        case .AAC:
            ret = ffPresenter.playDecodedPCM()
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
