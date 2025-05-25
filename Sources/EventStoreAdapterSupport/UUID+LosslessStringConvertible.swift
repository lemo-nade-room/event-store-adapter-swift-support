public import Foundation

/// `Foundation.UUID`を`@retroactive`キーワードで`LosslessStringConvertible`に準拠させる拡張
///
/// Event Sourcingにおいて、イベントIDやAggregate IDとして`UUID`を頻繁に使用し、
/// 文字列との相互変換が必要な場面が多いため、より直感的なAPIを提供します。
///
/// ```swift
/// let uuid = UUID()
/// let string = String(uuid)
/// let restored = UUID(string)
/// ```
extension UUID: @retroactive LosslessStringConvertible {
    /// 文字列からUUIDを初期化する
    ///
    /// - Parameter description: UUID文字列表現
    public init?(_ description: String) {
        self.init(uuidString: description)
    }
}
