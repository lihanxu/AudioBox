//
//  RootTableViewController.swift
//  AudioBox
//
//  Created by anker on 2022/2/8.
//

import UIKit

class RootTableViewController: UITableViewController {
    enum Functions: String {
        case PCM = "Record & Play PCM"
        case PCMResample = "PCM Resample"
        case AudioEncoder = "Audio Encoder"
        case AudioDecoder = "Audio Decoder"
        case EarsBack = "Ears Back"
        case AudioSpectrum = "Audio Spectrum"
        case CreateAudio = "Create Audio"
    }
    
    let funcsList: Array<Functions> = [.PCM, .PCMResample, .AudioEncoder, .AudioDecoder, .EarsBack, .AudioSpectrum, .CreateAudio]
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return funcsList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AudioFunctionsCell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row + 1). " + funcsList[indexPath.row].rawValue
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let funcUnit = funcsList[indexPath.row]
        var viewCtr: UIViewController?;
        switch funcUnit {
        case .PCM:
            viewCtr = PCMRecordViewController(nibName: "PCMRecordViewController", bundle: nil)
        case .PCMResample:
            viewCtr = PCMResampleViewController(nibName: "PCMResampleViewController", bundle: nil)
        case .AudioEncoder:
            viewCtr = AudioEncoderViewController(nibName: "AudioEncoderViewController", bundle: nil)
        case .AudioDecoder:
            viewCtr = AudioDecoderViewController(nibName: "AudioDecoderViewController", bundle: nil)
        case .EarsBack:
            viewCtr = EarsBackViewController(nibName: "EarsBackViewController", bundle: nil)
        case .AudioSpectrum:
            viewCtr = AudioSpectrumViewController(nibName: "AudioSpectrumViewController", bundle: nil)
        case .CreateAudio:
            viewCtr = AudioCreateViewController(nibName: "AudioCreateViewController", bundle: nil)
        }
        guard let vc = viewCtr else { return }
        vc.title = funcUnit.rawValue;
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
