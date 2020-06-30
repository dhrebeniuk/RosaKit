//
//  VolumeRecognizer.swift
//  dbMeter
//
//  Created by Dmytro Hrebeniuk on 2/10/17.
//  Copyright © 2017 Dmytro Hrebeniuk. All rights reserved.
//

import AVFoundation

public typealias MicrophoneReaderHandler = (_ audioPowerBuffer: [Double]) -> Void

class MicrophoneReader {

    private static let kIntToDoubleScale: Double = 32768.0

	private(set) var audioRecordingManager: AudioRecordingManager = AudioRecordingManager()
	
    func startReading(handler: @escaping MicrophoneReaderHandler) {
		let audioRecordingManager = AudioRecordingManager()
		self.audioRecordingManager = audioRecordingManager
		
		try? audioRecordingManager.setup() { (data, timestamp, timeScale, samplesCount, sampleRate) in
			
            let powers = data.withUnsafeBytes { rawPointer -> [Double] in
                rawPointer.bindMemory(to: Int16.self)
                    .map { Double($0)/Self.kIntToDoubleScale }
            }
            handler(powers)
		}
		
		audioRecordingManager.startRecording()
	}
}
