//
//  SamplesRenderer.swift
//  RosaKitExample
//
//  Created by Dmytro Hrebeniuk on 12/18/17.
//  Copyright © 2017 Dmytro Hrebeniuk. All rights reserved.
//

import Metal
import CoreMedia

class SamplesMetalRenderer {

	private let device: MTLDevice?
	private let commandQueue: MTLCommandQueue?
	
	init() {
		self.device = MTLCreateSystemDefaultDevice()
		self.commandQueue = self.device?.makeCommandQueue(maxCommandBufferCount: 1)
	}
	
	private var renderPipelineState: MTLRenderPipelineState?
	private var texture: MTLTexture?
	private var commandBuffer: MTLCommandBuffer?
	
    var scaleFactor: Float = 1.0
    
	func setup() {
		self.initializeRenderPipelineState()
	}
	
	private func initializeRenderPipelineState() {
		guard let device = self.device,
			let library = device.makeDefaultLibrary() else {
				return
		}
		
		let pipelineDescriptor = MTLRenderPipelineDescriptor()
		pipelineDescriptor.sampleCount = 1
		pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
		pipelineDescriptor.depthAttachmentPixelFormat = .invalid
		
		pipelineDescriptor.vertexFunction = library.makeFunction(name: "mapTexture")
		pipelineDescriptor.fragmentFunction = library.makeFunction(name: "displayBackTexture")
		
		do {
			try self.renderPipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
		}
		catch {
			assertionFailure("Failed creating a render state pipeline. Can't render the texture without one.")
			return
		}
	}
	
	func render(with renderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable) {
		guard let texture = self.texture else {
			return
		}
		
		guard let renderPipelineState = self.renderPipelineState
			else {
				return
		}
		
		guard let commandBuffer = self.commandQueue?.makeCommandBuffer() else {
			return
		}

		let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
		encoder?.pushDebugGroup("RenderFrame")
		encoder?.setRenderPipelineState(renderPipelineState)
		encoder?.setFragmentTexture(texture, index: 0)
        
		encoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
		encoder?.popDebugGroup()
		encoder?.endEncoding()
		
		commandBuffer.present(drawable)
		commandBuffer.commit()
	}
	
	func send(texture: MTLTexture) {
		self.texture = texture
	}
	
	func requestRenderedTexture() -> MTLTexture? {
		return self.texture
	}
	
}
