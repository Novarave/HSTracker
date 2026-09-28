//
//  ChineseOverlayPreferences.swift
//  HSTracker
//

import AppKit
import SwiftUI

final class ChineseOverlayPreferences: PreferencePaneController, PreferencePane {
    var preferencePaneIdentifier = PreferencePaneIdentifier.chinese_overlay
    var preferencePaneTitle = "中文轻量覆盖层"
    var preferencePaneIcon = NSImage(named: "settings-overlay-layout")!

    var preferencePaneSearchText: [String] {
        ["常规", "外观", "记牌器", "对手信息", "牧师助手", "热键", "关于",
         "我的牌库", "任务进度", "灌注", "复生池", "关键牌追踪"]
    }

    override func makeContentView() -> NSView? {
        let hosting = NSHostingView(rootView: ChineseOverlayPreferencesView())
        hosting.translatesAutoresizingMaskIntoConstraints = false
        return hosting
    }
}

extension PreferencePaneIdentifier {
    static let chinese_overlay = Self("chinese_overlay")
}

struct ChineseOverlayPreferencesView: View {
    @State private var lightweightOverlay = Settings.lightweightChineseOverlay
    @State private var priestAssistant = Settings.priestAssistantEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("中文轻量覆盖层")
                .font(.title2)

            Text("V0.1 保留现有日志解析、实体状态、DeckString 和卡牌数据库，仅替换用户可见的记牌器布局。")
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.secondary)

            Divider()
            preferenceSection("常规") {
                Toggle("启用 V0.1 中文轻量覆盖层", isOn: binding(
                    get: { lightweightOverlay },
                    set: {
                        lightweightOverlay = $0
                        Settings.lightweightChineseOverlay = $0
                    }))
            }

            preferenceSection("外观") {
                Text("暗色半透明、圆角面板和 macOS 风格层次已随覆盖层启用。")
                    .foregroundColor(.secondary)
            }

            preferenceSection("记牌器") {
                Text("左侧显示“我的牌库”，并沿用现有牌库计数、悬停卡牌详情和状态更新。")
                    .foregroundColor(.secondary)
            }

            preferenceSection("对手信息") {
                Text("右上角显示已知对手牌库、手牌数量和可识别卡牌。")
                    .foregroundColor(.secondary)
            }

            preferenceSection("牧师助手") {
                Toggle("显示牧师助手", isOn: binding(
                    get: { priestAssistant },
                    set: {
                        priestAssistant = $0
                        Settings.priestAssistantEnabled = $0
                    }))
                Text("包含任务进度、灌注、复生池和关键牌追踪。仅在识别到牧师套牌时填充数据。")
                    .foregroundColor(.secondary)
            }

            preferenceSection("热键") {
                Text("沿用现有 HSTracker 热键设置。")
                    .foregroundColor(.secondary)
            }

            preferenceSection("关于") {
                Text("HSTracker V0.1 中文界面 · 卡牌名称和描述优先使用官方 zhCN 数据。")
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(width: PreferencePaneController.fixedWidth, alignment: .leading)
    }

    private func preferenceSection<Content: View>(_ title: String,
                                                   @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    private func binding(get: @escaping () -> Bool, set: @escaping (Bool) -> Void) -> Binding<Bool> {
        Binding(get: get, set: set)
    }
}
