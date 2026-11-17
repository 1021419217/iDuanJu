import SwiftUI

/// iOS 17 兼容的 ScrollView 内容偏移读取。
///
/// 上游 UI 重设计用了 `onScrollGeometryChange`（iOS 18+）来读 contentOffset，
/// 但本工程部署目标是 iOS 17。这里用 GeometryReader + PreferenceKey 在命名的
/// coordinateSpace 里读内容视图的 minY，换算成与 iOS 18 API 等价的值：
///
///     onScrollGeometryChange 的 g.contentOffset.y + g.contentInsets.top
///     == -contentView.frame(in: .named(space)).minY
///
/// 用法：在 ScrollView 的**内容**根节点上挂 `.readScrollOffset("space") { y in ... }`，
/// 并给 ScrollView（或其外层）`.coordinateSpace(name: "space")`。
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat? { nil }
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        // 保留第一个非 nil 读数，避免兄弟视图用默认值覆盖。
        if value == nil { value = nextValue() }
    }
}

extension View {
    /// 读取本视图在命名坐标系里的顶部偏移，转换为「已滚动点数」（顶部为 0，下滑为正）。
    @ViewBuilder
    func readScrollOffset(_ space: String, onChange: @escaping (CGFloat) -> Void) -> some View {
        self.background {
            GeometryReader { geo in
                Color.clear
                    .preference(key: ScrollOffsetPreferenceKey.self,
                                value: -geo.frame(in: .named(space)).minY)
            }
        }
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            if let value { onChange(value) }
        }
    }
}
