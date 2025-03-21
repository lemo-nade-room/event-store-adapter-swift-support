public import SwiftSyntax
public import SwiftSyntaxMacros

public struct EventSupport: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw Error.onlyApplicableToEnum
        }

        guard
            let inheritanceClause = enumDecl.inheritanceClause,
            inheritanceClause.inheritedTypes
                .compactMap({ $0.type.as(MemberTypeSyntax.self)?.name.identifier?.name })
                .contains("Event")
        else {
            throw Error.missingConformanceToEventStoreAdapterEvent
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

    public enum Error: Swift.Error, CustomStringConvertible {
        case onlyApplicableToEnum
        case missingConformanceToEventStoreAdapterEvent

        public var description: String {
            switch self {
            case .onlyApplicableToEnum:
                "@EventSupport can only be applied to an enum."
            case .missingConformanceToEventStoreAdapterEvent:
                "The annotated type must conform to EventStoreAdapter.Event."
            }
        }
    }
}
