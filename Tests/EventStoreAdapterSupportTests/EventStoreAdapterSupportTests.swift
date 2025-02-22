import EventStoreAdapter
import EventStoreAdapterSupport
import Foundation
import Testing

@Test func マクロが使用できる() async throws {
    // Arrange
    struct Account: Aggregate {
        var id: Id
        var sequenceNumber: Int
        var version: Int
        var lastUpdatedAt: Date

        struct Id: AggregateId {
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
            typealias AggregateId = Account.Id
        }
    }

    struct AccountCreated: EventStoreAdapter.Event {
        var id: UUID
        var name: String
        var aggregateId: Account.Id
        var sequenceNumber: Int
        var occurredAt: Date
        var isCreated: Bool { true }
    }
    struct AccountDeleted: EventStoreAdapter.Event {
        var id: UUID
        var aggregateId: Account.Id
        var sequenceNumber: Int
        var occurredAt: Date
        var isCreated: Bool { false }
    }

    // Act
    let event = Account.Event.created(
        .init(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            name: "account",
            aggregateId: .init(value: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!),
            sequenceNumber: 1,
            occurredAt: ISO8601DateFormatter().date(from: "2022-01-01T00:00:00Z")!
        )
    )

    // Assert
    #expect(event.id == UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    #expect(
        event.aggregateId
            == Account.Id(value: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!))
    #expect(event.sequenceNumber == 1)
    #expect(event.occurredAt == ISO8601DateFormatter().date(from: "2022-01-01T00:00:00Z")!)
    #expect(event.isCreated == true)
}
