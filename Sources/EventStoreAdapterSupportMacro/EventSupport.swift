public import SwiftSyntax
public import SwiftSyntaxMacros

/// A Swift macro that automatically generates common event properties for enums.
///
/// The `EventSupport` macro is designed to work with enums that represent events in Event Sourcing
/// and CQRS architectures. When applied to an enum, it automatically generates computed properties
/// that extract common event data from enum cases using switch statements.
///
/// ## Generated Properties
///
/// The macro generates the following computed properties:
/// - `id: Self.Id` - The unique identifier of the event
/// - `aid: Self.AID` - The aggregate identifier
/// - `seqNr: Int` - The sequence number of the event within the aggregate
/// - `occurredAt: Date` - The timestamp when the event occurred
/// - `isCreated: Bool` - Whether this is a creation event for the aggregate
///
/// ## Usage
///
/// ```swift
/// @EventSupport
/// enum AccountEvent: EventStoreAdapter.Event {
///     case created(AccountCreated)
///     case updated(AccountUpdated)
///     case deleted(AccountDeleted)
///
///     typealias Id = UUID
///     typealias AID = AccountID
/// }
/// ```
///
/// ## Requirements
///
/// - Can only be applied to `enum` declarations
/// - Each enum case payload must have the properties that correspond to the generated properties
/// - Tuple-style enum cases are not supported; use struct or class types as payloads
///
/// ## Access Level
///
/// The generated properties inherit the access level of the enum declaration:
/// - `public enum` → `public` properties
/// - `internal enum` (default) → `internal` properties
/// - `private enum` → `private` properties
///
/// ## Error Handling
///
/// If applied to a non-enum declaration, the macro will produce a compilation error
/// with a descriptive message.
public struct EventSupport: MemberMacro {
  /// Expands the `@EventSupport` macro to generate common event properties.
  ///
  /// This method is called by the Swift compiler when the `@EventSupport` macro is encountered.
  /// It analyzes the target enum declaration and generates computed properties that extract
  /// common event data from enum cases.
  ///
  /// - Parameters:
  ///   - node: The attribute syntax node representing the `@EventSupport` macro
  ///   - declaration: The declaration group (enum) to which the macro is applied
  ///   - context: The macro expansion context provided by the compiler
  /// - Returns: An array of declaration syntax nodes representing the generated properties
  /// - Throws: `EventSupport.Error.onlyApplicableToEnum` if applied to a non-enum declaration
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      throw Error.onlyApplicableToEnum
    }

    let elements = enumDecl.memberBlock.members
      .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
      .flatMap { $0.elements }

    let accessLevel = detectAccessLevel(modifiers: enumDecl.modifiers)

    return [
      try DeclSyntax(
        makeProperty(
          name: "id",
          typeName: "Self.Id",
          elements: elements,
          accessLevel: accessLevel
        )
      ),
      try DeclSyntax(
        makeProperty(
          name: "aid",
          typeName: "Self.AID",
          elements: elements,
          accessLevel: accessLevel
        )
      ),
      try DeclSyntax(
        makeProperty(
          name: "seqNr",
          typeName: "Int",
          elements: elements,
          accessLevel: accessLevel
        )
      ),
      try DeclSyntax(
        makeProperty(
          name: "occurredAt",
          typeName: "Date",
          elements: elements,
          accessLevel: accessLevel
        )
      ),
      try DeclSyntax(
        makeProperty(
          name: "isCreated",
          typeName: "Bool",
          elements: elements,
          accessLevel: accessLevel
        )
      ),
    ]
  }

  /// Creates a computed property declaration that switches over enum cases.
  ///
  /// This method generates a computed property that uses a switch statement to extract
  /// the specified property from each enum case's associated value.
  ///
  /// - Parameters:
  ///   - name: The name of the property to generate (e.g., "id", "aid", "seqNr")
  ///   - typeName: The type name of the property (e.g., "Self.Id", "Int", "Date")
  ///   - elements: The enum case elements to generate switch cases for
  ///   - accessLevel: The access level for the generated property
  /// - Returns: A variable declaration syntax node for the computed property
  /// - Throws: Syntax errors if the property declaration cannot be created
  private static func makeProperty(
    name: String,
    typeName: String,
    elements: [EnumCaseElementSyntax],
    accessLevel: AccessLevel
  ) throws -> VariableDeclSyntax {
    try VariableDeclSyntax(
      "\(raw: accessLevel.rawValue) var \(raw: name): \(raw: typeName)"
    ) {
      try SwitchExprSyntax("switch self") {
        for element in elements {
          SwitchCaseSyntax("case .\(element.name)(let event): event.\(raw: name)")
        }
      }
    }
  }

  /// Errors that can occur during `@EventSupport` macro expansion.
  public enum Error: Swift.Error, CustomStringConvertible {
    /// Indicates that the macro was applied to a declaration other than an enum.
    ///
    /// The `@EventSupport` macro can only be applied to `enum` declarations.
    /// Applying it to `struct`, `class`, or other declaration types will result in this error.
    case onlyApplicableToEnum

    /// A human-readable description of the error.
    public var description: String {
      switch self {
        case .onlyApplicableToEnum:
          "@EventSupport can only be applied to an enum."
      }
    }
  }
}
