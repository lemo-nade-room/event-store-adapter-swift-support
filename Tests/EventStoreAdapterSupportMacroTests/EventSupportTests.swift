import EventStoreAdapterSupportMacro
import MacroTesting
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import Testing

@Suite(
    .macros(
        record: .missing,
        macros: ["EventSupport": EventSupport.self]
    )
)
struct EventSupportTests {
    @Test func 正常系() async throws {
        assertMacro {
            """
            @EventSupport
            package enum Event: EventStoreAdapter.Event {
                case created(AccountCreated)
                case updated(AccountUpdated)
                case deleted(AccountDeleted)    

                typealias Id = UUID
                typealias AID = UUID
            }
            """
        } expansion: {
            """
            package enum Event: EventStoreAdapter.Event {
                case created(AccountCreated)
                case updated(AccountUpdated)
                case deleted(AccountDeleted)    

                typealias Id = UUID
                typealias AID = UUID

                package var id: Self.Id {
                    switch self {
                    case .created(let event):
                        event.id
                    case .updated(let event):
                        event.id
                    case .deleted(let event):
                        event.id
                    }
                }

                package var aid: Self.AID {
                    switch self {
                    case .created(let event):
                        event.aid
                    case .updated(let event):
                        event.aid
                    case .deleted(let event):
                        event.aid
                    }
                }

                package var seqNr: Int {
                    switch self {
                    case .created(let event):
                        event.seqNr
                    case .updated(let event):
                        event.seqNr
                    case .deleted(let event):
                        event.seqNr
                    }
                }

                package var occurredAt: Date {
                    switch self {
                    case .created(let event):
                        event.occurredAt
                    case .updated(let event):
                        event.occurredAt
                    case .deleted(let event):
                        event.occurredAt
                    }
                }

                package var isCreated: Bool {
                    switch self {
                    case .created(let event):
                        event.isCreated
                    case .updated(let event):
                        event.isCreated
                    case .deleted(let event):
                        event.isCreated
                    }
                }
            }
            """
        }
    }

    @Test func アクセス修飾子がない場合はinternalで作成する() async throws {
        assertMacro {
            """
            @EventSupport
            enum Event: EventStoreAdapter.Event {
                case created(AccountCreated)
                case updated(AccountUpdated)
                case deleted(AccountDeleted)    

                typealias Id = UUID
                typealias AggregateId = UUID
            }
            """
        } expansion: {
            """
            enum Event: EventStoreAdapter.Event {
                case created(AccountCreated)
                case updated(AccountUpdated)
                case deleted(AccountDeleted)    

                typealias Id = UUID
                typealias AggregateId = UUID

                internal var id: Self.Id {
                    switch self {
                    case .created(let event):
                        event.id
                    case .updated(let event):
                        event.id
                    case .deleted(let event):
                        event.id
                    }
                }

                internal var aid: Self.AID {
                    switch self {
                    case .created(let event):
                        event.aid
                    case .updated(let event):
                        event.aid
                    case .deleted(let event):
                        event.aid
                    }
                }

                internal var seqNr: Int {
                    switch self {
                    case .created(let event):
                        event.seqNr
                    case .updated(let event):
                        event.seqNr
                    case .deleted(let event):
                        event.seqNr
                    }
                }

                internal var occurredAt: Date {
                    switch self {
                    case .created(let event):
                        event.occurredAt
                    case .updated(let event):
                        event.occurredAt
                    case .deleted(let event):
                        event.occurredAt
                    }
                }

                internal var isCreated: Bool {
                    switch self {
                    case .created(let event):
                        event.isCreated
                    case .updated(let event):
                        event.isCreated
                    case .deleted(let event):
                        event.isCreated
                    }
                }
            }
            """
        }
    }

    @Test func enum以外に使用するとエラーメッセージを出す() async throws {
        assertMacro {
            """
            @EventSupport
            package struct Event: EventStoreAdapter.Event {
            }
            """
        } diagnostics: {
            """
            @EventSupport
            ┬────────────
            ╰─ 🛑 @EventSupport can only be applied to an enum.
            package struct Event: EventStoreAdapter.Event {
            }
            """
        }
    }

    @Test func Eventに準拠していなければエラーメッセージを出す() async throws {
        assertMacro {
            """
            @EventSupport
            package enum Event {
                case created(AccountCreated)
                case updated(AccountUpdated)
                case deleted(AccountDeleted)    

                typealias Id = UUID
                typealias AggregateId = UUID
            }
            """
        } diagnostics: {
            """
            @EventSupport
            ┬────────────
            ╰─ 🛑 The annotated type must conform to EventStoreAdapter.Event.
            package enum Event {
                case created(AccountCreated)
                case updated(AccountUpdated)
                case deleted(AccountDeleted)    

                typealias Id = UUID
                typealias AggregateId = UUID
            }
            """
        }
    }
}
