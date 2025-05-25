# EventStoreAdapterSupport

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20v15-blue.svg)](#)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/lemo-nade-room/event-store-adapter-swift-support/actions/workflows/ci.yaml/badge.svg)](https://github.com/lemo-nade-room/event-store-adapter-swift-support/actions)

[日本語] [English](./README.md)

`EventStoreAdapterSupport` は、  
[lemo-nade-room/event-store-adapter-swift](https://github.com/lemo-nade-room/event-store-adapter-swift)  
と組み合わせて利用できる **Swift Macros** ベースの拡張ライブラリです。  
イベントソーシング・CQRS を用いた開発において、「煩雑なボイラープレートコード」を最小化するための仕組みを提供します。

## 概要

このライブラリが提供する主な機能は次のとおりです。

**`@EventSupport` (Macro)**
- `EventStoreAdapter.Event` に準拠した `enum` に付与すると、
  イベントが **共通して持つべきプロパティ**（`id`, `aid`, `seqNr`, `occurredAt`, `isCreated`）を自動的に生成します。
- 列挙子ごとに共通の値を取り出すための冗長な `switch` 文を省略できます。

本リポジトリには、このマクロの動作確認用テストが含まれています。
加えて、今後 `event-store-adapter-swift` ライブラリの使用をより便利にするための **追加ヘルパー** も実装予定です。

---

## インストール方法

### Swift Package Manager (SPM)

1. **Package.swift** で依存関係を追加する

    ```swift
    dependencies: [
        // ...
        .package(
            url: "https://github.com/lemo-nade-room/event-store-adapter-swift-support.git",
            branch: "main"
        )
    ]
    ```

2. **ターゲット**に `EventStoreAdapterSupport` を組み込む

    ```swift
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "EventStoreAdapterSupport", package: "event-store-adapter-swift-support"),
            // ほか依存パッケージ...
        ]
    )
    ```

3. `swift build` または Xcode 上でビルド・実行

---

## 使い方とサンプル

### 1. `@EventSupport` マクロ

`@EventSupport` は、`enum` 宣言に対し共通イベントプロパティを**自動生成**するマクロです。  
特に **`EventStoreAdapter.Event`** に準拠した列挙型に適用することを想定しています。

#### 典型例

```swift
import EventStoreAdapter
import EventStoreAdapterSupport
import Foundation

// まずイベントのペイロード型を定義 (ここでは例として2種類)
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

// 集約ID (AggregateId)
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

// @EventSupport を適用（EventStoreAdapter.Event継承あり）
@EventSupport
enum AccountEvent: EventStoreAdapter.Event {
    case created(AccountCreated)
    case deleted(AccountDeleted)

    // プロトコル要件 (ID 型/ AID 型)
    typealias Id = UUID
    typealias AID = AccountID
}

// プロトコル継承なしでも使用可能
@EventSupport
enum SomeEvent {  // プロトコル継承は任意
    case happened(SomeData)
    case occurred(OtherData)
    
    typealias Id = UUID
    typealias AID = UUID
}

// 非修飾名でも使用可能
@EventSupport
enum TodoEvent: Event {  // EventStoreAdapter.Event の代わりに Event でも OK
    case created(TodoCreated)
    case updated(TodoUpdated)
    
    typealias Id = UUID
    typealias AID = TodoID
}
```

この `@EventSupport` マクロを適用すると、**列挙型が自動的に下記のプロパティ**を持つようになります。

- `var id: Self.Id`
- `var aid: Self.AID`
- `var seqNr: Int`
- `var occurredAt: Date`
- `var isCreated: Bool`

列挙子を切り替える `switch self` が生成されるので、同様のコードを手書きする必要はありません。  
具体的には、以下のようなコードが（内部的に）追加されます:

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

#### メリット

- **イベントごとに重複するコードを大幅に削減**
- **将来的にイベントケースが増えても、同じ型構造なら自動スイッチが拡張**
- **enum の可読性・保守性の向上**

#### 注意点

- `@EventSupport` は任意の `enum` に適用できます。プロトコル継承は必須ではありません。
- 生成されるプロパティ（`id`, `aid`, `seqNr`, `occurredAt`, `isCreated`）を使用する場合は、列挙子のペイロード型がこれらのプロパティを持つ必要があります。
- タプル形式 (`case created(id: UUID, seqNr: Int)`) などのケースは非対応です。必ず **構造体・クラスなどの型**を割り当ててください。
- `EventStoreAdapter.Event` と組み合わせて使用する場合は、適切な `typealias Id` と `typealias AID` の設定を行ってください。


---

## FAQ

### Q. `EventStoreAdapter.Event` に準拠しない `enum` に `@EventSupport` を付けたらどうなる？

A. 問題ありません。`@EventSupport` はプロトコル継承を要求しないため、任意の `enum` に適用できます。ただし、生成されるプロパティを使用する場合は、列挙子のペイロード型が対応するプロパティを持つ必要があります。


### Q. タプル形式の `case created(id: UUID)` のようなものは `@EventSupport` でサポートされる？

A. 現状は**サポートしていません**。必ず **構造体**など、`EventStoreAdapter.Event` を満たす型を `case` のペイロードに指定してください。

### Q. マクロが生成するコードはどこで確認できる？

A. Xcode の `DerivedData` フォルダ内のビルド成果物や、`swift build` 実行後の出力で確認できます。  
Swift 6.0 時点では、マクロ生成コードを直接閲覧するための簡易なコマンドが用意されていません。  
ただし、エラー発生時などにコンソールへ部分的に表示される場合があります。

---

## ライセンス

このライブラリは [MIT License](./LICENSE) のもとで配布されています。  
詳細は `LICENSE` ファイルを参照してください。

---

## 関連リンク

- **Event Store Adapter (本家ライブラリ)**  
  [lemo-nade-room/event-store-adapter-swift](https://github.com/lemo-nade-room/event-store-adapter-swift)

- **Issue や PR**  
  ご意見・ご要望・バグ報告などがあれば、Issue もしくはプルリクエストでお知らせください。