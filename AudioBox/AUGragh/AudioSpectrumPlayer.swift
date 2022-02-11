//
//  AudioSpectrumPlayer.swift
//  AudioBox
//
//  Created by anker on 2022/2/11.
//

import UIKit
import AVFAudio
import Accelerate

protocol AudioSpectrumPlayerDelegate: NSObjectProtocol {
    func player(_ player: AudioSpectrumPlayer, didGenerateSpectrum spectra: [[Float]])
}

class AudioSpectrumPlayer: NSObject {
    weak var delegate: AudioSpectrumPlayerDelegate?
    private let engine: AVAudioEngine = AVAudioEngine()
    private let player: AVAudioPlayerNode = AVAudioPlayerNode()
    private var isPlaying: Bool = false

    private var fftSize: Int = 1024 * 2
    private lazy var fftSetup: FFTSetup? = vDSP_create_fftsetup(vDSP_Length(Int(round(log2(Double(fftSize))))), FFTRadix(kFFTRadix2))
    
    public var frequencyBands: Int = 80 //频带数量
    public var startFrequency: Float = 100 //起始频率
    public var endFrequency: Float = 18000 //截止频率
    private lazy var bands: [(lowerFrequency: Float, upperFrequency: Float)] = {
        var bands = [(lowerFrequency: Float, upperFrequency: Float)]()
        //1：根据起止频谱、频带数量确定增长的倍数：2^n
        let n = log2(endFrequency/startFrequency) / Float(frequencyBands)
        var nextBand: (lowerFrequency: Float, upperFrequency: Float) = (startFrequency, 0)
        for i in 1...frequencyBands {
            //2：频带的上频点是下频点的2^n倍
            let highFrequency = nextBand.lowerFrequency * powf(2, n)
            nextBand.upperFrequency = i == frequencyBands ? endFrequency : highFrequency
            bands.append(nextBand)
            nextBand.lowerFrequency = highFrequency
        }
        return bands
    }()
    
    //缓存上一帧的值
    private var spectrumBuffer = [[Float]]()
    //缓动系数，数值越大动画越"缓"
    public var spectrumSmooth: Float = 0.5 {
        didSet {
            spectrumSmooth = max(0.0, spectrumSmooth)
            spectrumSmooth = min(1.0, spectrumSmooth)
        }
    }
    
    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }

    override init() {
        super.init()
        //将player挂载到engine上，再把player与engine的mainMixerNode连接起来就完成了AVAudioEngine的整个节点图创建
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(fftSize), format: nil) { [weak self] buffer, time in
            self?.handleBuffer(buffer, time: time)
        }
        //在调用engine的strat()方法开始启动engine之前，需要通过prepare()方法提前分配相关资源
        engine.prepare()
        try? engine.start()
    }
    
    func play(withFileName name: String) {
        guard let fileURL = Bundle.main.url(forResource: name, withExtension: nil),
              let audioFile = try? AVAudioFile(forReading: fileURL) else {
            return
        }
        isPlaying = true
        player.stop()
        player.scheduleFile(audioFile, at: nil, completionHandler: nil)
        player.play()
    }
    
    func stop() {
        isPlaying = false
        player.stop()
    }
    
    private func handleBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        if isPlaying == false {
            return
        }
        
        //这句的作用是确保每次回调中buffer的frameLength是fftSize大小，详见：https://stackoverflow.com/a/27343266/6192288
        if buffer.frameLength !=  AVAudioFrameCount(fftSize) {
            buffer.frameLength = AVAudioFrameCount(fftSize)
        }
        
        let amplitudes: [[Float]] = fft(buffer)
        let aWeights = createFrequencyWeights()
        
        //1: 初始化spectrumBuffer
        if spectrumBuffer.count == 0 {
           for _ in 0..<amplitudes.count {
               spectrumBuffer.append(Array<Float>(repeating: 0, count: frequencyBands))
           }
        }
        
        for (index, amplitude) in amplitudes.enumerated() {
            let weightedAmplitudes = amplitude.enumerated().map {(index, element) in
                return element * aWeights[index]
            }
            var spectrum = bands.map {
                findMaxAmplitude(for: $0, in: weightedAmplitudes, with: Float(buffer.format.sampleRate) / Float(fftSize)) * 5.0
            }
            spectrum = highlightWaveform(spectrum: spectrum)
            let zipped = zip(spectrumBuffer[index], spectrum)
            spectrumBuffer[index] = zipped.map { $0.0 * spectrumSmooth + $0.1 * (1 - spectrumSmooth) }
        }
//        print(spectra)
        self.delegate?.player(self, didGenerateSpectrum: spectrumBuffer)
    }
    
    private func fft(_ buffer: AVAudioPCMBuffer) -> [[Float]] {
        var amplitudes: [[Float]] = []
        guard let floatChannelData: UnsafePointer<UnsafeMutablePointer<Float>> = buffer.floatChannelData else {
            return amplitudes
        }
        
        //1：抽取buffer中的样本数据
        var channels:UnsafePointer<UnsafeMutablePointer<Float>>
        let channelCount: Int = Int(buffer.format.channelCount)
        let isInterleaved: Bool = buffer.format.isInterleaved
        
        if isInterleaved {
            let interleavedData: UnsafeBufferPointer<Float> = UnsafeBufferPointer(start: floatChannelData[0], count: fftSize * channelCount)
            var channelsTemp: [UnsafeMutablePointer<Float>] = []
            for i in 0..<channelCount {
                var channelData: [Float] = stride(from: i, to: interleavedData.count, by: channelCount).map { interleavedData[$0] }
                channelsTemp.append(UnsafeMutablePointer(&channelData))
            }
            channels = UnsafePointer(channelsTemp)
        } else {
            channels = floatChannelData
        }
        
        for i in 0..<channelCount {
            let channel = channels[i]
            
            //2: 加汉宁窗
            var window: [Float]  = [Float](repeating: 0.0, count: Int(fftSize))
            vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
            vDSP_vmul(channel, 1, window, 1, channel, 1, vDSP_Length(fftSize))
            
            //3: 将实数包装成FFT要求的复数fftInOut，既是输入也是输出
            var realp: [Float] = [Float](repeating: 0.0, count: Int(fftSize / 2))
            var imagp: [Float] = [Float](repeating: 0.0, count: Int(fftSize / 2))
            var fftInOut: DSPSplitComplex = DSPSplitComplex(realp: &realp, imagp: &imagp)
            channel.withMemoryRebound(to: DSPComplex.self, capacity: fftSize) { (typeConvertedTransferBuffer) -> Void in
                vDSP_ctoz(typeConvertedTransferBuffer, 2, &fftInOut, 1, vDSP_Length(fftSize / 2))
            }
            
            //4：执行FFT
            vDSP_fft_zrip(fftSetup!, &fftInOut, 1, vDSP_Length(round(log2(Double(fftSize)))), FFTDirection(FFT_FORWARD))
            
            //5：调整FFT结果，计算振幅
            fftInOut.imagp[0] = 0
            let fftNormFactor = Float(1.0 / Float(fftSize))
            vDSP_vsmul(fftInOut.realp, 1, [fftNormFactor], fftInOut.imagp, 1, vDSP_Length(fftSize / 2))
            vDSP_vsmul(fftInOut.imagp, 1, [fftNormFactor], fftInOut.realp, 1, vDSP_Length(fftSize / 2))
            var channelAmplitudes: [Float] = [Float](repeating: 0.0, count: Int(fftSize / 2))
            vDSP_zvabs(&fftInOut, 1, &channelAmplitudes, 1, vDSP_Length(fftSize / 2))
            channelAmplitudes[0] = channelAmplitudes[0] / 2
            amplitudes.append(channelAmplitudes)
        }
        
        return amplitudes
    }
    
    private func findMaxAmplitude(for band:(lowerFrequency: Float, upperFrequency: Float), in amplitudes: [Float], with bandWidth: Float) -> Float {
        let startIndex = Int(round(band.lowerFrequency / bandWidth))
        let endIndex = min(Int(round(band.upperFrequency / bandWidth)), amplitudes.count - 1)
        return amplitudes[startIndex...endIndex].max()!
    }
    
    // 响度优化
    private func createFrequencyWeights() -> [Float] {
        let Δf = 44100.0 / Float(fftSize)
        let bins = fftSize / 2 //返回数组的大小
        var f = (0..<bins).map { Float($0) * Δf}
        f = f.map { $0 * $0 }
        
        let c1 = powf(12194.217, 2.0)
        let c2 = powf(20.598997, 2.0)
        let c3 = powf(107.65265, 2.0)
        let c4 = powf(737.86223, 2.0)
        
        let num = f.map { c1 * $0 * $0 }
        let den = f.map { ($0 + c2) * sqrtf(($0 + c3) * ($0 + c4)) * ($0 + c1) }
        let weights = num.enumerated().map { (index, ele) in
            return 1.2589 * ele / den[index]
        }
        return weights
    }
    
    // 帧内平滑优化
    private func highlightWaveform(spectrum: [Float]) -> [Float] {
        //1: 定义权重数组，数组中间的5表示自己的权重
        //   可以随意修改，个数需要奇数
        let weights: [Float] = [1, 2, 3, 5, 3, 2, 1]
        let totalWeights = Float(weights.reduce(0, +))
        let startIndex = weights.count / 2
        //2: 开头几个不参与计算
        var averagedSpectrum = Array(spectrum[0..<startIndex])
        for i in startIndex..<spectrum.count - startIndex {
            //3: zip作用: zip([a,b,c], [x,y,z]) -> [(a,x), (b,y), (c,z)]
            let zipped = zip(Array(spectrum[i - startIndex...i + startIndex]), weights)
            let averaged = zipped.map { $0.0 * $0.1 }.reduce(0, +) / totalWeights
            averagedSpectrum.append(averaged)
        }
        //4：末尾几个不参与计算
        averagedSpectrum.append(contentsOf: Array(spectrum.suffix(startIndex)))
        return averagedSpectrum
    }

}
