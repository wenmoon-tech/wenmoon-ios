//
//  LinksView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 11.02.25.
//

import SwiftUI

// MARK: - LinksView
struct LinksView: View {
    let links: CoinDetails.Links
    
    @Environment(\.openURL) private var openURL
    
    @State private var selectedURLs: [URL] = []
    @State private var showingActionSheet = false
    
    var body: some View {
        FlowLayout() {
            ForEach(Array(generateLinkButtons().enumerated()), id: \.offset) { _, view in
                view
            }
        }
        .confirmationDialog("Select a Link", isPresented: $showingActionSheet, titleVisibility: .visible) {
            ForEach(selectedURLs, id: \.self) { url in
                Button {
                    openURL(url)
                } label: {
                    Text(extractDomain(from: url))
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func generateLinkButtons() -> [AnyView] {
        var buttons: [AnyView] = []
        
        if let urls = links.homepage {
            appendMultiLinkButton(
                to: &buttons,
                title: "Website",
                urls: urls,
                showFullURL: false,
                systemImageName: "globe"
            )
        }
        
        if let url = links.whitepaper {
            buttons.append(
                AnyView(
                    LinkButtonView(
                        url: url,
                        title: "Whitepaper",
                        systemImageName: "doc"
                    )
                )
            )
        }
        
        if let username = links.twitterScreenName, !username.isEmpty,
           let url = URL(string: "https://twitter.com/\(username)") {
            buttons.append(
                AnyView(
                    LinkButtonView(
                        url: url,
                        title: "X",
                        imageName: "x.logo"
                    )
                )
            )
        }
        
        if let url = links.subredditUrl,
           url.absoluteString != "https://www.reddit.com" {
            buttons.append(
                AnyView(
                    LinkButtonView(
                        url: url,
                        title: "Reddit",
                        imageName: "reddit.logo"
                    )
                )
            )
        }
        
        if let username = links.telegramChannelIdentifier, !username.isEmpty,
           let url = URL(string: "https://t.me/\(username)") {
            buttons.append(
                AnyView(
                    LinkButtonView(
                        url: url,
                        title: "Telegram",
                        imageName: "telegram.logo"
                    )
                )
            )
        }
        
        let urls = (links.chatUrl ?? []) + (links.announcementUrl ?? [])
        appendMultiLinkButton(
            to: &buttons,
            title: "Communication",
            urls: urls,
            showFullURL: false,
            systemImageName: "message.fill"
        )
        
        if let urls = links.blockchainSite {
            appendMultiLinkButton(
                to: &buttons,
                title: "Explorer",
                urls: urls,
                showFullURL: false,
                systemImageName: "link"
            )
        }
        
        if let urls = links.reposUrl.github {
            if urls.count == 1, let url = urls.first {
                buttons.append(
                    AnyView(
                        LinkButtonView(
                            url: url,
                            title: "GitHub",
                            imageName: "github.logo"
                        )
                    )
                )
            } else if !urls.isEmpty {
                buttons.append(
                    AnyView(
                        MultiLinkButtonView(
                            title: "GitHub",
                            urls: urls,
                            imageName: "github.logo",
                            showFullURL: true,
                            showingActionSheet: $showingActionSheet,
                            selectedURLs: $selectedURLs
                        )
                    )
                )
            }
        }
        
        return buttons
    }
    
    private func appendMultiLinkButton(
        to buttons: inout [AnyView],
        title: String,
        urls: [URL],
        showFullURL: Bool,
        imageName: String? = nil,
        systemImageName: String? = nil
    ) {
        guard !urls.isEmpty else { return }
        if urls.count == 1, let url = urls.first {
            buttons.append(
                AnyView(
                    LinkButtonView(
                        url: url,
                        title: title,
                        imageName: imageName,
                        systemImageName: systemImageName
                    )
                )
            )
        } else {
            buttons.append(
                AnyView(
                    MultiLinkButtonView(
                        title: title,
                        urls: urls,
                        imageName: imageName,
                        systemImageName: systemImageName,
                        showFullURL: showFullURL,
                        showingActionSheet: $showingActionSheet,
                        selectedURLs: $selectedURLs
                    )
                )
            )
        }
    }
    
    private func extractDomain(from url: URL) -> String {
        let absoluteString = url.absoluteString
        if absoluteString.contains("github") {
            return absoluteString.replacingOccurrences(of: "https://", with: "")
        } else {
            let domain = url.host ?? absoluteString
            return domain.replacingOccurrences(of: "www.", with: "")
        }
    }
}

// MARK: - LinkButtonView
struct LinkButtonView: View {
    let url: URL
    let title: String?
    let imageName: String?
    let systemImageName: String?
    
    @Environment(\.openURL) private var openURLAction
    
    init(
        url: URL,
        title: String? = nil,
        imageName: String? = nil,
        systemImageName: String? = nil
    ) {
        self.url = url
        self.title = title
        self.imageName = imageName
        self.systemImageName = systemImageName
    }
    
    var body: some View {
        Button {
            openURLAction(url)
        } label: {
            LinkButtonContent(
                title: title,
                imageName: imageName,
                systemImageName: systemImageName
            )
        }
    }
}

// MARK: - MultiLinkButtonView
struct MultiLinkButtonView: View {
    let title: String
    let urls: [URL]
    let imageName: String?
    let systemImageName: String?
    let showFullURL: Bool
    
    @Binding var showingActionSheet: Bool
    @Binding var selectedURLs: [URL]
    
    init(
        title: String,
        urls: [URL],
        imageName: String? = nil,
        systemImageName: String? = nil,
        showFullURL: Bool = false,
        showingActionSheet: Binding<Bool>,
        selectedURLs: Binding<[URL]>
    ) {
        self.title = title
        self.urls = urls
        self.imageName = imageName
        self.systemImageName = systemImageName
        self.showFullURL = showFullURL
        self._showingActionSheet = showingActionSheet
        self._selectedURLs = selectedURLs
    }
    
    var body: some View {
        Button {
            selectedURLs = urls
            showingActionSheet = true
        } label: {
            LinkButtonContent(
                title: title,
                imageName: imageName,
                systemImageName: systemImageName
            )
        }
    }
}

// MARK: - LinkButtonContent
struct LinkButtonContent: View {
    let title: String?
    let imageName: String?
    let systemImageName: String?
    
    var body: some View {
        HStack(spacing: 4) {
            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            } else if let systemImageName {
                Image(systemName: systemImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
            if let title {
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, (title == nil) ? 8 : 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .fixedSize()
    }
}

// MARK: - FlowLayout
struct FlowLayout: Layout {
    var spacing: CGFloat = 10
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            if currentX + size.width > maxWidth {
                totalHeight += rowHeight + spacing
                currentX = 0
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
