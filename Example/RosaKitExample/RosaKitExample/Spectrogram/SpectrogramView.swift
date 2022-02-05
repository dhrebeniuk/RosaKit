//
//  SpectrogramView.swift
//  RosaKitExample
//
//  Created by Dmytro Hrebeniuk on 1/5/19.
//  Copyright © 2019 Dmytro Hrebeniuk. All rights reserved.
//

import Cocoa
import Metal
import MetalKit
import RosaKit

protocol SpectrogramViewDataSource: class {
    
    func elementsCountInSpectrogram(view: SpectrogramView) -> Int
    
    func elementsValueInSpectrogram(view: SpectrogramView, at index: Int) -> [Double]
    
}

class SpectrogramView: NSScrollView {

    let samplesMetalRenderer = SamplesMetalRenderer()
    
    @IBInspectable open var backgroundChartColor: NSColor = .black
    @IBInspectable open var chartLineColor: NSColor = .white

    private static let leftMarginToSnap: CGFloat = 20.0
    private static var labelWidth: CGFloat = 200.0
    
    var elementWidth: CGFloat = 20.0
    
    weak var delegate: SpectrogramViewDataSource?

    private var scrollNotificationHandler: NSObjectProtocol?
    
    private var metalView: MTKView?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
             
        samplesMetalRenderer.setup()

        initializeMetalView()
        
        scrollNotificationHandler.map { NotificationCenter.default.removeObserver($0) }
        scrollNotificationHandler = NotificationCenter.default.addObserver(forName: NSScrollView.didLiveScrollNotification, object: self, queue: .main) { [weak self] _ in
            self?.setNeedsDisplay(self?.bounds ?? .zero)
        }
    }
    
    private func initializeMetalView() {
        let metalView = MTLCreateSystemDefaultDevice().map { MTKView(frame: self.bounds, device: $0) }
        metalView?.delegate = self
        metalView?.framebufferOnly = false
        metalView?.colorPixelFormat = .bgra8Unorm
        metalView?.preferredFramesPerSecond = 30
        metalView?.enableSetNeedsDisplay = true
        metalView.map { self.addSubview($0) }
        
        self.metalView = metalView
    }
    
    func reloadData(magnitifyIfNeeded: Bool = true) {
        setNeedsDisplay(bounds)
        
        let elementsCount = delegate?.elementsCountInSpectrogram(view: self) ?? 0
        let documentSize = documentView?.frame.size ?? .zero
        
        let shouldMagnitityDelta = abs(contentView.bounds.maxX - documentSize.width)
        let shouldMagnitityToLeft = shouldMagnitityDelta <= SpectrogramView.leftMarginToSnap
        
        let documentWidth = max(elementWidth*CGFloat(elementsCount), frame.width)
        documentView?.setFrameSize(NSSize(width: documentWidth, height: documentSize.height))
        
        if shouldMagnitityToLeft, magnitifyIfNeeded {
            let horizontalOffset = max(documentWidth - bounds.width, 0.0)
            contentView.bounds = contentView.bounds.offsetBy(dx: horizontalOffset, dy: 0.0)
        }
        else if !magnitifyIfNeeded {
            contentView.bounds = CGRect(origin: .zero, size: contentView.bounds.size)
        }
        layoutMetalView()
    }
    
    private func layoutMetalView() {
        self.samplesMetalRenderer.scaleFactor = Float(elementWidth)
        
        self.metalView?.frame = NSRect(origin: NSPoint(x: 0.0, y: 0.0), size: NSSize(width: frame.size.width, height: bounds.size.height - 40.0))
    }
    
    override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)
        
        reloadData()
    }
    
    private func redrawSpectrogram() {
        let rect = self.documentVisibleRect
        
        let elementsCount = delegate?.elementsCountInSpectrogram(view: self) ?? 0
        
        guard elementsCount > 1 else {
            return
        }
        
        let startElement = Int(rect.origin.x/elementWidth)
        let endElement = Int(ceil(rect.maxX/elementWidth) + 1)
        
        guard startElement >= 0 else {
            return
        }
        
        guard startElement < endElement else {
            return
        }
        
        var bytes = [UInt8]()
            
        let cols = endElement - startElement - 1
        let items = delegate?.elementsValueInSpectrogram(view: self, at: 0) ?? [Double]()
        let rows = items.count
        
        for index in startElement...endElement-1 {
            let items = delegate?.elementsValueInSpectrogram(view: self, at: index) ?? [Double]()
            if items.count > 0 {
                for value in items {
                    if value.isNaN == false {
                        let dbValue = value*100
                        bytes.append(UInt8(round(min(max(dbValue, 0), 255))))
                    }
                    else {
                        bytes.append(0)
                    }
                }
            }
            else {
                bytes.append(contentsOf: [UInt8](repeating: 0, count: rows))
            }
        }
        
        let texture = MTLCreateSystemDefaultDevice()?.createRedTexture(from: bytes, width: rows, height: cols)
        
        texture.map {
            samplesMetalRenderer.send(texture: $0)
        }
        
        metalView.map {
            $0.setNeedsDisplay($0.frame)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        redrawSpectrogram()
        
        let rect = self.documentVisibleRect

        let elementsCount = delegate?.elementsCountInSpectrogram(view: self) ?? 0
               
        guard elementsCount > 1 else {
           return
        }
        
        let startElement = abs(Int(rect.origin.x/elementWidth))
        let endElement = min(Int(ceil(rect.maxX/elementWidth) + 1), elementsCount)
        
        guard startElement < endElement else {
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "mm:ss"
        
        let offset = contentView.bounds.origin.x
        let localOffset = offset
        
        let globalOffset = offset

        let strideBy = Int(SpectrogramView.labelWidth)
        let audioLength = localOffset + contentView.bounds.width

        let range = stride(from: CGFloat(0.0), through: audioLength, by: CGFloat.Stride(strideBy))
        for position in range {
            let point = NSPoint(x: (position - globalOffset).truncatingRemainder(dividingBy: contentView.bounds.width), y: bounds.height - 25.0)
            
            let timeInterval = TimeInterval(position/(15500.0))/TimeInterval(elementWidth/SpectrogramView.labelWidth)
            let date = Date(timeIntervalSince1970: timeInterval)

            let timeString = dateFormatter.string(from: date)
            
            (timeString as NSString).draw(at: point, withAttributes: [NSAttributedString.Key.foregroundColor: chartLineColor])
        }
    }
    
}

extension SpectrogramView: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let currentRenderPassDescriptor = view.currentRenderPassDescriptor,
            let currentDrawable = view.currentDrawable
            else {
                return
        }
        
        samplesMetalRenderer.render(with: currentRenderPassDescriptor, drawable: currentDrawable)
    }
}
