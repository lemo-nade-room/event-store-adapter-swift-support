import SwiftSyntax

func detectAccessLevel(modifiers: DeclModifierListSyntax) -> AccessLevel {
    for modifier in modifiers {
        switch modifier.name.tokenKind {
        case .keyword(.open): return .open
        case .keyword(.package): return .package
        case .keyword(.public): return .public
        case .keyword(.internal): return .internal
        case .keyword(.fileprivate): return .fileprivate
        case .keyword(.private): return .private
        default: continue
        }
    }
    return .internal
}
enum AccessLevel: String, Sendable, Hashable, Codable, CaseIterable {
    case `open`
    case `package`
    case `public`
    case `internal`
    case `fileprivate`
    case `private`
}
