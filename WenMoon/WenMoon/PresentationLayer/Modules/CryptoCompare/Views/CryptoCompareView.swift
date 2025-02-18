//
//  CryptoCompareView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 05.12.24.
//

import SwiftUI

struct CryptoCompareView: View {
    // MARK: - Properties
    @StateObject private var viewModel = CryptoCompareViewModel()

    @State private var selectedPriceOption: PriceOption = .now
    @State private var coinA: Coin?
    @State private var coinB: Coin?

    @State private var cachedImage1: Image?
    @State private var cachedImage2: Image?

    @State private var isSelectingFirstCoin = true
    @State private var showCoinSelectionView = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                makeCoinSelectionView(
                    coin: $coinA,
                    cachedImage: $cachedImage1,
                    placeholder: "Select Coin A",
                    isFirstCoin: true
                )
                
                Button(action: {
                    swap(&coinA, &coinB)
                    swap(&cachedImage1, &cachedImage2)
                    viewModel.triggerImpactFeedback()
                }) {
                    Image("arrows.swap")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(90))
                }
                .disabled(coinA == nil || coinB == nil)
                
                makeCoinSelectionView(
                    coin: $coinB,
                    cachedImage: $cachedImage2,
                    placeholder: "Select Coin B",
                    isFirstCoin: false
                )
                
                VStack(spacing: 16) {
                    let symbolA = coinA?.symbol.uppercased() ?? "A"
                    let symbolB = coinB?.symbol.uppercased() ?? "B"
                    Picker("Price Option", selection: $selectedPriceOption) {
                        ForEach(PriceOption.allCases, id: \.self) { option in
                            Text("\(symbolB) \(option.rawValue)").tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(8)
                    .padding(.horizontal)

                    VStack(spacing: 8) {
                        HStack(spacing: .zero) {
                            Text(symbolA)
                                .bold()
                                .foregroundColor(.white)
                            
                            Text(" WITH THE MARKET CAP OF ")
                            
                            Text(symbolB)
                                .foregroundColor(.white)
                                .bold()
                            
                            Text(" \(selectedPriceOption.rawValue)")
                        }
                        .font(.footnote)
                        .foregroundColor(.gray)

                        let price = viewModel.calculatePrice(
                            for: coinA,
                            coinB: coinB,
                            option: selectedPriceOption
                        ) ?? .zero

                        let multiplier = viewModel.calculateMultiplier(
                            for: coinA,
                            coinB: coinB,
                            option: selectedPriceOption
                        ) ?? .zero

                        HStack {
                            Text(price.formattedAsCurrency())
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            let multiplierColor: Color = viewModel.isPositiveMultiplier(multiplier).map { $0 ? .wmGreen : .wmRed } ?? .gray
                            Text(multiplier.formattedAsMultiplier())
                                .font(.title2)
                                .foregroundColor(multiplierColor)
                        }
                    }
                }
                .padding(.top, 16)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Powered by CoinGecko")
                        .font(.footnote)
                    
                    Image("gecko")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                .foregroundColor(.gray)
            }
            .padding()
            .sheet(isPresented: $showCoinSelectionView) {
                CoinSelectionView(mode: .selection, didSelectCoin: { selectedCoin in
                    loadAndCacheCoinImage(for: selectedCoin)
                    
                    if isSelectingFirstCoin {
                        coinA = selectedCoin
                    } else {
                        coinB = selectedCoin
                    }
                })
            }
            .navigationTitle("Compare")
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func makeCoinSelectionView(
        coin: Binding<Coin?>,
        cachedImage: Binding<Image?>,
        placeholder: String,
        isFirstCoin: Bool
    ) -> some View {
        HStack {
            Button(action: {
                isSelectingFirstCoin = isFirstCoin
                showCoinSelectionView = true
            }) {
                makeCoinView(
                    coin: coin.wrappedValue,
                    cachedImage: cachedImage.wrappedValue,
                    placeholderText: placeholder
                )
            }
            
            if coin.wrappedValue != nil {
                Button(action: {
                    coin.wrappedValue = nil
                    cachedImage.wrappedValue = nil
                }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 12, height: 12)
                        .foregroundColor(.gray)
                }
                .padding(.leading, 8)
            }
        }
    }
    
    @ViewBuilder
    private func makeCoinView(coin: Coin?, cachedImage: Image?, placeholderText: String) -> some View {
        HStack(spacing: 12) {
            if let coin {
                CoinImageView(
                    image: cachedImage,
                    placeholderText: coin.symbol,
                    size: 36
                )
                
                Text(coin.symbol.uppercased())
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(coin.currentPrice.formattedAsCurrency())
                    .font(.headline)
                    .foregroundColor(.white)
            } else {
                Circle()
                    .stroke(Color.gray, lineWidth: 1)
                    .frame(width: 36, height: 36)
                
                Text(placeholderText)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: coin != nil)
    }
    
    // MARK: - Helper Methods
    private func loadAndCacheCoinImage(for coin: Coin) {
        if let url = coin.image {
            Task {
                if let data = await viewModel.loadImage(from: url),
                   let uiImage = UIImage(data: data) {
                    if isSelectingFirstCoin {
                        cachedImage1 = Image(uiImage: uiImage)
                    } else {
                        cachedImage2 = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }
}

// MARK: - Previews
struct CryptoCompareView_Previews: PreviewProvider {
    static var previews: some View {
        CryptoCompareView()
    }
}
