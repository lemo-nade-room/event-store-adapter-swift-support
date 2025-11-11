import SwiftSyntax

/// Detects the access level from a list of declaration modifiers.
///
/// This function examines the modifiers of a declaration (such as `public`, `internal`, `private`)
/// and returns the corresponding `AccessLevel` enum value. If no access level modifier is found,
/// it defaults to `internal`.
///
/// - Parameter modifiers: The list of declaration modifiers to examine
/// - Returns: The detected access level, defaulting to `.internal` if none is specified
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
/// Represents the access level of a Swift declaration.
///
/// This enum corresponds to Swift's access control keywords and is used to determine
/// the appropriate access level for generated code based on the original declaration's modifiers.
///
/// The cases are ordered from most permissive to most restrictive:
/// - `open`: Available to all modules and can be subclassed/overridden
/// - `package`: Available within the same package (Swift 5.9+)
/// - `public`: Available to all modules but cannot be subclassed/overridden
/// - `internal`: Available within the same module (default)
/// - `fileprivate`: Available within the same source file
/// - `private`: Available within the same declaration
enum AccessLevel: String, Sendable, Hashable, Codable, CaseIterable {
  /// Open access level - most permissive, allows subclassing and overriding across modules
  case `open`
  /// Package access level - available within the same package
  case `package`
  /// Public access level - available across modules but not subclassable
  case `public`
  /// Internal access level - available within the same module (default)
  case `internal`
  /// File-private access level - available within the same source file
  case `fileprivate`
  /// Private access level - available within the same declaration
  case `private`
}
