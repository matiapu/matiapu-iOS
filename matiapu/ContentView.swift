//
//  ContentView.swift
//  matiapu
//
//  Created by 石田湊 on 2026/05/21.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModels: AppViewModels
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModels = State(wrappedValue: AppViewModels(dependencies: dependencies))
    }

    var body: some View {
        MainTabView(viewModels: viewModels, dependencies: dependencies)
    }
}

#Preview {
    ContentView(dependencies: .live)
}
