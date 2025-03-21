import SwiftSyntax

struct Property: Sendable {
    var accessLevel: AccessLevel
    var identifier: IdentifierPatternSyntax
    var typeAnnotation: TypeAnnotationSyntax

    var variableDeclSyntax: VariableDeclSyntax {
        get throws {
            try VariableDeclSyntax(
                "\(raw: accessLevel.rawValue) var \(identifier)\(typeAnnotation)")
        }
    }

    var functionParameterSyntax: FunctionParameterSyntax {
        FunctionParameterSyntax("\(identifier)\(typeAnnotation),")
    }

    var labeledExprSyntax: LabeledExprSyntax {
        var result = LabeledExprSyntax(
            label: "\(identifier)",
            expression: DeclReferenceExprSyntax(baseName: identifier.identifier)
        )
        result.trailingComma = .commaToken()
        return result
    }
}

extension [Property] {
    var functionParameterListSyntax: FunctionParameterListSyntax {
        var functionParameterSyntaxes = map(\.functionParameterSyntax)
        if functionParameterSyntaxes.count != 0 {
            functionParameterSyntaxes[functionParameterSyntaxes.count - 1].trailingComma = nil
        }
        return .init(functionParameterSyntaxes)
    }

    var labeledExprListSyntax: LabeledExprListSyntax {
        var labeledExprSytaxes = map(\.labeledExprSyntax)
        if labeledExprSytaxes.count != 0 {
            labeledExprSytaxes[labeledExprSytaxes.count - 1].trailingComma = nil
        }
        return .init(labeledExprSytaxes)
    }
}
