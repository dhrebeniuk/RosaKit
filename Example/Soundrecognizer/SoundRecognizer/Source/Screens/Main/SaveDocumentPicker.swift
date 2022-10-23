//
//  SaveDocumentPicker.swift
//  SoundRecognizer
//
//  Created by Hrebeniuk Dmytro on 20.07.2022.
//  Copyright © 2022 Hrebeniuk Dmytro. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

struct SaveDocumentPicker: UIViewControllerRepresentable {
    
    @Binding var url: URL

    func makeCoordinator() -> DocumentPickerCoordinator {
        return DocumentPickerCoordinator(url: $url)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<SaveDocumentPicker>) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forExporting: [url])
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiviewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<SaveDocumentPicker>) {
    }
    
}

class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    
    @Binding var url: URL

    init(url: Binding<URL>) {
        _url = url
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        
    }
}
