//
//  AudioRecordingManager.swift
//  dbMeter
//
//  Created by Dmytro Hrebeniuk on 2/10/17.
//  Copyright © 2017 Dmytro Hrebeniuk. All rights reserved.
//

import AVFoundation

open class AudioRecordingManager {
	
	private let session: AVCaptureSession
	private let audioRecorder: AudioRecorder
	private let audioSampler: AudioSampler

	public convenience init() {
		self.init(AVCaptureSession())
	}
	
	public init(_ captureSession: AVCaptureSession) {
		self.session = captureSession
		
		self.audioRecorder = AudioRecorder(captureSession)
		self.audioSampler = AudioSampler(captureSession)
	}
	
	// MARK: Public

	open func setup(audioHandler: @escaping AudioSamplerHandler) throws {
		let isRecordingRunning = self.session.isRunning
		
		if isRecordingRunning {
			self.stopRecording()
		}
		
		try self.audioRecorder.setupRecordingSession()
		
		self.audioSampler.audioSamplerOutputHandler = audioHandler
		self.audioSampler.setupOutput()
		
		if isRecordingRunning {
			self.startRecording()
		}
	}
    
    open func setup(audioDeviceNameHandler: @escaping AudioRecorderDeviceNameHandler) {
        self.audioRecorder.audioRecorderDeviceNameHandler = audioDeviceNameHandler
    }
	
	open func startRecording() {
		if !self.session.isRunning {
			self.session.startRunning()
		}
	}
	
	open func stopRecording() {
		if self.session.isRunning {
			self.session.stopRunning()
		}
	}
	
}
