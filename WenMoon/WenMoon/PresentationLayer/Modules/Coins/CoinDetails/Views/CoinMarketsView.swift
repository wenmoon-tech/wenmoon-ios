//
//  CoinMarketsView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 12.02.25.
//

import SwiftUI

struct CoinMarketsView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    @StateObject private var viewModel: CoinMarketsViewModel
    
    @FocusState private var isTextFieldFocused: Bool
    
    // MARK: - Initializers
    init(tickers: [CoinDetails.Ticker]) {
        _viewModel = StateObject(wrappedValue: CoinMarketsViewModel(tickers: tickers))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            let tickers = viewModel.searchedTickers
            VStack {
                if tickers.isEmpty {
                    PlaceholderView(text: "No markets found")
                } else {
                    List(tickers, id: \.self) { ticker in
                        makeMarketRow(ticker)
                    }
                    .listStyle(.plain)
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
            .navigationTitle("Markets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .if(viewModel.tickers.count >= 20) { view in
                view.searchable(
                    text: $viewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "e.g. Binance"
                )
                .searchFocused($isTextFieldFocused)
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                isTextFieldFocused = false
            }
        )
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func makeMarketRow(_ ticker: CoinDetails.Ticker) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let marketName = ticker.market.name {
                        Text(marketName)
                            .font(.subheadline).bold()
                    }
                    
                    if let trustScore = ticker.trustScore {
                        Circle()
                            .fill(trustScore.color)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text("\(ticker.base)/\(ticker.target)")
                    .frame(maxWidth: 150, alignment: .leading)
                    .lineLimit(1)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let lastPrice = ticker.convertedLast {
                    Text(lastPrice.formattedAsCurrency())
                        .font(.footnote).bold()
                }
                
                if let volume = ticker.convertedVolume {
                    Text(volume.formattedWithAbbreviation(suffix: "$"))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            guard let url = ticker.tradeUrl else { return }
            openURL(url)
        }
    }
}
