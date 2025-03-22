/// # `AggregateActor` Macro
///
/// `@AggregateActor` は、Swift の `actor` および **`distributed actor`** 宣言に対して、
/// 自動的に初期化処理やスナップショット用の構造体を追加するためのマクロです。
/// CQRS + Event Sourcing の文脈で、**アクターが持つプロパティ**を利用してスナップショット型を生成し、
/// アクターに「スナップショット取得用プロパティ (`snapshot`)」と「スナップショットから復元するための初期化メソッド」を追加します。
///
/// ## 概要
///
/// - **通常の `actor`**
///   - `Snapshot` 構造体 (`EventStoreAdapter.Aggregate` 準拠) が生成される。
///   - `var snapshot: Snapshot` プロパティでスナップショットを取得できる。
///   - `init(snapshot:)` によってスナップショットで復元できる。
///
/// - **`distributed actor`**
///   - 上記に加え、マクロが `distributed var snapshot: Snapshot` を生成し、
///     `init(actorSystem: ActorSystem, snapshot: Snapshot)` も自動的に追加する。
///   - スナップショット取得や復元時に `actorSystem` を扱うためのコードが付与される。
///   - 従来どおりの通常イニシャライザだけでなく、`distributed actor` 特有のイニシャライザパターン（`actorSystem` を引数に含む）にも対応。
///
/// 結果として、CQRS + Event Sourcing で必要となるスナップショットの保存・復元フローが簡素化されます。
///
///
/// ## 付与対象
///
/// このマクロは **`actor` または `distributed actor`** 宣言に対して付与する必要があります。
/// それ以外（`struct`, `class` 等）に付与すると、コンパイルエラーが発生します。
///
/// ```swift
/// @AggregateActor
/// public actor UserAccount {
///     var aid: AID
///     var seqNr: Int
///     var version: Int
///     var lastUpdatedAt: Date
///     // ...
/// }
///
/// @AggregateActor
/// public distributed actor RemoteAccount {
///     // distributed actor 用のアクターシステムを保持
///     var aid: AID
///     var seqNr: Int
///     var version: Int
///     var lastUpdatedAt: Date
///     // ...
/// }
/// ```
///
/// ## 自動生成されるもの
///
/// ### 1. `Snapshot` 構造体
///
/// - アクター内部のストアドプロパティ（単純な `var` 宣言で、カスタムアクセサブロックが無いもの）を列挙し、
///   同じ名前・同じ型のプロパティを持つ `Snapshot` 構造体を自動生成します。
/// - 生成される `Snapshot` は `EventStoreAdapter.Aggregate` に準拠し、
///   `aid`, `seqNr`, `version`, `lastUpdatedAt` など、イベントソーシングで必要となる集約情報を含めることが可能です。
///
/// ### 2. `snapshot` プロパティ
///
/// - アクターから現在の状態を取り出すための `snapshot` プロパティが生成されます。
/// - すべてのストアドプロパティを `Snapshot` に詰め替えて返す形になります。
/// - `distributed actor` の場合は `distributed var snapshot: Snapshot` が生成され、
///   分散アクターであってもスナップショット取得をリモート呼び出しできるようになります。（アクセスレベルはアクターの修飾子に準じます）
///
/// ### 3. スナップショットによるイニシャライザ
///
/// - 通常の `actor` では `init(snapshot:)` が生成されます。
///   ```swift
///   public init(snapshot: Snapshot) {
///       self.aid = snapshot.aid
///       self.seqNr = snapshot.seqNr
///       self.version = snapshot.version
///       self.lastUpdatedAt = snapshot.lastUpdatedAt
///   }
///   ```
/// - `distributed actor` では、アクターシステム付きの `init(actorSystem: ActorSystem, snapshot: Snapshot)` が追加されます。
///   ```swift
///   public init(actorSystem: ActorSystem, snapshot: Snapshot) {
///       self.actorSystem = actorSystem
///       self.aid = snapshot.aid
///       self.seqNr = snapshot.seqNr
///       self.version = snapshot.version
///       self.lastUpdatedAt = snapshot.lastUpdatedAt
///   }
///   ```
/// - これにより、アクターをスナップショットから**復元**できるようになります。
///
///
/// ## 使用例
///
/// ### 通常の `actor` に適用
///
/// ```swift
/// import EventStoreAdapter
/// import EventStoreAdapterSupport
/// import Foundation
///
/// @AggregateActor
/// public actor UserAccount {
///     var aid: AID
///     var seqNr: Int
///     var version: Int
///     var lastUpdatedAt: Date
///
///     public init(aid: AID, seqNr: Int, version: Int, lastUpdatedAt: Date) {
///         self.aid = aid
///         self.seqNr = seqNr
///         self.version = version
///         self.lastUpdatedAt = lastUpdatedAt
///     }
///
///     public struct AID: AggregateId {
///         public static let name = "user_account"
///         public var value: UUID
///         // ...
///     }
///
///     // ↓ 以下のコードが自動生成されるイメージです
///     // public struct Snapshot: EventStoreAdapter.Aggregate { ... }
///     // public var snapshot: Snapshot { ... }
///     // public init(snapshot: Snapshot) { ... }
/// }
///
/// // ---- 使い方: スナップショットの保存・復元 ----
///
//  // スナップショットの保存
/// let actor = UserAccount(aid: .init(value: ...), seqNr: 10, version: 3, lastUpdatedAt: Date())
/// let snapshot = actor.snapshot  // ここで最新の状態を取得
/// // これをデータベースに保存するなど
///
/// // スナップショットの復元
/// let loadedSnapshot: UserAccount.Snapshot = ... // DB等からロード
/// let restoredActor = UserAccount(snapshot: loadedSnapshot)
/// // これで復元が完了
/// ```
///
/// ### `distributed actor` に適用
///
/// ```swift
/// import Distributed
/// import EventStoreAdapter
/// import EventStoreAdapterSupport
/// import Foundation
///
/// @AggregateActor
/// public distributed actor RemoteAccount {
///     // 分散アクター特有の actorSystem プロパティ
///     // （マクロ適用により init(actorSystem:..., snapshot:...) が自動生成される）
///     var aid: AID
///     var seqNr: Int
///     var version: Int
///     var lastUpdatedAt: Date
///
///     // distributed actor 向けのイニシャライザ
///     public init(actorSystem: ActorSystem, aid: AID, seqNr: Int, version: Int, lastUpdatedAt: Date) {
///         self.actorSystem = actorSystem
///         self.aid = aid
///         self.seqNr = seqNr
///         self.version = version
///         self.lastUpdatedAt = lastUpdatedAt
///     }
///
///     public struct AID: AggregateId {
///         public static let name = "remote_account"
///         public var value: UUID
///         // ...
///     }
///
///     // ↓ 以下のコードが自動生成されるイメージです
///     // public struct Snapshot: EventStoreAdapter.Aggregate { ... }
///     // public distributed var snapshot: Snapshot { ... }
///     // public init(actorSystem: ActorSystem, snapshot: Snapshot) { ... }
/// }
///
/// // ---- 使い方: 分散アクターの場合も同様にスナップショットで復元できる ----
/// // 例: actorSystem を使いリモートで呼び出すケースなどにも対応可能
/// ```
///
/// ## メリット
///
/// - **スナップショット用の構造体やイニシャライザを手書きする手間を大幅に削減**
///   アクター内のプロパティ変更時にもマクロが追従し、不整合を防ぎます。
///
/// - **分散アクター (Distributed Actor) にも同様の仕組みが適用**
///   `distributed var snapshot` や `init(actorSystem:..., snapshot:...)` などが自動生成され、リモート呼び出しや分散復元にも対応しやすくなります。
///
/// - **Event Sourcing との相性が良い**
///   スナップショットを簡単に生成・復元できるため、永続化レイヤーやリポジトリ実装をシンプルに保てます。
///
///
/// ## 注意点
///
/// - **アクター以外**（`struct`, `class` 等）には付与できません。付与するとコンパイルエラーになります。
/// - スナップショット対象は「カスタムアクセサの無いストアドプロパティ」だけです。`willSet`/`didSet` や計算プロパティは含まれません。
/// - `private` や `fileprivate` といったアクセスレベルのプロパティも含めて、マクロはコード上のプロパティを抽出します。
///   （コンパイル時のソース変換フェーズで解析するため）
/// - `distributed actor` の場合は、必ず **`actorSystem`** という名前のストアドプロパティが必要となります（Swift の言語仕様）。
///   マクロ適用時には、そのプロパティを `init` の引数として使用します。
/// - スナップショット構造体の名称は `Snapshot` に固定されます。カスタム名称を付けたい場合は手動で定義する方法をご検討ください。
///
///
/// ## まとめ
///
/// `@AggregateActor` マクロは、CQRS + Event Sourcing で多用される**スナップショット機能**を
/// `actor` と `distributed actor` の両方で直感的に扱えるようにするための仕組みを提供します。
/// ボイラープレートコードの削減や、保守性の向上に繋がります。
///
/// ```swift
/// @AggregateActor
/// actor SomeAggregate { /* ... */ }
///
/// @AggregateActor
/// distributed actor AnotherAggregate { /* ... */ }
/// ```
///
/// これにより、ローカル・リモート問わずアクターの状態を管理しやすくなります。
@attached(member, names: named(init), named(snapshot), named(Snapshot))
public macro AggregateActor() =
    #externalMacro(module: "EventStoreAdapterSupportMacro", type: "AggregateActor")
