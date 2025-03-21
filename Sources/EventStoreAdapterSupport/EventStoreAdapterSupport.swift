/// # `EventSupport` Macro
///
/// `@EventSupport` は、Swift の `enum` 宣言に対して **CQRS + Event Sourcing** で必要となるイベントの共通プロパティを自動生成します。
/// `EventStoreAdapter.Event` プロトコルに準拠した `enum`  が複数のケースを持つ場合、それぞれのケースが共通して持つべき以下のプロパティをスイッチで切り替えて返すコードをマクロが生成します。
///
/// - `id`: イベントの一意な識別子
/// - `aid`: 集約 ID (Aggregate ID)
/// - `seqNr`: イベントのシーケンス番号 (集約ごとに連番)
/// - `occurredAt`: イベントが起こった日時
/// - `isCreated`: 生成イベントかどうかを示すフラグ
///
/// ## 概要
///
/// - `enum` が `EventStoreAdapter.Event` に準拠していることを前提とし、列挙子（`case created(...)`, `case updated(...)` など）それぞれに含まれるペイロード型（`struct` など）のプロパティをまとめる目的で使用します。
/// - `@EventSupport` をつけることで、**すべての列挙子が共通して持つ必要があるプロパティ**を自動生成し、`switch self` で列挙子に応じた値を返す形のコードを付与します。
/// - 具体的には、下記のようなプロパティが生成されます。
///   1. `var id: Self.Id`
///   2. `var aid: Self.AID`
///   3. `var seqNr: Int`
///   4. `var occurredAt: Date`
///   5. `var isCreated: Bool`
///
/// ## 付与対象
///
/// - **`enum`** で、**`EventStoreAdapter.Event`** に準拠している型にのみ付与できます。
/// - `struct` や `class` 等に付与するとコンパイルエラーとなります。
/// - `enum` であっても `EventStoreAdapter.Event` に準拠していない場合、マクロ適用時にエラーが発生します。
///
/// ```swift
/// @EventSupport
/// public enum AccountEvent: EventStoreAdapter.Event {
///     case created(AccountCreated)
///     case updated(AccountUpdated)
///     // ...
/// }
/// ```
///
/// ## 自動生成されるもの
///
/// ### プロパティ一覧
///
/// 1. `id: Self.Id`
///    - 各ケースが保持するイベント型の `id` プロパティを返します。
///
/// 2. `aid: Self.AID`
///    - 集約IDを取得します。
///    - 例: `AccountCreated.aid`, `AccountUpdated.aid` など。
///
/// 3. `seqNr: Int`
///    - 集約ごとに一意な連番。
///    - 例えば `AccountCreated.seqNr`, `AccountUpdated.seqNr` を切り替えます。
///
/// 4. `occurredAt: Date`
///    - イベント発生時刻。
///    - 例: `AccountCreated.occurredAt`, `AccountUpdated.occurredAt` など。
///
/// 5. `isCreated: Bool`
///    - このイベントが「作成イベント（集約の初回作成）」かどうか。
///    - 例: `AccountCreated.isCreated` が `true` で、`AccountUpdated.isCreated` が `false`、など。
///
/// ### 生成されるコード例
///
/// #### 例: イベント定義
///
/// ```swift
/// @EventSupport
/// enum AccountEvent: EventStoreAdapter.Event {
///     case created(AccountCreated)
///     case updated(AccountUpdated)
///
///     // ここで定義が必要なもの:
///     // - typealias Id = UUID
///     // - typealias AID = Account.Id
/// }
/// ```
///
/// #### 例: 自動生成コード (概略)
///
/// ```swift
/// extension AccountEvent {
///     // id プロパティ
///     internal var id: Self.Id {
///         switch self {
///         case .created(let event):
///             event.id
///         case .updated(let event):
///             event.id
///         }
///     }
///
///     // aid プロパティ
///     internal var aid: Self.AID {
///         switch self {
///         case .created(let event):
///             event.aid
///         case .updated(let event):
///             event.aid
///         }
///     }
///
///     // seqNr プロパティ
///     internal var seqNr: Int {
///         switch self {
///         case .created(let event):
///             event.seqNr
///         case .updated(let event):
///             event.seqNr
///         }
///     }
///
///     // occurredAt プロパティ
///     internal var occurredAt: Date {
///         switch self {
///         case .created(let event):
///             event.occurredAt
///         case .updated(let event):
///             event.occurredAt
///         }
///     }
///
///     // isCreated プロパティ
///     internal var isCreated: Bool {
///         switch self {
///         case .created(let event):
///             event.isCreated
///         case .updated(let event):
///             event.isCreated
///         }
///     }
/// }
/// ```
///
/// ## 使い方
///
/// 1. まず `EventStoreAdapter.Event` プロトコルに必要な要件を満たすイベントの payload 型を用意します。
///    例: `AccountCreated`, `AccountUpdated` など。
///    これらは `id`, `aid`, `seqNr`, `occurredAt`, `isCreated` などのプロパティを持つ必要があります。
///
/// 2. それらを列挙型 `enum SomeEvent` の `case` に割り当てます。
///    ```swift
///    enum SomeEvent: EventStoreAdapter.Event {
///        case created(AccountCreated)
///        case updated(AccountUpdated)
///
///        // ここでプロトコル要件の `associatedtype Id`, `associatedtype AID` を満たすための型エイリアスを用意
///        typealias Id = UUID
///        typealias AID = MyAggregate.Id
///    }
///    ```
///
/// 3. `@EventSupport` を付与することで、`SomeEvent` の列挙子ごとに `id`, `aid`, `seqNr`, `occurredAt`, `isCreated` を自動実装します。
///
/// ```swift
/// @EventSupport
/// public enum SomeEvent: EventStoreAdapter.Event {
///     case created(AccountCreated)
///     case updated(AccountUpdated)
///
///     public typealias Id = UUID
///     public typealias AID = MyAggregate.Id
/// }
/// ```
///
/// 4. マクロが展開されると、`SomeEvent` 内に共通プロパティへのアクセスが追加されます。
///    これで、列挙子が `created` のとき・`updated` のとき等で切り替え処理を書く必要がなくなります。
///
/// ## メリット
///
/// - **冗長なスイッチを書く必要がない**: 各ケースに共通のイベント情報を取り出すためのスイッチ文を手書きで書く必要がありません。
/// - **コードの可読性向上**: 大量のイベントケースがあっても、同じような `var id`, `var aid` プロパティ実装を列挙子ごとにコピペする必要がありません。
/// - **保守コスト削減**: イベントケースを追加する際も、同じ型構造であればマクロが自動的にスイッチ文を拡張してくれます。
///
/// ## 注意点
///
/// - すべての列挙子のペイロード型（例: `AccountCreated`, `AccountUpdated`）が、それぞれ `EventStoreAdapter.Event` の必須プロパティ (`id`, `aid`, `seqNr`, `occurredAt`, `isCreated`) を実装している必要があります。
/// - `@EventSupport` はアクセスレベル修飾子（`public`, `internal` など）を自動推定します。
///   - 例えば `public enum SomeEvent` に対して付与した場合、生成されるプロパティも `public` になります。
///   - 修飾子が無い場合は `internal` 扱いとなります。
/// - 列挙子のペイロードがタプル形式（`case created(Int, String)` など）だと、`@EventSupport` からは参照できません。
///   必ず構造体・クラスなどの型を割り当ててください。
///
/// ## 使用例
///
/// ```swift
/// import Foundation
/// import EventStoreAdapter
/// import EventStoreAdapterSupport
///
/// @EventSupport
/// enum BlogPostEvent: EventStoreAdapter.Event {
///     case created(PostCreated)
///     case edited(PostEdited)
///     case published(PostPublished)
///
///     typealias Id = UUID
///     typealias AID = BlogPostId
/// }
///
/// struct PostCreated: EventStoreAdapter.Event {
///     let id: UUID
///     let aid: BlogPostId
///     let seqNr: Int
///     let occurredAt: Date
///     let isCreated: Bool = true
///
///     // ...
/// }
///
/// struct PostEdited: EventStoreAdapter.Event {
///     let id: UUID
///     let aid: BlogPostId
///     let seqNr: Int
///     let occurredAt: Date
///     let isCreated: Bool = false
///     // ...
/// }
///
/// struct PostPublished: EventStoreAdapter.Event {
///     let id: UUID
///     let aid: BlogPostId
///     let seqNr: Int
///     let occurredAt: Date
///     let isCreated: Bool = false
///     // ...
/// }
///
/// struct BlogPostId: AggregateId {
///     static let name = "BlogPost"
///     var value: UUID
///     // ...
/// }
/// ```
@attached(
    member, names: named(id), named(aid), named(seqNr), named(occurredAt),
    named(isCreated))
public macro EventSupport() =
    #externalMacro(module: "EventStoreAdapterSupportMacro", type: "EventSupport")
