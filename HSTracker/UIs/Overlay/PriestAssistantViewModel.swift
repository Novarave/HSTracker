//
//  PriestAssistantViewModel.swift
//  HSTracker
//
//  The first small, game-state-backed assistant for the Chinese lightweight
//  overlay. It intentionally reads the existing Player/Entity state instead of
//  introducing another parser or card model.
//

import Foundation
import SwiftUI

struct PriestTaskProgress: Identifiable {
    let id: String
    let title: String
    let progress: Int
    let total: Int

    var fraction: Double {
        guard total > 0 else { return 0 }
        return min(1, max(0, Double(progress) / Double(total)))
    }
}

struct PriestInfuseProgress: Identifiable {
    let id: String
    let card: Card
    let threshold: Int
    let deaths: Int

    var isReady: Bool { deaths >= threshold }
}

struct PriestResurrectionCard: Identifiable {
    let id: String
    let card: Card
    let count: Int
}

enum PriestKeyCardStatus: String {
    case inDeck = "牌库"
    case inHand = "手牌"
    case played = "已用"
    case dead = "已死"
    case unknown = "未知"
}

struct PriestKeyCard: Identifiable {
    let id: String
    let card: Card
    let count: Int
    let status: PriestKeyCardStatus
}

final class PriestAssistantViewModel: ObservableObject {
    @Published private(set) var isPriestDeck = false
    @Published private(set) var tasks = [PriestTaskProgress]()
    @Published private(set) var infuseDeaths = 0
    @Published private(set) var infuseCards = [PriestInfuseProgress]()
    @Published private(set) var resurrectionPool = [PriestResurrectionCard]()
    @Published private(set) var keyCards = [PriestKeyCard]()
    @Published private(set) var turn = 0

    private static let infuseRegex = try? NSRegularExpression(
        pattern: #"(?:[Ii]nfuse|灌注)\s*[\(（]\s*(\d+)\s*[\)）]"#,
        options: [])

    func refresh(game: Game) {
        guard let player = game.player else {
            clear()
            return
        }

        let playerClass = game.currentDeck?.playerClass ?? player.currentClass ?? player.originalClass
        guard playerClass == .priest else {
            clear()
            return
        }

        isPriestDeck = true
        turn = game.turnNumber()

        tasks = player.quests.compactMap { entity in
            let total = entity[.quest_progress_total]
            let progress = min(max(entity[.quest_progress], 0), max(total, 0))
            guard total > 0 || progress > 0 else { return nil }
            let card = entity.card
            return PriestTaskProgress(id: card.id.isEmpty ? "quest-\(entity.id)" : card.id,
                                      title: card.simplifiedChineseName,
                                      progress: progress,
                                      total: max(total, max(progress, 1)))
        }

        let deadMinions = player.deadMinionsCards.filter { $0.isMinion }
        infuseDeaths = deadMinions.count
        let visibleCards = player.hand.map { $0.card } + player.deck.map { $0.card }
        infuseCards = uniqueCards(visibleCards)
            .compactMap { card in
                guard let threshold = Self.infuseThreshold(in: card) else { return nil }
                return PriestInfuseProgress(id: card.id,
                                            card: card,
                                            threshold: threshold,
                                            deaths: infuseDeaths)
            }
            .sorted { lhs, rhs in
                if lhs.isReady != rhs.isReady { return lhs.isReady && !rhs.isReady }
                return lhs.threshold < rhs.threshold
            }

        resurrectionPool = groupedCards(deadMinions.map { $0.card })
            .prefix(12)
            .map { PriestResurrectionCard(id: $0.card.id, card: $0.card, count: $0.count) }

        let candidates = player.playerCardList.filter(isPriestKeyCard)
        keyCards = groupedCards(candidates)
            .prefix(12)
            .map { entry in
                PriestKeyCard(id: entry.card.id,
                              card: entry.card,
                              count: entry.count,
                              status: status(of: entry.card, player: player))
            }
    }

    private func clear() {
        isPriestDeck = false
        tasks = []
        infuseDeaths = 0
        infuseCards = []
        resurrectionPool = []
        keyCards = []
        turn = 0
    }

    private func uniqueCards(_ cards: [Card]) -> [Card] {
        var seen = Set<String>()
        return cards.compactMap { card in
            guard !card.id.isEmpty, seen.insert(card.id).inserted else { return nil }
            return card
        }
    }

    private func groupedCards(_ cards: [Card]) -> [(card: Card, count: Int)] {
        var grouped = [String: (card: Card, count: Int)]()
        for card in cards where !card.id.isEmpty {
            if let existing = grouped[card.id] {
                grouped[card.id] = (existing.card, existing.count + max(card.count, 1))
            } else {
                let copy = card.copy()
                copy.count = max(card.count, 1)
                grouped[card.id] = (copy, max(card.count, 1))
            }
        }
        return grouped.values.sorted { lhs, rhs in
            if lhs.card.cost != rhs.card.cost { return lhs.card.cost < rhs.card.cost }
            return lhs.card.simplifiedChineseName < rhs.card.simplifiedChineseName
        }
    }

    private static func infuseThreshold(in card: Card) -> Int? {
        let source = "\(card.enText) \(card.simplifiedChineseText)"
        guard let regex = infuseRegex else { return nil }
        let range = NSRange(location: 0, length: source.utf16.count)
        guard let match = regex.firstMatch(in: source, options: [], range: range),
              let thresholdRange = Range(match.range(at: 1), in: source) else {
            return nil
        }
        return Int(source[thresholdRange])
    }

    private func isPriestKeyCard(_ card: Card) -> Bool {
        let text = "\(card.enText) \(card.simplifiedChineseText)".lowercased()
        return card.isClass(cardClass: .priest)
            || text.contains("resurrect")
            || text.contains("复活")
            || text.contains("灌注")
            || text.contains("infuse")
    }

    private func status(of card: Card, player: Player) -> PriestKeyCardStatus {
        if player.deadMinionsCards.contains(where: { $0.cardId == card.id }) {
            return .dead
        }
        if player.hand.contains(where: { $0.cardId == card.id }) {
            return .inHand
        }
        if player.cardsPlayedThisMatch.contains(where: { $0.cardId == card.id }) {
            return .played
        }
        if player.deck.contains(where: { $0.cardId == card.id }) {
            return .inDeck
        }
        return .unknown
    }
}
