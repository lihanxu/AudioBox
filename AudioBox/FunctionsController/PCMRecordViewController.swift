//
//  PCMRecordViewController.swift
//  AudioBox
//
//  Created by anker on 2022/2/8.
//

import UIKit

class PCMRecordViewController: UIViewController {
    private enum State {
        case idle
        case ready
        case recording
        case playing
    }
    @IBOutlet weak var durationTime: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    private var pcmState: State = .idle {
        didSet {
            switch pcmState {
            case .idle:
                break
            case .ready:
                recordButton.isEnabled = true
                recordButton.setTitle("Start Record", for: .normal)
                playButton.isEnabled = true
                playButton.setTitle("Play", for: .normal)
            case .recording:
                recordButton.isEnabled = true
                recordButton.setTitle("Stop Record", for: .normal)
                playButton.isEnabled = false
            case .playing:
                recordButton.isEnabled = false
                playButton.isEnabled = true
                playButton.setTitle("Pause", for: .normal)
            }
        }
    }
    private var timer: Timer?
    private var duration: Int = 0
    
    let ffPresenter: FFmpegPresenter = FFmpegPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    private func initUI() {
        durationTime.text = "00:00"
        recordButton.setTitle("Start Record", for: .normal)
        playButton.setTitle("Play", for: .normal)
        playButton.isEnabled = false
    }

    @IBAction private func recordButtonDidClick(_ sender: Any) {
        if pcmState == .recording {
            stopRecordPCM()
        } else {
            startRecordPCM()
        }
    }
    
    @IBAction private func playButtonDidClick(_ sender: Any) {
        if pcmState == .playing {
            stopPlayPCM()
        } else {
            startPlayPCM()
        }
    }
    
    // MARK: Action
    private func startRecordPCM() {
        durationTime.text = "00:00"
        duration = 0
        let temPath = FileManager.documentsDir() + "/out.pcm"
        let ret = ffPresenter.startRecordPCM(withPath: temPath)
        guard ret else {
            showError()
            return
        }
        pcmState = .recording
        cancelTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.durationTime.text = String(format: "%02d:%02d", (self?.duration ?? 0) / 60, (self?.duration ?? 0) % 60)
            self?.duration += 1
        }
        timer?.fire()
    }
    
    private func stopRecordPCM() {
        pcmState = .ready
        cancelTimer()
        ffPresenter.stopRecordPCM()
    }
    
    private func cancelTimer() {
        guard timer?.isValid == true else { return }
        timer?.invalidate()
        timer = nil
    }
    
    private func startPlayPCM() {
        let ret = ffPresenter.playRecordedPCM()
        guard ret else {
            showError()
            return;
        }
        pcmState = .playing
        cancelTimer()
        var ramaining = duration
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.durationTime.text = String(format: "%02d:%02d", ramaining / 60, ramaining % 60)
            ramaining -= 1
        }
        timer?.fire()
    }
    
    private func stopPlayPCM() {
        pcmState = .ready
        cancelTimer()
        ffPresenter.stopPlay()
    }
}
