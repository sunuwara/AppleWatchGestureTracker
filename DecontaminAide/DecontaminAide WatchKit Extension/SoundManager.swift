//
//  SoundManager.swift
//  DecontaminAide WatchKit Extension
//
//  Created by PGCapstone Team on 10/26/20.
//

import Foundation
import AVFoundation
import SoundAnalysis


class SoundManager: ObservableObject {

    let model: MLModel = try! SoundClassifier_copy(configuration: MLModelConfiguration.init()).model

    var audioEngine: AVAudioEngine!
    var inputBus: AVAudioNodeBus!
    var inputFormat:  AVAudioFormat!
    var streamAnalyzer: SNAudioStreamAnalyzer!

    var analysisQueue: DispatchQueue!
    var resultsObserver: ResultsObserver!

    func startAudioEngine() {
        // Create a new audio engine.
        audioEngine = AVAudioEngine()

        // Get the native audio format of the engine's input bus.
        inputBus = AVAudioNodeBus(0)
        inputFormat = audioEngine.inputNode.inputFormat(forBus: inputBus)
        do {
            // Start the stream of audio data.
            try audioEngine.start()
        } catch {
            print("Unable to start AVAudioEngine: \(error.localizedDescription)")
        }

        streamAnalyzer = SNAudioStreamAnalyzer(format: inputFormat)

        resultsObserver = ResultsObserver()

        do {
            // Prepare a new request for the trained model.
            let request = try SNClassifySoundRequest(mlModel: model)
            try streamAnalyzer.add(request, withObserver: resultsObserver)
        } catch {
            print("Unable to prepare request: \(error.localizedDescription)")
            return
        }

        // Serial dispatch queue used to analyze incoming audio buffers.
        analysisQueue = DispatchQueue(label: "com.apple.AnalysisQueue")

        // Install an audio tap on the audio engine's input node.
        audioEngine.inputNode.installTap(onBus: inputBus,
                                         bufferSize: 8192, // 8k buffer
                                         format: inputFormat) { buffer, time in

            // Analyze the current audio buffer.
            self.analysisQueue.async {
                self.streamAnalyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }
    }

    func stopAudioEngine(){
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}

// Observer object that is called as analysis results are found.
class ResultsObserver : NSObject, SNResultsObserving {

    func request(_ request: SNRequest, didProduce result: SNResult) {

        // Get the top classification.
        guard let result = result as? SNClassificationResult,
            let classification = result.classifications.first else { return }

        // Determine the time of this result.
        let formattedTime = String(format: "%.2f", result.timeRange.start.seconds)
        print("Analysis result for audio at time: \(formattedTime)")

        let confidence = classification.confidence * 100.0
        let percent = String(format: "%.2f%%", confidence)

        // Print the result as Type of Sound: percentage confidence.
        print("\(classification.identifier): \(percent) confidence.\n")
        if(Int(confidence) > 95 && classification.identifier == "Cough") {
            print("You Just Coughed")
        }
        if(Int(confidence) > 95 && classification.identifier == "Sneeze") {
            print("You Just Sneezed")
        }
        if(Int(confidence) > 95 && classification.identifier == "Scratch") {
            print("You Just Scratched")
        }
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("The the analysis failed: \(error.localizedDescription)")
    }

    func requestDidComplete(_ request: SNRequest) {
        print("The request completed successfully!")
    }
}
