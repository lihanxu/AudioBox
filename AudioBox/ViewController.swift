//
//  ViewController.swift
//  AudioBox
//
//  Created by anker on 2022/1/28.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var audioRecordButton: UIButton!
    @IBOutlet weak var coverToWavButton: UIButton!
    @IBOutlet weak var playWavButton: UIButton!
    let presenter: FFmpegPresenter = FFmpegPresenter()
    var temPath: String?
    
    @IBOutlet weak var playCreatedButton: UIButton!
    @IBOutlet weak var frequencySlider: UISlider!
    @IBOutlet weak var frequencyValueLabel: UILabel!
    lazy var player: KarplusStrongPlayer = {
        return KarplusStrongPlayer()
    }()
    
    @IBOutlet weak var earsBackButton: UIButton!
    lazy var earsBack: EarsBack = {
        return EarsBack()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        frequencySlider.value = 440.0
        temPath = NSTemporaryDirectory() + "/out.pcm"
    }

    //MARK: - Record PCM & Cover to WAV
    @IBAction func audioRecordButtonDidClick(_ sender: Any) {
        let button = sender as! UIButton
        if button.tag == 0 {
            button.tag = 1
            button.setTitle("Recording", for: .normal)
            DispatchQueue.global().async { [weak self] in
                self?.recordAudio()
            }
        } else {
            button.tag = 0
            button.setTitle("Record PCM", for: .normal)
            DispatchQueue.global().async { [weak self] in
                self?.presenter.stopRecordPCM()
            }
        }
    }
    
    func recordAudio() {
        guard let temPath = self.temPath else {
            return
        }
        guard presenter.initDevice() == true else {
            return
        }
        presenter.startRecordPCM(withPath: temPath)
    }
    @IBAction func coverToWavButtonDidClick(_ sender: Any) {
        presenter.coverToWAV();
    }
    
    @IBAction func playWavButtonDidClick(_ sender: Any) {
        presenter.playWAV();
    }
    
    // MARK: Create audio
    @IBAction func frequencySliderValueChanged(_ sender: Any) {
        let slider = sender as! UISlider
        frequencyValueLabel.text = "\(Int(slider.value))" + "Hz"
        player.updateFrequency(Double(slider.value))
    }
    
    @IBAction func playCreatedButtonDidClick(_ sender: Any) {
        let button = sender as! UIButton
        if button.tag == 0 {
            button.tag = 1
            button.setTitle("Playing", for: .normal)
            player.start()
            player.updateFrequency(Double(frequencySlider.value))
        } else {
            button.tag = 0
            button.setTitle("Play Created", for: .normal)
            player.stop()
        }
    }
    
    //MARK: AUGraph
    @IBAction func earsBackButtonDidClick(_ sender: Any) {
        let button = sender as! UIButton
        if button.tag == 0 {
            button.tag = 1
            button.setTitle("Ears Backing", for: .normal)
            earsBack.start()
        } else {
            button.tag = 0
            button.setTitle("Ears Back", for: .normal)
            earsBack.stop()
        }
    }
}

