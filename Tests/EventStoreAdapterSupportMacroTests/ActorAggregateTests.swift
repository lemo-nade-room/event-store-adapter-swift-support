import EventStoreAdapterSupportMacro
import MacroTesting
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import Testing

@Suite(
    .macros(
        record: .missing,
        macros: ["ActorAggregate": ActorAggregate.self]
    )
)
struct ActorAggregateTests {
    @Test func LocalActor() async throws {
        assertMacro {
            """
            @ActorAggregate
            public actor Account {
                var aid: AID
                var name: String
                var seqNr: Int
                var version: Int
                var lastUpdatedAt: Date
                
                public init(
                    aid: AID,
                    name: String,
                    seqNr: Int,
                    version: Int,
                    lastUpdatedAt: Date
                ) {
                    self.aid = aid
                    self.name = name
                    self.seqNr = seqNr
                    self.version = version
                    self.lastUpdatedAt = lastUpdatedAt
                }

                public struct AID: AggregateId {
                    public static let name = "Account"
                    public var value: String
                    public init(value: String) {
                        self.value = value
                    }
                }
            }
            """
        } expansion: {
            """
            public actor Account {
                var aid: AID
                var name: String
                var seqNr: Int
                var version: Int
                var lastUpdatedAt: Date
                
                public init(
                    aid: AID,
                    name: String,
                    seqNr: Int,
                    version: Int,
                    lastUpdatedAt: Date
                ) {
                    self.aid = aid
                    self.name = name
                    self.seqNr = seqNr
                    self.version = version
                    self.lastUpdatedAt = lastUpdatedAt
                }

                public struct AID: AggregateId {
                    public static let name = "Account"
                    public var value: String
                    public init(value: String) {
                        self.value = value
                    }
                }

                public struct Snapshot: EventStoreAdapter.Aggregate {
                    public var aid: AID
                    public var name: String
                    public var seqNr: Int
                    public var version: Int
                    public var lastUpdatedAt: Date
                    public init(aid: AID, name: String, seqNr: Int, version: Int, lastUpdatedAt: Date) {
                        self.aid = aid
                        self.name = name
                        self.seqNr = seqNr
                        self.version = version
                        self.lastUpdatedAt = lastUpdatedAt
                    }
                }

                public var snapshot: Snapshot {
                    .init(aid: aid, name: name, seqNr: seqNr, version: version, lastUpdatedAt: lastUpdatedAt)
                }

                public init(snapshot: Snapshot) {
                    self.aid = snapshot.aid
                    self.name = snapshot.name
                    self.seqNr = snapshot.seqNr
                    self.version = snapshot.version
                    self.lastUpdatedAt = snapshot.lastUpdatedAt
                }
            }
            """
        }
    }
}
