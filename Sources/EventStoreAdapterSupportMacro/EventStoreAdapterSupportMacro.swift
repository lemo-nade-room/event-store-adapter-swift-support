import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct EventStoreAdapterSupportMacro: CompilerPlugin {
    var providingMacros: [any Macro.Type] = [
        EventSupport.self,
        AggregateActor.self,
    ]
}
