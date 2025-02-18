//
//  ContentView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 19.11.24.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Properties
    @StateObject private var contentViewModel = ContentViewModel()
    @StateObject private var coinListViewModel = CoinListViewModel()
    @StateObject private var portfolioViewModel = PortfolioViewModel()
    @StateObject private var coinSelectionViewModel = CoinSelectionViewModel()
    
    @State private var scrollText = false
    
    // MARK: - Body
    var body: some View {
        VStack {
            HStack(spacing: 8) {
                ForEach(contentViewModel.globalMarketItems, id: \.self) { item in
                    makeGlobalMarketItemView(item)
                }
            }
            .frame(width: 940, height: 20)
            .offset(x: scrollText ? -680 : 680)
            .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: scrollText)
            
            TabView(selection: $contentViewModel.startScreenIndex) {
                CoinListView()
                    .tabItem {
                        Image("coins")
                    }
                    .tag(0)
                
                PortfolioView()
                    .tabItem {
                        Image("bag")
                    }
                    .tag(1)
                
                CryptoCompareView()
                    .tabItem {
                        Image("arrows.swap")
                    }
                    .tag(2)
                
                EducationView()
                    .tabItem {
                        Image("books")
                    }
                    .tag(3)
                
                AccountView()
                    .tabItem {
                        Image("person")
                    }
                    .tag(4)
            }
        }
        .environmentObject(coinListViewModel)
        .environmentObject(portfolioViewModel)
        .environmentObject(coinSelectionViewModel)
        .task {
            await contentViewModel.fetchGlobalCryptoMarketData()
            await contentViewModel.fetchGlobalMarketData()
        }
        .task {
            await coinListViewModel.fetchCoins()
            portfolioViewModel.fetchPortfolios()
        }
        .onAppear {
            Task { @MainActor in
                try await Task.sleep(for: .seconds(1))
                scrollText = true
            }
            contentViewModel.fetchStartScreen()
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func makeGlobalMarketItemView(_ item: GlobalMarketItem) -> some View {
        HStack(spacing: 4) {
            Text(item.type.title)
                .font(.footnote)
                .foregroundColor(.lightGray)
            
            Text(item.value)
                .font(.footnote).bold()
        }
    }
}
