import EventStoreAdapter
import EventStoreAdapterSupport
import Foundation
import Testing

@Test
func EventSupportマクロが使用できる() async throws {
  // Arrange
  struct AccountAID: AggregateId {
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
  enum AccountEvent: EventStoreAdapter.Event {
    case created(AccountCreated)
    case deleted(AccountDeleted)

    typealias Id = UUID
    typealias AID = AccountAID
  }

  struct AccountCreated: EventStoreAdapter.Event {
    var id: UUID
    var name: String
    var aid: AccountAID
    var seqNr: Int
    var occurredAt: Date
    var isCreated: Bool { true }
  }
  struct AccountDeleted: EventStoreAdapter.Event {
    var id: UUID
    var aid: AccountAID
    var seqNr: Int
    var occurredAt: Date
    var isCreated: Bool { false }
  }

  // Act
  let event = AccountEvent.created(
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
      == AccountAID(value: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
  )
  #expect(event.seqNr == 1)
  #expect(event.occurredAt == ISO8601DateFormatter().date(from: "2022-01-01T00:00:00Z")!)
  #expect(event.isCreated == true)
}
