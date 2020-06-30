//
//  AudioSampler.swift
//  dbMeter
//
//  Created by Dmytro Hrebeniuk on 2/10/17.
//  Copyright © 2017 Dmytro Hrebeniuk. All rights reserved.
//

import AVFoundation
import CoreMedia

private let kSampleBufferQueue = "com.cavap.SampleAudioBufferQueue"

public typealias AudioSamplerHandler = (_ sampleData: Data, _ timeStamp: Int64, _ timeScale: Int64, _ samplesCount: Int64, _ sampleRate: Int64) -> Void

class AudioSampler: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {

	private let session: AVCaptureSession
	private var audioOutput: AVCaptureAudioDataOutput!
	
	var isSoundEnabled: Bool = true

	var audioSamplerOutputHandler: AudioSamplerHandler?

	init(_ captureSession: AVCaptureSession) {
		self.session = captureSession
	}
	
	func setupOutput() {
		guard self.audioOutput == nil else { return }
		
		self.audioOutput = AVCaptureAudioDataOutput()
		let queue = DispatchQueue(label: kSampleBufferQueue, attributes: [])
		self.audioOutput.setSampleBufferDelegate(self, queue: queue)
		
		if self.session.canAddOutput(self.audioOutput) {
			self.session.addOutput(self.audioOutput)
		}
	}
	
	func unSetupOutput() {
		guard self.audioOutput != nil else { return }
		
		self.session.removeOutput(self.audioOutput)
		self.audioOutput = nil
	}
	
	func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

		if let handler = self.audioSamplerOutputHandler {
			var blockBufferOut: CMBlockBuffer?
			var sizeOut = Int(0)
			
			guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
				return
			}
			
			let streamDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)

			let audioBufferSizeStatus = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, bufferListSizeNeededOut: &sizeOut, bufferListOut: nil, bufferListSize: 0, blockBufferAllocator: nil, blockBufferMemoryAllocator: nil, flags: 0, blockBufferOut: nil)
			guard audioBufferSizeStatus == noErr else {
				return
			}
			            
			var audioBufferList: AudioBufferList = AudioBufferList.allocate(maximumBuffers: MemoryLayout<AudioBufferList>.size + sizeOut).unsafePointer.pointee

			let audioBufferStatus = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, bufferListSizeNeededOut: &sizeOut, bufferListOut: &audioBufferList, bufferListSize: sizeOut, blockBufferAllocator: kCFAllocatorDefault, blockBufferMemoryAllocator: kCFAllocatorDefault, flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, blockBufferOut: &blockBufferOut)
			guard audioBufferStatus == noErr else {
				return
			}

			let sampleRate = streamDescription?.pointee.mSampleRate ?? 0
			
			let audioBuffer = audioBufferList.mBuffers
			let samplesCount = Int64(CMSampleBufferGetNumSamples(sampleBuffer))
			
			let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
			            			
			let data = Data(bytes: UnsafeMutableRawPointer(audioBuffer.mData!), count: Int(audioBuffer.mDataByteSize))
            
			handler(data, presentationTimeStamp.value, Int64(presentationTimeStamp.timescale), samplesCount, Int64(sampleRate))
		}
	}
}
