//
//  NeonEffect.swift
//  SwiftCircularAudioVisualizer
//
//  Created by Ha Jong Myeong on 2023/04/12.
//
import SwiftUI

struct Constants {
    static let numberOfBars: Int = 32
    static let intensityFactor: Float = 2
    static let intensityThreshold: Float = 100
}

struct CircularAudioVisualizer: View {
    @State private var isPlayingAudio = false
    @State private var audioData: [Float] = Array(repeating: 0, count: Constants.numberOfBars)
    private let audioProcessor = AudioProcessor.sharedInstance
    private let updateTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    let innerRadius: CGFloat = 80
    let maxBarLength: CGFloat = 150

    var body: some View {
        VStack {
            ZStack {
                ForEach(0 ..< Constants.numberOfBars) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            Color(
                                hue: 0.5 - Double((audioData[index] / Constants.intensityThreshold) / 5),
                                saturation: 1,
                                brightness: 1,
                                opacity: 0.7
                            )
                        )
                        .frame(width: 4, height: min(CGFloat(audioData[index] * Constants.intensityFactor), maxBarLength))
                        .modifier(NeonEffect(color: Color.white.opacity(0.75), radius: 4, x: 1, y: 1))
                        .offset(x: 0, y: -innerRadius - min(CGFloat(audioData[index] * Constants.intensityFactor / 2), maxBarLength / 2))
                        .rotationEffect(.degrees(Double(index) / Double(Constants.numberOfBars) * 360))
                }

                Circle()
                    .fill(Color.black)
                    .frame(width: 2 * innerRadius, height: 2 * innerRadius)
                    .onTapGesture {
                        print("tapped")
                    }
            }
            .frame(width: 2 * (innerRadius + CGFloat(Constants.intensityThreshold * Constants.intensityFactor)), height: 2 * (innerRadius + CGFloat(Constants.intensityThreshold * Constants.intensityFactor)))

            Button(action: audioPlaybackButtonTapped) {
                Image(systemName: "\(isPlayingAudio ? "pause" : "play").circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
            }
            .foregroundColor(.secondary)
        }
        .onReceive(updateTimer, perform: refreshAudioData)
    }

    func refreshAudioData(_: Date) {
        if isPlayingAudio {
            withAnimation(.easeOut(duration: 0.08)) {
                audioData = audioProcessor.frequencyMagnitudes.map {
                    min($0, Constants.intensityThreshold)
                }
            }
        }
    }

    func audioPlaybackButtonTapped() {
        if isPlayingAudio {
            audioProcessor.audioPlayerNode.pause()
        } else {
            audioProcessor.audioPlayerNode.play()
        }
        isPlayingAudio.toggle()
    }
}
