////
////  EarsBack.swift
////  TestFFmpeg
////
////  Created by anker on 2022/1/28.
////
//
//import Foundation
//import AudioToolbox
//
//let INPUT_BUS: Int = 1
//let OUTPUT_BUS: Int = 0
//
//class EarsBack: NSObject {
//    var audioGraph: AUGraph?
//    var playerNode: AUNode
//    var playerUnit: AudioUnit?
//    var outputFormat: AudioStreamBasicDescription
//
//    override init() {
//        var status: OSStatus = noErr
//        status = NewAUGraph(&audioGraph)
//        CheckStatus(status, "NewAUGraph error!!!", true)
//
//        var ioDes: AudioComponentDescription = AudioComponentDescription(componentType: kAudioUnitType_Output,
//                                                                         componentSubType: kAudioUnitSubType_RemoteIO,
//                                                                         componentManufacturer: kAudioUnitManufacturer_Apple,
//                                                                         componentFlags: 0,
//                                                                         componentFlagsMask: 0)
//        playerNode = AUNode()
//        status = AUGraphAddNode(audioGraph!, &ioDes, &(playerNode))
//        CheckStatus(status, "AUGraphAddNode error!!!", true)
//        status = AUGraphOpen(audioGraph!)
//        CheckStatus(status, "AUGraphOpen error!!!", true)
//        status = AUGraphNodeInfo(audioGraph!, playerNode, nil, &playerUnit)
//        CheckStatus(status, "AUGraphNodeInfo error!!!", true)
//
//        outputFormat = AudioStreamBasicDescription(mSampleRate: 44100.0,
//                                                   mFormatID: kAudioFormatLinearPCM,
//                                                   mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
//                                                   mBytesPerPacket: 4,
//                                                   mFramesPerPacket: 1,
//                                                   mBytesPerFrame: 4,
//                                                   mChannelsPerFrame: 2,
//                                                   mBitsPerChannel: 16,
//                                                   mReserved: 0)
//
//        super.init()
//
//        status = AudioUnitSetProperty(playerUnit!, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &outputFormat, UInt32(MemoryLayout.size(ofValue: outputFormat)))
//        CheckStatus(status, "AudioUnitSetProperty kAudioUnitProperty_StreamFormat error!!!", true)
//        var flag: Int  = 1
//        status = AudioUnitSetProperty(playerUnit!, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flag, UInt32(MemoryLayout.size(ofValue: flag)))
//        CheckStatus(status, "AudioUnitSetProperty kAudioOutputUnitProperty_EnableIO error!!!", true)
//
//        var renderProc: AURenderCallbackStruct = AURenderCallbackStruct(inputProc: MyAURenderCallback,
//                                                                        inputProcRefCon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
//        AUGraphSetNodeInputCallback(audioGraph!, playerNode, 0, &renderProc);
//
//
//        AUGraphInitialize(audioGraph!)
//        status = AUGraphUpdate(audioGraph!, nil)
//        CheckStatus(status, "AUGraphUpdate error!!!", true)
//    }
//
//    func start() {
//        DispatchQueue.global().async { [weak self] in
//            guard let sself = self else {
//                return
//            }
//            var isRunning: DarwinBoolean = false
//            AUGraphIsRunning(sself.audioGraph!, &isRunning)
//            if isRunning == false {
//                AUGraphStart(sself.audioGraph!)
//            }
//        }
//    }
//
//    func stop() {
//        DispatchQueue.global().async { [weak self] in
//            guard let sself = self else {
//                return
//            }
//            var isRunning: DarwinBoolean = false
//            AUGraphIsRunning(sself.audioGraph!, &isRunning)
//            if isRunning == true {
//                AUGraphStop(sself.audioGraph!)
//            }
//        }
//    }
//
//    var MyAURenderCallback: AURenderCallback? = { ( inRefCon: UnsafeMutableRawPointer, ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>, inTimeStamp: UnsafePointer<AudioTimeStamp>, inBusNumber: UInt32, inNumberFrames: UInt32, ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus in
//        return AudioUnitRender(inRefCon.playerUnit!, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData!)
//    }
//}
