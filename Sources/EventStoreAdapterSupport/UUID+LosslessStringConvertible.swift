public import Foundation

/// Extension that makes `Foundation.UUID` conform to `LosslessStringConvertible` using Swift 6.0's `@retroactive` keyword.
///
/// In Event Sourcing architectures, UUIDs are frequently used as event IDs and aggregate IDs,
/// requiring frequent string conversion. This extension provides a more intuitive API for
/// bidirectional string conversion.
///
/// ## Usage Examples
///
/// ```swift
/// // Create UUID from string
/// let uuid = UUID("550E8400-E29B-41D4-A716-446655440000")
///
/// // Convert UUID to string
/// let uuidString = String(uuid)
///
/// // Round-trip conversion
/// let originalUUID = UUID()
/// let stringRepresentation = String(originalUUID)
/// let restoredUUID = UUID(stringRepresentation)
/// ```
///
/// ## Benefits
///
/// - **Intuitive API**: Use `String(uuid)` and `UUID(string)` for conversions
/// - **Type Safety**: Leverages Swift's type system for safe conversions
/// - **Event Sourcing Ready**: Optimized for common Event Sourcing patterns
/// - **Swift 6.0 Compatible**: Uses `@retroactive` for clean protocol conformance
///
/// ## Note
///
/// This extension uses the `@retroactive` keyword introduced in Swift 6.0 to conform
/// an external type (`Foundation.UUID`) to an external protocol (`LosslessStringConvertible`).
/// This is the recommended approach for such conformances in Swift 6.0+.
extension UUID: @retroactive LosslessStringConvertible {
    /// Initializes a UUID from its string representation.
    ///
    /// This initializer attempts to create a UUID from a string representation.
    /// It accepts standard UUID string formats (with or without hyphens).
    ///
    /// - Parameter description: The string representation of the UUID
    ///
    /// ## Supported Formats
    ///
    /// - Standard format: `"550E8400-E29B-41D4-A716-446655440000"`
    /// - Lowercase: `"550e8400-e29b-41d4-a716-446655440000"`
    /// - Mixed case: `"550E8400-e29b-41D4-A716-446655440000"`
    ///
    /// ## Example
    ///
    /// ```swift
    /// let uuid1 = UUID("550E8400-E29B-41D4-A716-446655440000") // Valid
    /// let uuid2 = UUID("invalid-uuid-string") // Returns nil
    /// ```
    public init?(_ description: String) {
        self.init(uuidString: description)
    }
}
