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
    @State private var playerWidth = Settings.chineseOverlayPlayerWidth
    @State private var opponentWidth = Settings.chineseOverlayOpponentWidth
    @State private var fontScale = Settings.chineseOverlayFontScale

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

                chineseSlider("我的牌库宽度", value: $playerWidth,
                              range: ChineseOverlayLayoutViewModel.minimumWidth...ChineseOverlayLayoutViewModel.maximumWidth) {
                    Settings.chineseOverlayPlayerWidth = $0
                }
                chineseSlider("右侧信息框宽度", value: $opponentWidth,
                              range: ChineseOverlayLayoutViewModel.minimumWidth...ChineseOverlayLayoutViewModel.maximumWidth) {
                    Settings.chineseOverlayOpponentWidth = $0
                }
                chineseSlider("文字和卡牌大小", value: $fontScale,
                              range: ChineseOverlayLayoutViewModel.minimumFontScale...ChineseOverlayLayoutViewModel.maximumFontScale,
                              suffix: "%") {
                    Settings.chineseOverlayFontScale = $0
                }
                Text("解锁覆盖层后，也可以直接拖动左右面板的内侧边缘调整宽度；锁定后继续点击穿透。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button("恢复默认布局") {
                    playerWidth = 300
                    opponentWidth = 330
                    fontScale = 1
                    Settings.chineseOverlayPlayerWidth = 300
                    Settings.chineseOverlayOpponentWidth = 330
                    Settings.chineseOverlayFontScale = 1
                }
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

    @ViewBuilder
    private func chineseSlider(_ title: String,
                               value: Binding<Double>,
                               range: ClosedRange<Double>,
                               suffix: String = " px",
                               onChange: @escaping (Double) -> Void) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .frame(width: 112, alignment: .leading)
            Slider(value: Binding(get: { value.wrappedValue },
                                  set: {
                                      value.wrappedValue = $0
                                      onChange($0)
                                  }), in: range, step: 1)
            Text(displayValue(value.wrappedValue, suffix: suffix))
                .font(.system(.caption, design: .monospaced))
                .frame(width: 58, alignment: .trailing)
        }
    }

    private func displayValue(_ value: Double, suffix: String) -> String {
        if suffix == "%" {
            return "\(Int((value * 100).rounded()))%"
        }
        return "\(Int(value.rounded()))\(suffix)"
    }
}

/// Shared live settings for the Chinese overlay. The settings pane and the
/// overlay both observe the same UserDefaults notifications, so a slider or a
/// resize handle updates the game overlay without restarting HSTracker.
final class ChineseOverlayLayoutViewModel: ObservableObject {
    static let minimumWidth = 240.0
    static let maximumWidth = 460.0
    static let minimumFontScale = 0.85
    static let maximumFontScale = 1.6

    @Published var playerWidth: CGFloat
    @Published var opponentWidth: CGFloat
    @Published var fontScale: CGFloat

    private var observers: [NSObjectProtocol] = []

    init() {
        playerWidth = Self.clampWidth(Settings.chineseOverlayPlayerWidth)
        opponentWidth = Self.clampWidth(Settings.chineseOverlayOpponentWidth)
        fontScale = Self.clampFontScale(Settings.chineseOverlayFontScale)

        for key in [Settings.chinese_overlay_player_width,
                    Settings.chinese_overlay_opponent_width,
                    Settings.chinese_overlay_font_scale] {
            observers.append(
                NotificationCenter.default.addObserver(
                    forName: Notification.Name(rawValue: key),
                    object: nil,
                    queue: .main,
                    using: { [weak self] _ in
                        self?.reload()
                    }
                )
            )
        }
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func updatePlayerWidth(_ value: CGFloat) {
        playerWidth = Self.clampWidth(Double(value))
    }

    func updateOpponentWidth(_ value: CGFloat) {
        opponentWidth = Self.clampWidth(Double(value))
    }

    func persistWidths() {
        Settings.chineseOverlayPlayerWidth = Double(playerWidth)
        Settings.chineseOverlayOpponentWidth = Double(opponentWidth)
    }

    private func reload() {
        playerWidth = Self.clampWidth(Settings.chineseOverlayPlayerWidth)
        opponentWidth = Self.clampWidth(Settings.chineseOverlayOpponentWidth)
        fontScale = Self.clampFontScale(Settings.chineseOverlayFontScale)
    }

    private static func clampWidth(_ value: Double) -> CGFloat {
        CGFloat(min(max(value, minimumWidth), maximumWidth))
    }

    private static func clampFontScale(_ value: Double) -> CGFloat {
        CGFloat(min(max(value, minimumFontScale), maximumFontScale))
    }
}
