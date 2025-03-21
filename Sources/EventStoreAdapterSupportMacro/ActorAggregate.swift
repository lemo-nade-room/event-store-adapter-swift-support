public import SwiftSyntax
public import SwiftSyntaxMacros

public struct ActorAggregate: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let actorDecl = declaration.as(ActorDeclSyntax.self) else {
            throw Error.shouldBeActor
        }

        let accessLevel = detectAccessLevel(modifiers: actorDecl.modifiers)

        let properties = actorDecl.memberBlock.members.compactMap { member -> Property? in
            guard
                let variableDecl = member.decl.as(VariableDeclSyntax.self),
                let patternBindingSyntax = variableDecl.bindings.first,
                let identifierSyntax = patternBindingSyntax.pattern.as(
                    IdentifierPatternSyntax.self),
                let typeAnnotationSyntax = patternBindingSyntax.typeAnnotation,
                patternBindingSyntax.accessorBlock == nil
            else {
                return nil
            }
            return .init(
                accessLevel: accessLevel,
                identifier: identifierSyntax,
                typeAnnotation: typeAnnotationSyntax
            )
        }

        return [
            try DeclSyntax(makeSnapshotStructure(accessLevel: accessLevel, properties: properties)),
            try DeclSyntax(
                makeSnapshotComputedProperty(accessLevel: accessLevel, properties: properties)),
            try DeclSyntax(makeInitializer(accessLevel: accessLevel, properties: properties)),
        ]
    }

    static func makeSnapshotStructure(accessLevel: AccessLevel, properties: [Property])
        throws -> StructDeclSyntax
    {
        try StructDeclSyntax(
            "\(raw: accessLevel.rawValue) struct Snapshot: EventStoreAdapter.Aggregate"
        ) {
            for property in properties {
                "\(try property.variableDeclSyntax)"
            }
            try InitializerDeclSyntax(
                "\(raw: accessLevel.rawValue) init(\(properties.functionParameterListSyntax))"
            ) {
                for property in properties {
                    "self.\(property.identifier) = \(property.identifier)"
                }
            }
        }
    }

    static func makeSnapshotComputedProperty(accessLevel: AccessLevel, properties: [Property])
        throws -> VariableDeclSyntax
    {
        try VariableDeclSyntax("\(raw: accessLevel.rawValue) var snapshot: Snapshot") {
            ".init(\(properties.labeledExprListSyntax))"
        }
    }

    static func makeInitializer(accessLevel: AccessLevel, properties: [Property]) throws
        -> InitializerDeclSyntax
    {
        try InitializerDeclSyntax("\(raw: accessLevel.rawValue) init(snapshot: Snapshot)") {
            for property in properties {
                "self.\(property.identifier) = snapshot.\(property.identifier)"
            }
        }
    }

    enum Error: Swift.Error, Sendable, CustomStringConvertible {
        case shouldBeActor

        var description: String {
            switch self {
            case .shouldBeActor:
                "This macro should only be applied to `actor` declarations"
            }
        }

    }
}
