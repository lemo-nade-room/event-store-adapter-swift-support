# EventStoreAdapterSupport

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20v15-blue.svg)](#)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
<a href="https://github.com/lemo-nade-room/event-store-adapter-swift/actions/workflows/ci.yaml">
<img src="https://github.com/lemo-nade-room/event-store-adapter-swift-support/actions/workflows/ci.yaml/badge.svg" alt="Testing Status">
</a>

`EventStoreAdapterSupport` は [lemo-nade-room/event-store-adapter-swift](https://github.com/lemo-nade-room/event-store-adapter-swift) ライブラリと併用するための便利なヘルパーやマクロを提供するライブラリです。

現在は以下の機能を提供しています:

- `@EventSupport` (Macro)  
  `EventStoreAdapter.Event` に準拠した `enum` に適用すると、  
  イベントが共通して持つべきプロパティ（`id`, `aggregateId`, `sequenceNumber`, `occurredAt`, `isCreated`）を自動生成します。

## 特徴

- Swift Macros を活用し、少ないコード記述で定型的なイベントプロパティを追加できます。
- `EventSupport` マクロは `EventStoreAdapter.Event` に準拠した `enum` にのみ適用可能です。
- 現在は主に `@EventSupport` マクロのみですが、今後は EventStoreAdapter を扱う上で便利なヘルパーを追加する予定です。

## インストール

Swift Package Manager を使用して、以下のように依存パッケージとして追加してください。

```swift
dependencies: [
    .package(url: "https://github.com/lemo-nade-room/event-store-adapter-swift-support.git", branch: "main")
]
```

そして、ターゲットの依存関係に `EventStoreAdapterSupport` を追加します。

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "EventStoreAdapterSupport", package: "event-store-adapter-swift-support"),
        // 他の依存...
    ]
)
```

## 使い方

### 1. `enum` の宣言

```swift
import EventStoreAdapter
import EventStoreAdapterSupport
import Foundation

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

    // @EventSupport を付与すると、共通プロパティが自動生成されます。
    @EventSupport
    enum Event: EventStoreAdapter.Event {
        case created(AccountCreated)
        case deleted(AccountDeleted)

        // 自動生成されるプロパティが参照する型を定義
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
```

### 2. 自動生成されるコード例

```swift
// コンパイル後に下記のようなコードが追加されます (アクセス修飾子は例としてinternal)。
extension Account.Event {
    internal var id: Self.Id {
        switch self {
        case .created(let event):
            event.id
        case .deleted(let event):
            event.id
        }
    }

    internal var aggregateId: Self.AggregateId {
        switch self {
        case .created(let event):
            event.aggregateId
        case .deleted(let event):
            event.aggregateId
        }
    }

    internal var sequenceNumber: Int {
        switch self {
        case .created(let event):
            event.sequenceNumber
        case .deleted(let event):
            event.sequenceNumber
        }
    }

    internal var occurredAt: Date {
        switch self {
        case .created(let event):
            event.occurredAt
        case .deleted(let event):
            event.occurredAt
        }
    }

    internal var isCreated: Bool {
        switch self {
        case .created(let event):
            event.isCreated
        case .deleted(let event):
            event.isCreated
        }
    }
}
```

## ライセンス

このライブラリは [MIT License](./LICENSE) のもとで配布されています。詳細は `LICENSE` ファイルを参照してください。

---

## 連絡先

- [lemo-nade-room/event-store-adapter-swift](https://github.com/lemo-nade-room/event-store-adapter-swift)
- その他質問などがある場合は、Issue もしくはプルリクエストでお知らせください。
