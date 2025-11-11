import SwiftSyntax

/// Represents a property definition used in macro code generation.
///
/// This struct encapsulates the information needed to generate various Swift syntax elements
/// for a property, including variable declarations, function parameters, and labeled expressions.
/// It's primarily used by the `@EventSupport` macro to generate consistent property-related code.
struct Property: Sendable {
  /// The access level for this property (e.g., public, internal, private).
  var accessLevel: AccessLevel
  /// The identifier pattern representing the property name.
  var identifier: IdentifierPatternSyntax
  /// The type annotation for this property.
  var typeAnnotation: TypeAnnotationSyntax

  /// Generates a variable declaration syntax for this property.
  ///
  /// Creates a variable declaration with the specified access level, identifier, and type annotation.
  /// This is typically used to generate property declarations in Swift code.
  ///
  /// - Returns: A `VariableDeclSyntax` representing the property declaration
  /// - Throws: Syntax errors if the declaration cannot be created
  var variableDeclSyntax: VariableDeclSyntax {
    get throws {
      try VariableDeclSyntax(
        "\(raw: accessLevel.rawValue) var \(identifier)\(typeAnnotation)"
      )
    }
  }

  /// Generates a function parameter syntax for this property.
  ///
  /// Creates a function parameter with the property's identifier and type annotation,
  /// including a trailing comma. This is useful for generating function signatures
  /// that include this property as a parameter.
  ///
  /// - Returns: A `FunctionParameterSyntax` representing the parameter
  var functionParameterSyntax: FunctionParameterSyntax {
    FunctionParameterSyntax("\(identifier)\(typeAnnotation),")
  }

  /// Generates a labeled expression syntax for this property.
  ///
  /// Creates a labeled expression that references this property by name.
  /// This is typically used in function calls or initializers where the property
  /// is passed as a labeled argument.
  ///
  /// - Returns: A `LabeledExprSyntax` representing the labeled expression
  var labeledExprSyntax: LabeledExprSyntax {
    var result = LabeledExprSyntax(
      label: "\(identifier)",
      expression: DeclReferenceExprSyntax(baseName: identifier.identifier)
    )
    result.trailingComma = .commaToken()
    return result
  }
}

/// Extension providing convenience methods for arrays of `Property` instances.
extension [Property] {
  /// Generates a function parameter list syntax from an array of properties.
  ///
  /// Creates a function parameter list where each property becomes a parameter.
  /// The trailing comma is automatically removed from the last parameter.
  ///
  /// - Returns: A `FunctionParameterListSyntax` containing all properties as parameters
  var functionParameterListSyntax: FunctionParameterListSyntax {
    var functionParameterSyntaxes = map(\.functionParameterSyntax)
    if functionParameterSyntaxes.count != 0 {
      functionParameterSyntaxes[functionParameterSyntaxes.count - 1].trailingComma = nil
    }
    return .init(functionParameterSyntaxes)
  }

  /// Generates a labeled expression list syntax from an array of properties.
  ///
  /// Creates a labeled expression list where each property becomes a labeled expression.
  /// The trailing comma is automatically removed from the last expression.
  /// This is useful for generating argument lists in function calls or initializers.
  ///
  /// - Returns: A `LabeledExprListSyntax` containing all properties as labeled expressions
  var labeledExprListSyntax: LabeledExprListSyntax {
    var labeledExprSytaxes = map(\.labeledExprSyntax)
    if labeledExprSytaxes.count != 0 {
      labeledExprSytaxes[labeledExprSytaxes.count - 1].trailingComma = nil
    }
    return .init(labeledExprSytaxes)
  }
}
