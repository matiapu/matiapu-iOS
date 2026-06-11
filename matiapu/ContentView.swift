//
//  ContentView.swift
//  matiapu
//
//  Created by 石田湊 on 2026/05/21.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModels: AppViewModels

    init(dependencies: AppDependencies) {
        _viewModels = State(wrappedValue: AppViewModels(dependencies: dependencies))
    }

    var body: some View {
        MainTabView(viewModels: viewModels)
    }
}

#Preview {
    ContentView(dependencies: .live)
}
