//
//  ExpandableTextView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 12.02.25.
//

import SwiftUI

struct ExpandableTextView: View {
    // MARK: - Properties
    let text: String
    var collapsedHeight: CGFloat = 100
    
    @State private var fullTextHeight: CGFloat = .zero
    @State private var isExpanded = false
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: isExpanded ? nil : collapsedHeight, alignment: .topLeading)
                .clipped()
                .background(measurementView)
            
            if fullTextHeight > collapsedHeight {
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Show Less" : "Show More")
                            .font(.subheadline)
                        Image(systemName: "chevron.up")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .rotationEffect(.degrees(isExpanded ? 180 : .zero))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private var measurementView: some View {
        Text(text)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .opacity(.zero)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: FullTextHeightPreferenceKey.self,
                                    value: geo.size.height)
                }
            )
            .onPreferenceChange(FullTextHeightPreferenceKey.self) { newHeight in
                fullTextHeight = newHeight
            }
    }
}

// MARK: - FullTextHeightPreferenceKey
struct FullTextHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
