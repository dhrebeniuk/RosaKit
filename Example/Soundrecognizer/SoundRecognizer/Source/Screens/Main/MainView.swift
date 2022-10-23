//
//  MainView.swift
//  SoundRecognizer
//
//  Created by Hrebeniuk Dmytro on 27.12.2019.
//  Copyright © 2019 Hrebeniuk Dmytro. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var viewModel: MainViewModel

    var body: some View {
        VStack {
            
            switch viewModel.state {
            case .initial:
                Text("")
            case .downloading:
                Text("Downloading Dataset...")
            case .unzip:
                Text("Unzipping...")
            case .processing:
                Text("Percentage Proceccesed: \(viewModel.percentageProceccesed * 100)%")
                Text("Percentage Valid: \(viewModel.percentageValid * 100)%")
                Text("Percentage Invalid: \(viewModel.percentageInvalid * 100)%")
                
                ScrollView {
                    ForEach(self.viewModel.problemPreditions, id: \.self) { problemPrediction in
                        HStack {
                            Text("FileName: \(problemPrediction.fileName)")
                            Text("Predicted: \(problemPrediction.predictedCategory)")
                            Text("(\(problemPrediction.percentage))")
                            Text("Target: \(problemPrediction.targetCategory)")
                            
                            Spacer()
                            Button("Save Wave") {
                                viewModel.copyWave(toClipboard: problemPrediction)
                            }.padding()
                            
                            Button("Save STFT") {
                                viewModel.copySTFT(toClipboard: problemPrediction)
                            }.padding()
                        }.sheet(isPresented: $viewModel.showFileExportPicker) {
                            SaveDocumentPicker(url: $viewModel.fileExportURL)
                        }
                    }
                }
            }
            
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
