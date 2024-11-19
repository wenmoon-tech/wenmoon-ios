//
//  SelectionView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.11.24.
//

import SwiftUI

struct SelectionView: View {
    // MARK: - Properties
    @Environment(\.dismiss) var dismiss
    @Binding var selectedOption: String
    
    let title: String
    let options: [(name: String, isEnabled: Bool)]
    
    // MARK: - Body
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Text(title)
                    .font(.headline)
                    .bold()
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 12, height: 12)
                        .foregroundColor(.white)
                }
            }
            .padding(24)
            
            Spacer()
            
            List(options, id: \.name) { option in
                HStack {
                    Text(option.name)
                    
                    Spacer()
                    
                    if option.name == selectedOption {
                        Image(systemName: "checkmark")
                            .foregroundColor(.wmPink)
                    }
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    if option.isEnabled {
                        selectedOption = option.name
                        dismiss()
                    }
                }
                .disabled(!option.isEnabled)
                .opacity(option.isEnabled ? 1 : 0.5)
            }
            .listStyle(.plain)
        }
    }
}
