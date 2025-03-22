import EventStoreAdapterSupportMacro
import MacroTesting
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import Testing

@Suite(
    .macros(
        record: .missing,
        macros: ["AggregateActor": AggregateActor.self]
    )
)
struct AggregateActorTests {
    @Test func LocalActor() async throws {
        assertMacro {
            """
            @AggregateActor
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

    @Test func DistributedActor() async throws {
        assertMacro {
            """
            @AggregateActor
            package distributed actor Account {
                var aid: AID
                var name: String
                var seqNr: Int
                var version: Int
                var lastUpdatedAt: Date
                
                package init(
                    actorSystem: ActorSystem,
                    aid: AID,
                    name: String,
                    seqNr: Int,
                    version: Int,
                    lastUpdatedAt: Date
                ) {
                    self.actorSystem = actorSystem
                    self.aid = aid
                    self.name = name
                    self.seqNr = seqNr
                    self.version = version
                    self.lastUpdatedAt = lastUpdatedAt
                }
                
                package struct AID: AggregateId {
                    package static let name = "Account"
                    package  var value: String
                    package init(_ value: String) {
                        self.value = value
                    }
                    package var description: String { value }
                }
            }
            """
        } expansion: {
            """
            package distributed actor Account {
                var aid: AID
                var name: String
                var seqNr: Int
                var version: Int
                var lastUpdatedAt: Date
                
                package init(
                    actorSystem: ActorSystem,
                    aid: AID,
                    name: String,
                    seqNr: Int,
                    version: Int,
                    lastUpdatedAt: Date
                ) {
                    self.actorSystem = actorSystem
                    self.aid = aid
                    self.name = name
                    self.seqNr = seqNr
                    self.version = version
                    self.lastUpdatedAt = lastUpdatedAt
                }
                
                package struct AID: AggregateId {
                    package static let name = "Account"
                    package  var value: String
                    package init(_ value: String) {
                        self.value = value
                    }
                    package var description: String { value }
                }

                package struct Snapshot: EventStoreAdapter.Aggregate {
                    package var aid: AID
                    package var name: String
                    package var seqNr: Int
                    package var version: Int
                    package var lastUpdatedAt: Date
                    package init(aid: AID, name: String, seqNr: Int, version: Int, lastUpdatedAt: Date) {
                        self.aid = aid
                        self.name = name
                        self.seqNr = seqNr
                        self.version = version
                        self.lastUpdatedAt = lastUpdatedAt
                    }
                }

                package distributed var snapshot: Snapshot {
                    .init(aid: aid, name: name, seqNr: seqNr, version: version, lastUpdatedAt: lastUpdatedAt)
                }

                package init(actorSystem: ActorSystem, snapshot: Snapshot) {
                    self.actorSystem = actorSystem
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
