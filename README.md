# EventStoreAdapterSupport

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20v15-blue.svg)](#)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/lemo-nade-room/event-store-adapter-swift-support/actions/workflows/ci.yaml/badge.svg)](https://github.com/lemo-nade-room/event-store-adapter-swift-support/actions)

`EventStoreAdapterSupport` は、  
[lemo-nade-room/event-store-adapter-swift](https://github.com/lemo-nade-room/event-store-adapter-swift)  
と組み合わせて利用できる **Swift Macros** ベースの拡張ライブラリです。  
イベントソーシング・CQRS を用いた開発において、「煩雑なボイラープレートコード」を最小化するための仕組みを提供します。

## 概要

このライブラリが提供する主な機能は次のとおりです。

1. **`@AggregateActor` (Macro)**  
   - Swift の `actor` に付与すると、  
     そのアクターの状態を表す **スナップショット用構造体** と **スナップショット取得/復元用のプロパティ・イニシャライザ** を自動的に生成します。  
   - スナップショット型は `EventStoreAdapter.Aggregate` に準拠するため、**エンティティの保存や復元**を簡素化します。

2. **`@EventSupport` (Macro)**  
   - `EventStoreAdapter.Event` に準拠した `enum` に付与すると、  
     イベントが **共通して持つべきプロパティ**（`id`, `aid`, `seqNr`, `occurredAt`, `isCreated`）を自動的に生成します。  
   - 列挙子ごとに共通の値を取り出すための冗長な `switch` 文を省略できます。

本リポジトリには、これら 2 つのマクロの動作確認用テストが含まれています。  
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

// @EventSupport を適用
@EventSupport
enum AccountEvent: EventStoreAdapter.Event {
    case created(AccountCreated)
    case deleted(AccountDeleted)

    // プロトコル要件 (ID 型/ AID 型)
    typealias Id = UUID
    typealias AID = AccountID
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

- `enum` は **`EventStoreAdapter.Event`** に準拠している必要があります。  
  (`typealias Id` と `typealias AID` の設定を忘れずに行う)
- 列挙子のペイロード型も、`EventStoreAdapter.Event` プロトコルの必須プロパティを正しく実装していないといけません。
- タプル形式 (`case created(id: UUID, seqNr: Int)`) などのケースは非対応です。必ず **構造体・クラスなどの型**を割り当ててください。

---

### 2. `@AggregateActor` マクロ

`@AggregateActor` は、**Swift の `actor`** に付与し、スナップショット型 (`Snapshot`) や初期化メソッドを自動生成するマクロです。  
Event Sourcing では **スナップショット**を使ってアクター (集約) の最新状態を保存・復元することがありますが、  
このマクロを用いると煩雑なスナップショット用コードを自動的に生成できます。

#### 使用例

```swift
import EventStoreAdapter
import EventStoreAdapterSupport
import Foundation

@AggregateActor
public actor UserAccount {
    // 以下のプロパティがスナップショット化される
    var aid: AID
    var seqNr: Int
    var version: Int
    var lastUpdatedAt: Date

    // 通常のイニシャライザ
    public init(aid: AID, seqNr: Int, version: Int, lastUpdatedAt: Date) {
        self.aid = aid
        self.seqNr = seqNr
        self.version = version
        self.lastUpdatedAt = lastUpdatedAt
    }

    // 集約ID
    public struct AID: AggregateId {
        public static let name = "user_account"
        public var value: UUID
        // ...
    }

    // ------------------------------------
    // @AggregateActor により生成されるもの:
    //
    // public struct Snapshot: EventStoreAdapter.Aggregate {
    //     public var aid: AID
    //     public var seqNr: Int
    //     public var version: Int
    //     public var lastUpdatedAt: Date
    //
    //     public init(...){...}
    // }
    //
    // public var snapshot: Snapshot {
    //     .init(aid: aid, seqNr: seqNr, version: version, lastUpdatedAt: lastUpdatedAt)
    // }
    //
    // public init(snapshot: Snapshot) {
    //     self.aid = snapshot.aid
    //     self.seqNr = snapshot.seqNr
    //     self.version = snapshot.version
    //     self.lastUpdatedAt = snapshot.lastUpdatedAt
    // }
    // ------------------------------------
}
```

上記のように、**アクター内部のストアドプロパティ**を使って `Snapshot` 構造体を自動生成し、  
`actor` からは `snapshot` プロパティでその時点の状態を取得できるようになります。  
また、`init(snapshot:)` によって、スナップショットを使ったアクターの **復元**（リストア）も容易になります。

#### メリット

- アクター内の状態を一括して **スナップショット構造体** にまとめるための宣言を手書きする必要がありません。
- **プロパティの追加/削除** による変更にも容易に追従し、  
  スナップショットとの不整合を**マクロが防止**してくれます。

#### 注意点

- `actor` に対するマクロであるため、`class` や `struct` などには適用できません。
- カスタムアクセサ (`get`/`set`/`willSet`/`didSet`) を持つプロパティはスナップショット対象外となります。
- private スコープのプロパティも含め、ストアドプロパティはすべてスナップショットに含まれる可能性があるため注意してください。

---

## FAQ

### Q. `EventStoreAdapter.Event` に準拠しない `enum` に `@EventSupport` を付けたらどうなる？

A. コンパイル時にエラーが発生します。マクロが適用できない旨のエラーメッセージが表示されます。

### Q. `@AggregateActor` で生成される `Snapshot` にはアクセスレベルを付けられる？

A. アクターに付与されている修飾子 (`public`, `internal` など) に準じて生成されます。  
例えば、`public actor SomeActor` に適用すると、`public struct Snapshot` が生成されます。

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
  DynamoDB ベースの実装や、インメモリ実装など、CQRS + Event Sourcing を Swift で使うための各種機能を提供。

- **Issue や PR**  
  ご意見・ご要望・バグ報告などがあれば、Issue もしくはプルリクエストでお知らせください。
