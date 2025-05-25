# EventStoreAdapterSupport

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20v15-blue.svg)](#)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/lemo-nade-room/event-store-adapter-swift-support/actions/workflows/swift-test.yaml/badge.svg)](https://github.com/lemo-nade-room/event-store-adapter-swift-support/actions)

[English] [日本語](./README.ja.md)

`EventStoreAdapterSupport` is a **Swift Macros**-based utility library designed to work seamlessly with [lemo-nade-room/event-store-adapter-swift](https://github.com/lemo-nade-room/event-store-adapter-swift). It provides mechanisms to minimize boilerplate code in Event Sourcing and CQRS development.

## Overview

This library provides the following key features:

**`@EventSupport` Macro**
- When applied to an `enum` conforming to `EventStoreAdapter.Event`, it automatically generates common event properties (`id`, `aid`, `seqNr`, `occurredAt`, `isCreated`).
- Eliminates the need for repetitive `switch` statements to extract common values from enum cases.

**`UUID+LosslessStringConvertible` Extension**
- Provides convenient string conversion capabilities for `Foundation.UUID` using Swift 6.0's `@retroactive` keyword.
- Essential for Event Sourcing scenarios where UUIDs are frequently used as event IDs and aggregate IDs.

This repository includes comprehensive tests for macro functionality and is designed to make working with the `event-store-adapter-swift` library more convenient.

---

## Installation

### Swift Package Manager (SPM)

1. **Add dependency in Package.swift**

    ```swift
    dependencies: [
        // ...
        .package(
            url: "https://github.com/lemo-nade-room/event-store-adapter-swift-support.git",
            branch: "main"
        )
    ]
    ```

2. **Add to your target**

    ```swift
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "EventStoreAdapterSupport", package: "event-store-adapter-swift-support"),
            // other dependencies...
        ]
    )
    ```

3. Build with `swift build` or in Xcode

---

## Usage and Examples

### 1. `@EventSupport` Macro

The `@EventSupport` macro automatically generates common event properties for `enum` declarations. It's specifically designed for enums conforming to `EventStoreAdapter.Event`.

#### Basic Example

```swift
import EventStoreAdapter
import EventStoreAdapterSupport
import Foundation

// Define event payload types
struct AccountCreated: EventStoreAdapter.Event {
    let id: UUID
    let aid: AccountID
    let seqNr: Int
    let occurredAt: Date
    let isCreated: Bool = true
    let name: String
}

struct AccountDeleted: EventStoreAdapter.Event {
    let id: UUID
    let aid: AccountID
    let seqNr: Int
    let occurredAt: Date
    let isCreated: Bool = false
}

// Aggregate ID
struct AccountID: AggregateId {
    static let name = "account"
    let value: UUID
    init(value: UUID) {
        self.value = value
    }
    init?(_ description: String) {
        guard let uuid = UUID(uuidString: description) else { return nil }
        self.value = uuid
    }
    var description: String { value.uuidString }
}

// Apply @EventSupport to enum conforming to EventStoreAdapter.Event
@EventSupport
enum AccountEvent: EventStoreAdapter.Event {
    case created(AccountCreated)
    case deleted(AccountDeleted)

    // Protocol requirements
    typealias Id = UUID
    typealias AID = AccountID
}

// Works without protocol conformance too
@EventSupport
enum SomeEvent {  // Protocol conformance is optional
    case happened(SomeData)
    case occurred(OtherData)
    
    typealias Id = UUID
    typealias AID = UUID
}

// Works with unqualified Event protocol name
@EventSupport
enum TodoEvent: Event {  // Event instead of EventStoreAdapter.Event
    case created(TodoCreated)
    case updated(TodoUpdated)
    
    typealias Id = UUID
    typealias AID = TodoID
}
```

When `@EventSupport` is applied, the enum automatically gains the following properties:

- `var id: Self.Id`
- `var aid: Self.AID`
- `var seqNr: Int`
- `var occurredAt: Date`
- `var isCreated: Bool`

The macro generates `switch self` statements internally, eliminating the need to write repetitive code. Specifically, code like this is added:

```swift
extension AccountEvent {
    internal var id: Self.Id {
        switch self {
        case .created(let event):
            return event.id
        case .deleted(let event):
            return event.id
        }
    }

    internal var aid: Self.AID {
        switch self {
        case .created(let event):
            return event.aid
        case .deleted(let event):
            return event.aid
        }
    }

    internal var seqNr: Int {
        switch self {
        case .created(let event):
            return event.seqNr
        case .deleted(let event):
            return event.seqNr
        }
    }

    internal var occurredAt: Date {
        switch self {
        case .created(let event):
            return event.occurredAt
        case .deleted(let event):
            return event.occurredAt
        }
    }

    internal var isCreated: Bool {
        switch self {
        case .created(let event):
            return event.isCreated
        case .deleted(let event):
            return event.isCreated
        }
    }
}
```

#### Benefits

- **Dramatically reduces repetitive code** across event types
- **Automatically extends switch statements** when new event cases are added with the same structure
- **Improves enum readability and maintainability**

#### Important Notes

- `@EventSupport` can be applied to any `enum`. Protocol conformance is not required.
- When using the generated properties (`id`, `aid`, `seqNr`, `occurredAt`, `isCreated`), the payload types of enum cases must have these properties.
- Tuple-style cases (`case created(id: UUID, seqNr: Int)`) are not supported. Always use **struct or class types** as payloads.
- When used with `EventStoreAdapter.Event`, ensure proper `typealias Id` and `typealias AID` definitions.

### 2. `UUID+LosslessStringConvertible` Extension

This extension makes `Foundation.UUID` conform to `LosslessStringConvertible` using Swift 6.0's `@retroactive` keyword, providing more intuitive string conversion APIs.

```swift
import EventStoreAdapterSupport
import Foundation

// Create UUID from string
let uuid = UUID("550E8400-E29B-41D4-A716-446655440000")

// Convert UUID to string
let uuidString = String(uuid)

// Round-trip conversion
let originalUUID = UUID()
let stringRepresentation = String(originalUUID)
let restoredUUID = UUID(stringRepresentation)
```

This is particularly useful in Event Sourcing scenarios where UUIDs are frequently used as event IDs and aggregate IDs, and string conversion is often required.

---

## FAQ

### Q. What happens if I apply `@EventSupport` to an enum that doesn't conform to `EventStoreAdapter.Event`?

A. No problem! `@EventSupport` doesn't require protocol conformance and can be applied to any `enum`. However, if you use the generated properties, the payload types of enum cases must have the corresponding properties.

### Q. Are tuple-style cases like `case created(id: UUID)` supported by `@EventSupport`?

A. Currently **not supported**. You must use **struct types** that satisfy `EventStoreAdapter.Event` requirements as case payloads.

### Q. Where can I see the code generated by the macro?

A. You can find it in Xcode's `DerivedData` folder build artifacts or in the output after running `swift build`. As of Swift 6.0, there's no simple command to directly view macro-generated code, though it may be partially displayed in the console during error conditions.

---

## Requirements

- **Swift 6.0+**
- **macOS 15.0+** (or other supported platforms)
- **Xcode 16.0+** (for development)

---

## License

This library is distributed under the [MIT License](./LICENSE).  
See the `LICENSE` file for details.

---

## Related Links

- **Event Store Adapter (Main Library)**  
  [lemo-nade-room/event-store-adapter-swift](https://github.com/lemo-nade-room/event-store-adapter-swift)

- **Issues and Pull Requests**  
  For feedback, feature requests, or bug reports, please create an Issue or Pull Request.

---

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
