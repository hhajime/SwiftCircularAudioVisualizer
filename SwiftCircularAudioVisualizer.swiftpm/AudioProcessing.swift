//
//  AudioProcessing.swift
//  SwiftCircularAudioVisualizer
//
//  Created by Ha Jong Myeong on 2023/04/11.
//

import AVFoundation
import Accelerate

final class AudioProcessor {
    static let sharedInstance = AudioProcessor()
    
    private let audioEngine = AVAudioEngine()
    private let bufferCapacity = 1024
    
    let audioPlayerNode = AVAudioPlayerNode()
    var frequencyMagnitudes: [Float] = []
    
    private init() {
        setupAudioEngine()
        initializeFFT()
    }
    
    private func setupAudioEngine() {
        _ = audioEngine.mainMixerNode
        audioEngine.prepare()
        
        try! audioEngine.start()
        let audioFileURL = Bundle.main.url(forResource: "music", withExtension: "mp3")!
        let audioFile = try! AVAudioFile(forReading: audioFileURL)
        let audioFormat = audioFile.processingFormat
        
        audioEngine.attach(audioPlayerNode)
        audioEngine.connect(audioPlayerNode, to: audioEngine.mainMixerNode, format: audioFormat)
        audioPlayerNode.scheduleFile(audioFile, at: nil)
    }
    
    private func initializeFFT() {
        let fftConfiguration = vDSP_DFT_zop_CreateSetup(
            nil,
            UInt(bufferCapacity),
            vDSP_DFT_Direction.FORWARD
        )
        
        audioEngine.mainMixerNode.installTap(
            onBus: 0,
            bufferSize: UInt32(bufferCapacity),
            format: nil
        ) { [weak self] buffer, _ in
            guard let self = self else { return }
            let channelDataPointer = buffer.floatChannelData?[0]
            self.frequencyMagnitudes = self.performFFT(data: channelDataPointer!, configuration: fftConfiguration!)
        }
    }
    
    private func performFFT(data: UnsafeMutablePointer<Float>, configuration: OpaquePointer) -> [Float] {
        let realInput = generateRealInput(from: data)
        var (realOutput, imaginaryOutput) = createInOut()
        
        vDSP_DFT_Execute(configuration, realInput, realInput, &realOutput, &imaginaryOutput)
        
        let magnitudes = computeMagnitudes(realOutput: &realOutput, imaginaryOutput: &imaginaryOutput)
        let normalizedMagnitudes = normalize(magnitudes: magnitudes)
        
        return normalizedMagnitudes
    }
    
    private func generateRealInput(from data: UnsafeMutablePointer<Float>) -> [Float] {
        var realInput = [Float](repeating: 0, count: bufferCapacity)
        for index in 0 ..< bufferCapacity {
            realInput[index] = data[index]
        }
        return realInput
    }
    
    private func createInOut() -> (real: [Float], imaginary: [Float]) {
        let realOutput = [Float](repeating: 0, count: bufferCapacity)
        let imaginaryOutput = [Float](repeating: 0, count: bufferCapacity)
        return (realOutput, imaginaryOutput)
    }
    
    private func computeMagnitudes(realOutput: inout [Float], imaginaryOutput: inout [Float]) -> [Float] {
        var magnitudes = [Float](repeating: 0, count: Constants.numberOfBars)
        
        realOutput.withUnsafeMutableBufferPointer { realBufferPointer in
            imaginaryOutput.withUnsafeMutableBufferPointer { imaginaryBufferPointer in
                var complex = DSPSplitComplex(realp: realBufferPointer.baseAddress!, imagp: imaginaryBufferPointer.baseAddress!)
                vDSP_zvabs(&complex, 1, &magnitudes, 1, UInt(Constants.numberOfBars))
            }
        }

        return magnitudes
    }

    private func normalize(magnitudes: [Float]) -> [Float] {
        var normalizedMagnitudes = [Float](repeating: 0.0, count: Constants.numberOfBars)
        var scalingFactor = Float(1)
        vDSP_vsmul(magnitudes, 1, &scalingFactor, &normalizedMagnitudes, 1, UInt(Constants.numberOfBars))
        return normalizedMagnitudes
    }
}
