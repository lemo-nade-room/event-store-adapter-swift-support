import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// The main compiler plugin for EventStoreAdapterSupport macros.
///
/// This plugin serves as the entry point for the Swift compiler to discover and use
/// the macros provided by the EventStoreAdapterSupport library. It registers all
/// available macros that can be used in Swift code.
///
/// ## Provided Macros
///
/// - `EventSupport`: Automatically generates common event properties for enums
///
/// ## Usage
///
/// This plugin is automatically loaded by the Swift compiler when the
/// EventStoreAdapterSupport package is imported. Users don't need to interact
/// with this plugin directly.
@main
struct EventStoreAdapterSupportMacro: CompilerPlugin {
  /// The list of macro types provided by this plugin.
  ///
  /// This array contains all the macro implementations that are available
  /// for use when the EventStoreAdapterSupport package is imported.
  var providingMacros: [any Macro.Type] = [
    EventSupport.self
  ]
}
