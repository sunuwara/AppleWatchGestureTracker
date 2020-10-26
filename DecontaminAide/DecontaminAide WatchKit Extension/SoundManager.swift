//
//  SoundManager.swift
//  DecontaminAide WatchKit Extension
//
//  Created by Mitchell Piazza on 10/26/20.
//

import Foundation
import AVFoundation

class SoundManager: AVAudioRecorder, AVAudioRecorderDelegate{
    var audioRecorder: AVAudioRecorder!
    func getDirectory()-> String {
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return dirPath
    }
    
    func recordAudio(){
        
        let recordingName = "audio.m4a"
        let dirPath = getDirectory()
        let pathArray = [dirPath, recordingName]
        guard let filePath = URL(string: pathArray.joined(separator: "/")) else { return }
        
        let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey:12000,
                        AVNumberOfChannelsKey:1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        //start recording
        do {
        audioRecorder = try AVAudioRecorder(url: filePath, settings: settings)
        audioRecorder.delegate = self
        audioRecorder.record()
        } catch {
        print("Recording Failed")
        }
        
        
    }
    
    
    
    
}
