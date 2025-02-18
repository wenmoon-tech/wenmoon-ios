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
    
    @Binding var selectedOption: Int
    
    let title: String
    let options: [SettingOption]
    
    // MARK: - Body
    var body: some View {
        VStack {
            ZStack {
                Text(title)
                    .font(.headline)
                
                HStack {
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
            }
            
            Spacer()
            
            List(options, id: \.self) { option in
                HStack(spacing: 12) {
                    if let imageName = option.imageName {
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    Text(option.title)
                    
                    Spacer()
                    
                    if option.value == selectedOption {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    if option.isEnabled {
                        selectedOption = option.value
                        dismiss()
                    }
                }
                .disabled(!option.isEnabled)
                .opacity(option.isEnabled ? 1 : 0.5)
            }
            .listStyle(.plain)
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}
