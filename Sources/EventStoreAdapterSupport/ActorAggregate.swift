/// # `ActorAggregate` Macro
///
/// `@ActorAggregate` は、Swift の `actor` 宣言に対して自動的に初期化処理やスナップショット用の構造体を追加するためのマクロです。
/// CQRS + Event Sourcing の文脈で、**アクターが持つプロパティ**を利用してスナップショット型を生成し、
/// アクターに「スナップショット取得用プロパティ (`snapshot`)」と「スナップショットから復元するための初期化メソッド (`init(snapshot:)`)」を追加します。
///
/// ## 概要
///
/// - `actor` のプロパティから、スナップショットを表す内部構造体 `Snapshot` を自動生成します。
/// - 生成される `Snapshot` は `EventStoreAdapter.Aggregate` プロトコルに準拠します。
/// - `actor` に、`var snapshot: Snapshot` と `init(snapshot:)` を追加します。
/// - スナップショットを用いて、アクターの現在の状態を取り出す・復元することができるようになります。
/// - CQRS + Event Sourcing のリポジトリ実装などで、アクターの状態をスナップショットとして格納する際に便利です。
///
/// ## 付与対象
///
/// このマクロは **`actor` 宣言** に対して付与する必要があります。
/// `struct` や `class` など、`actor` 以外の宣言に付与すると、コンパイル エラーが発生します。
///
/// ```swift
/// @ActorAggregate
/// public actor UserAccount {
///     var aid: AID
///     var seqNr: Int
///     var version: Int
///     var lastUpdatedAt: Date
///
///     // ...
/// }
/// ```
///
/// ## 自動生成されるもの
///
/// ### `Snapshot` 構造体
///
/// - アクター内に存在する**ストアドプロパティ**（`var` で宣言され、かつゲッター/セッターのブロックがないもの）を元に、同名・同型のプロパティを持つ `Snapshot` 構造体が生成されます。
/// - `Snapshot` 構造体は `EventStoreAdapter.Aggregate` プロトコルに準拠するため、`aid`, `seqNr`, `version`, `lastUpdatedAt` 等の集約における共通情報を表すプロパティが含まれます。
/// - 自動生成されるイニシャライザ `init(...)` では、アクターと同じプロパティリストを引数として受け取り、`Snapshot` の各プロパティを初期化します。
///
/// ### `var snapshot: Snapshot`
///
/// - アクターに `snapshot` プロパティが追加されます。
/// - これは読み取り専用で、アクターの持つ各プロパティから `Snapshot` を作成して返す機能を提供します。
/// - 例えば `actor` が持つ `aid: AID`, `seqNr: Int` などの値が、自動的に `Snapshot` 構造体へコピーされ、返されます。
///
/// ### `init(snapshot:)`
///
/// - `init(snapshot:)` がアクターに追加され、`Snapshot` を受け取り、その中のプロパティの値をアクターにコピーすることで、**アクターの状態を復元**できます。
/// - 例えばデータベースに保存されたスナップショットを読み込み、それを渡すことで、このマクロを付与したアクターの状態を再現できます。
///
/// ## 使用例
///
/// ```swift
/// import EventStoreAdapter
/// import EventStoreAdapterSupport
/// import Foundation
///
/// @ActorAggregate
/// public actor UserAccount {
///     // このプロパティたちがスナップショットにも含まれる
///     var aid: AID
///     var seqNr: Int
///     var version: Int
///     var lastUpdatedAt: Date
///
///     // 通常のアクターイニシャライザ
///     public init(aid: AID, seqNr: Int, version: Int, lastUpdatedAt: Date) {
///         self.aid = aid
///         self.seqNr = seqNr
///         self.version = version
///         self.lastUpdatedAt = lastUpdatedAt
///     }
///
///     // 集約ID型
///     public struct AID: AggregateId {
///         public static let name = "user_account"
///         public var value: UUID
///         public init(value: UUID) { self.value = value }
///         public init?(_ description: String) {
///             guard let uuid = UUID(uuidString: description) else { return nil }
///             self.value = uuid
///         }
///         public var description: String { value.uuidString }
///     }
///
///     // ----------------------------
///     // @ActorAggregate によって自動生成されるもの:
///     //
///     // public struct Snapshot: EventStoreAdapter.Aggregate {
///     //     public var aid: AID
///     //     public var seqNr: Int
///     //     public var version: Int
///     //     public var lastUpdatedAt: Date
///     //
///     //     public init(aid: AID, seqNr: Int, version: Int, lastUpdatedAt: Date) {
///     //         self.aid = aid
///     //         self.seqNr = seqNr
///     //         self.version = version
///     //         self.lastUpdatedAt = lastUpdatedAt
///     //     }
///     // }
///     //
///     // public var snapshot: Snapshot {
///     //     .init(aid: aid, seqNr: seqNr, version: version, lastUpdatedAt: lastUpdatedAt)
///     // }
///     //
///     // public init(snapshot: Snapshot) {
///     //     self.aid = snapshot.aid
///     //     self.seqNr = snapshot.seqNr
///     //     self.version = snapshot.version
///     //     self.lastUpdatedAt = snapshot.lastUpdatedAt
///     // }
///     // ----------------------------
/// }
/// ```
///
/// ### 復元処理の流れ
///
/// 1. `UserAccount` のスナップショットがデータベースに格納されていたとします（`snapshot` フィールドは `UserAccount.Snapshot` 型）。
/// 2. データベースから `UserAccount.Snapshot` をロードしたら、`UserAccount(snapshot:)` を使ってアクターを復元できます。
/// 3. そのアクターの `snapshot` プロパティを参照すると、最新状態のスナップショットが取得できます。
///
/// ```swift
/// // データベースから snapshot を取得
/// let loadedSnapshot: UserAccount.Snapshot = ...
/// // アクターの復元
/// let userActor = UserAccount(snapshot: loadedSnapshot)
///
/// // 状態の確認や操作
/// print(userActor.snapshot.seqNr) // 取得したスナップショットのseqNr
/// ```
///
/// ## メリット
///
/// - **冗長なコードの排除**: スナップショット用の構造体と、スナップショット/復元処理を手動で書く必要がありません。
/// - **保守性の向上**: アクターのプロパティを変更した際、スナップショット型も自動的に同期されるため、型の整合性を保つのが容易です。
/// - **Event Sourcing との相性**: CQRS + Event Sourcing でスナップショットが必要な場面で、非常にシンプルに実装できます。
///
/// ## 注意点
///
/// - スナップショット構造体には、アクター内のすべてのストアドプロパティが含まれます（`private`, `fileprivate` スコープ含む）。
///   （Swift のマクロはソースコード変換の段階で動作するため、可視性制限を超えてプロパティへアクセスできます。）
/// - `@ActorAggregate` が付与される `actor` にカスタムアクセサ（`get`, `set`, `willSet`, `didSet` など）を持つプロパティがある場合、マクロは対象外とします。
///   自動的にスナップショットへ追加されない点にご注意ください。
/// - `ActorAggregate` は単一のアクターだけで使うケースを想定しています。
///   継承関係や非常に複雑なアクター定義（ジェネリクス多用など）には、動作保証がありません。
@attached(member, names: named(init), named(snapshot), named(Snapshot))
public macro ActorAggregate() =
    #externalMacro(module: "EventStoreAdapterSupportMacro", type: "ActorAggregate")
