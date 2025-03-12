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

        let accessLevelKeywords: Set<Keyword> = [
            .open,
            .package,
            .public,
            .internal,
            .fileprivate,
            .private,
        ]
        let accessModifier =
            enumDecl.modifiers
            .first {
                accessLevelKeywords.map({ .keyword($0) })
                    .contains(
                        $0.name.tokenKind
                    )
            }

        return [
            try DeclSyntax(
                makeProperty(
                    name: "id", typeName: "Self.Id", elements: elements,
                    accessModifier: accessModifier)),
            try DeclSyntax(
                makeProperty(
                    name: "aid", typeName: "Self.AID", elements: elements,
                    accessModifier: accessModifier)),
            try DeclSyntax(
                makeProperty(
                    name: "seqNr", typeName: "Int", elements: elements,
                    accessModifier: accessModifier)),
            try DeclSyntax(
                makeProperty(
                    name: "occurredAt", typeName: "Date", elements: elements,
                    accessModifier: accessModifier)),
            try DeclSyntax(
                makeProperty(
                    name: "isCreated", typeName: "Bool", elements: elements,
                    accessModifier: accessModifier)),
        ]
    }

    private static func makeProperty(
        name: String,
        typeName: String,
        elements: [EnumCaseElementSyntax],
        accessModifier: DeclModifierSyntax?
    ) throws -> VariableDeclSyntax {
        try VariableDeclSyntax(
            "\(accessModifier?.name ?? "internal ")var \(raw: name): \(raw: typeName)"
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

private func fourCharacterCode(for characters: String) -> UInt32? {
    guard characters.count == 4 else { return nil }

    var result: UInt32 = 0
    for character in characters {
        result = result << 8
        guard let asciiValue = character.asciiValue else { return nil }
        result += UInt32(asciiValue)
    }
    return result
}
enum CustomError: Error { case message(String) }
