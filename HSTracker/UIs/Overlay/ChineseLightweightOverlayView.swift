//
//  ChineseLightweightOverlayView.swift
//  HSTracker
//
//  V0.1 overlay matching the agreed macOS prototype: the known deck on the
//  left, opponent information in the upper-right, and a Priest assistant in
//  the lower-right. It is intentionally click-through; the existing overlay
//  window continues to sweep the reported card-row frames for hover previews.
//

import SwiftUI

struct ChineseLightweightOverlayView: View {
    @ObservedObject var viewModel: RootOverlayViewModel
    let canvasSize: CGSize

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ChineseDeckPanelView(title: "我的牌库",
                                 subtitle: "已知卡牌",
                                 tracker: viewModel.playerTracker,
                                 playerType: .player,
                                 accent: Color(red: 0.25, green: 0.68, blue: 0.95),
                                 height: min(780, max(360, canvasSize.height - 150)))
                .padding(.top, 72)
                .padding(.leading, 16)

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 12) {
                ChineseOpponentPanelView(tracker: viewModel.opponentTracker)
                    .frame(height: 290)

                if viewModel.priestAssistantEnabled {
                    PriestAssistantPanelView(viewModel: viewModel.priestAssistant)
                        .frame(height: min(455, max(300, canvasSize.height - 390)))
                }
            }
            .frame(width: 330,
                   height: max(520, canvasSize.height - 120),
                   alignment: .top)
            .padding(.top, 72)
            .padding(.trailing, 16)
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

private struct ChineseDeckPanelView: View {
    let title: String
    let subtitle: String
    @ObservedObject var tracker: TrackerPanelViewModel
    let playerType: PlayerType
    let accent: Color
    let height: CGFloat

    var body: some View {
        ChineseOverlayPanel(title: title, accent: accent) {
            HStack(spacing: 10) {
                Text(subtitle)
                Spacer()
                Text("牌库 \(tracker.deckCount)")
                Text("手牌 \(tracker.handCount)")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.white.opacity(0.68))

            Divider().background(Color.white.opacity(0.16))

            if tracker.cards.cards.isEmpty {
                Text("等待对局数据")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.52))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.top, 12)
            } else {
                CardTileListView(cards: chineseCards(tracker.cards.cards),
                                 playerType: playerType,
                                 cardHeight: 26,
                                 reset: tracker.cards.reset,
                                 flashing: tracker.cards.flashing,
                                 version: tracker.cards.version,
                                 hoverKind: playerType == .player ? .playerDeck : .opponentDeck)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipped()
            }
        }
        .frame(width: 300, height: height)
    }
}

private struct ChineseOpponentPanelView: View {
    @ObservedObject var tracker: TrackerPanelViewModel

    var body: some View {
        ChineseOverlayPanel(title: "对手信息",
                            accent: Color(red: 0.95, green: 0.48, blue: 0.38)) {
            HStack(spacing: 10) {
                Text(tracker.playerName?.isEmpty == false ? tracker.playerName! : "未知对手")
                Spacer()
                Text("牌库 \(tracker.deckCount)")
                Text("手牌 \(tracker.handCount)")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.white.opacity(0.68))

            Divider().background(Color.white.opacity(0.16))

            if tracker.cards.cards.isEmpty {
                Text("等待已知卡牌")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.52))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.top, 12)
            } else {
                CardTileListView(cards: chineseCards(tracker.cards.cards.prefix(10).map { $0 }),
                                 playerType: .opponent,
                                 cardHeight: 25,
                                 reset: tracker.cards.reset,
                                 flashing: tracker.cards.flashing,
                                 version: tracker.cards.version,
                                 hoverKind: .opponentDeck)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipped()
            }
        }
    }
}

private struct PriestAssistantPanelView: View {
    @ObservedObject var viewModel: PriestAssistantViewModel

    var body: some View {
        ChineseOverlayPanel(title: "牧师助手",
                            accent: Color(red: 0.73, green: 0.48, blue: 0.98)) {
            if !viewModel.isPriestDeck {
                Text("识别到牧师套牌后显示任务、灌注和复生池")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.58))
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            } else {
                Text("第 \(viewModel.turn) 回合")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.62))

                PriestAssistantSection(title: "任务进度") {
                    if viewModel.tasks.isEmpty {
                        Text("暂无任务数据")
                            .foregroundColor(.white.opacity(0.46))
                    } else {
                        ForEach(viewModel.tasks) { task in
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(task.title)
                                    Spacer()
                                    Text("\(task.progress)/\(task.total)")
                                }
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.86))
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.white.opacity(0.12))
                                        Capsule().fill(Color(red: 0.73, green: 0.48, blue: 0.98))
                                            .frame(width: geometry.size.width * CGFloat(task.fraction))
                                    }
                                }
                                .frame(height: 4)
                            }
                        }
                    }
                }

                PriestAssistantSection(title: "灌注") {
                    HStack {
                        Text("友方随从死亡")
                        Spacer()
                        Text("\(viewModel.infuseDeaths)")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.76))

                    if viewModel.infuseCards.isEmpty {
                        Text("未发现灌注牌")
                            .foregroundColor(.white.opacity(0.46))
                    } else {
                        ForEach(viewModel.infuseCards) { item in
                            HStack(spacing: 6) {
                                Text(item.card.simplifiedChineseName)
                                Spacer()
                                Text(item.isReady ? "已完成" : "\(item.deaths)/\(item.threshold)")
                                    .foregroundColor(item.isReady ? .green : .white.opacity(0.62))
                            }
                        }
                    }
                }

                PriestAssistantSection(title: "复生池") {
                    if viewModel.resurrectionPool.isEmpty {
                        Text("暂无已知亡语随从")
                            .foregroundColor(.white.opacity(0.46))
                    } else {
                        ForEach(viewModel.resurrectionPool) { item in
                            HStack(spacing: 6) {
                                Text(item.card.simplifiedChineseName)
                                Spacer()
                                Text("×\(item.count)")
                                    .foregroundColor(.white.opacity(0.62))
                            }
                        }
                    }
                }

                PriestAssistantSection(title: "关键牌追踪") {
                    if viewModel.keyCards.isEmpty {
                        Text("暂无可追踪关键牌")
                            .foregroundColor(.white.opacity(0.46))
                    } else {
                        ForEach(viewModel.keyCards) { item in
                            HStack(spacing: 6) {
                                Text(item.card.simplifiedChineseName)
                                Spacer()
                                Text(item.status.rawValue)
                                    .foregroundColor(item.status == .dead ? .orange : .white.opacity(0.62))
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct PriestAssistantSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            content
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.76))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ChineseOverlayPanel<Content: View>: View {
    let title: String
    let accent: Color
    let content: Content

    init(title: String, accent: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accent)
                    .frame(width: 7, height: 7)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            content
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.72))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 4)
    }
}

private func chineseCards(_ cards: [Card]) -> [Card] {
    cards.map { card in
        let copy = card.copy()
        copy.name = card.simplifiedChineseName
        copy.text = card.simplifiedChineseText
        if !card.zhCNFlavor.isEmpty {
            copy.flavor = card.zhCNFlavor
        }
        return copy
    }
}
