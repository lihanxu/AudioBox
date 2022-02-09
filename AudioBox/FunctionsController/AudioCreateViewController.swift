//
//  AudioCreateViewController.swift
//  AudioBox
//
//  Created by anker on 2022/2/9.
//

import UIKit

class AudioCreateViewController: UIViewController {
    
    @IBOutlet weak var frequencySlider: UISlider!
    @IBOutlet weak var frequencyValueLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    private let player: KarplusStrongPlayer = KarplusStrongPlayer()
    private var isPlaying: Bool = false {
        didSet {
            playButton.setTitle(isPlaying ? "Pause" : "Play", for: .normal)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        frequencyValueLabel.text = "440Hz"
        frequencySlider.setValue(440, animated: true)
        playButton.setTitle("Play", for: .normal)
    }

    @IBAction func frequencySliderValueChanged(_ sender: Any) {
        let slider = sender as! UISlider
        frequencyValueLabel.text = "\(Int(slider.value))" + "Hz"
        player.updateFrequency(Double(slider.value))
    }
    
    @IBAction func playButtonDidClick(_ sender: Any) {
        if isPlaying {
            player.stop()
        } else {
            player.start()
        }
        isPlaying = !isPlaying
    }
}
