//
//  BaseView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 19.11.24.
//

import SwiftUI

struct BaseView<Content: View>: View {
    // MARK: - Properties
    @Binding var errorMessage: String?
    @State private var showErrorAlert = false
    
    let content: Content
    
    // MARK: - Initializers
    init(errorMessage: Binding<String?>, @ViewBuilder content: () -> Content) {
        self._errorMessage = errorMessage
        self.content = content()
    }
    
    // MARK: - Body
    var body: some View {
        content
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage!),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onChange(of: errorMessage) { _, newValue in
                showErrorAlert = newValue != nil
            }
    }
}
