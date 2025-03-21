import EventStoreAdapter
import EventStoreAdapterSupport
import Foundation
import Testing

@Test func マクロが使用できる() async throws {
    // Arrange
    @ActorAggregate
    actor Account {
        var aid: AID
        var seqNr: Int
        var version: Int
        var lastUpdatedAt: Date

        init(aid: AID, seqNr: Int, version: Int, lastUpdatedAt: Date) {
            self.aid = aid
            self.seqNr = seqNr
            self.version = version
            self.lastUpdatedAt = lastUpdatedAt
        }

        struct AID: AggregateId {
            static let name = "account"
            init?(_ description: String) {
                guard let value = UUID(uuidString: description) else {
                    return nil
                }
                self.value = value
            }
            var description: String { value.uuidString }
            init(value: UUID) {
                self.value = value
            }
            var value: UUID
        }

        @EventSupport
        enum Event: EventStoreAdapter.Event {
            case created(AccountCreated)
            case deleted(AccountDeleted)

            typealias Id = UUID
            typealias AID = Account.AID
        }
    }

    struct AccountCreated: EventStoreAdapter.Event {
        var id: UUID
        var name: String
        var aid: Account.AID
        var seqNr: Int
        var occurredAt: Date
        var isCreated: Bool { true }
    }
    struct AccountDeleted: EventStoreAdapter.Event {
        var id: UUID
        var aid: Account.AID
        var seqNr: Int
        var occurredAt: Date
        var isCreated: Bool { false }
    }

    // Act
    let event = Account.Event.created(
        .init(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            name: "account",
            aid: .init(value: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!),
            seqNr: 1,
            occurredAt: ISO8601DateFormatter().date(from: "2022-01-01T00:00:00Z")!
        )
    )

    // Assert
    #expect(event.id == UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    #expect(
        event.aid
            == Account.AID(value: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!))
    #expect(event.seqNr == 1)
    #expect(event.occurredAt == ISO8601DateFormatter().date(from: "2022-01-01T00:00:00Z")!)
    #expect(event.isCreated == true)
}

extension UUID: @retroactive LosslessStringConvertible {
    init?(_ description: String) {
        self.init(uuidString: description)
    }
    var description: String {
        uuidString
    }
}
