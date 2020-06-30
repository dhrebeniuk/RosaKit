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
            if (viewModel.percentage > 0) {
                Text("Sound category:\n")
                Text("\(viewModel.categoryTitle) (\(viewModel.categoryIndex))")
                Text("\(viewModel.percentage) %")
            }
            else {
                Text("Loading...")
            }
        }
        
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
