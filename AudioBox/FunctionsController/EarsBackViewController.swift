//
//  EarsBackViewController.swift
//  AudioBox
//
//  Created by anker on 2022/2/9.
//

import UIKit

class EarsBackViewController: UIViewController {
    @IBOutlet weak var startButton: UIButton!
    
    private let earsBackCtr: EarsBack = EarsBack()
    private var isRunning: Bool = false {
        didSet {
            startButton.setTitle(isRunning ? "Pause" : "Start", for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startButton.setTitle("Start", for: .normal)
    }

    @IBAction func startButtonDidClick(_ sender: Any) {
        if isRunning {
            stopEarsBakc()
        } else {
            startEarsBack()
        }
    }
    
    private func startEarsBack() {
        isRunning = true
        earsBackCtr.start()
    }
    
    private func stopEarsBakc() {
        isRunning = false
        earsBackCtr.stop()
    }
}
