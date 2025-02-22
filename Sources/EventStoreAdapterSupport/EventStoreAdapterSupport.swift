/// # EventSupport
///
/// `EventStoreAdapter.Event` に準拠した `enum` に適用することで、
/// イベントが持つべき共通プロパティ（`id`, `aggregateId`, `sequenceNumber`, `occurredAt`, `isCreated`）を自動生成するマクロです。
///
/// このマクロは以下の特徴があります:
/// 1. **適用先:** `enum` のみが対象です。クラスや構造体には適用できません。
/// 2. **型要件:** 適用先の `enum` は `EventStoreAdapter.Event` に準拠している必要があります。
/// 3. **自動生成されるプロパティ:**
///    - `id: Self.Id`
///    - `aggregateId: Self.AggregateId`
///    - `sequenceNumber: Int`
///    - `occurredAt: Date`
///    - `isCreated: Bool`
///
/// アクセス修飾子について:
/// - マクロを適用した `enum` にアクセス修飾子（`public`, `internal` など）が指定されている場合は、
///   自動生成されるプロパティも同一のアクセスレベルとなります。
/// - アクセス修飾子が指定されていない場合は、`internal` として扱われます。
///
/// ## 使い方の例
///
/// 以下のように `@EventSupport` を付与するだけで、共通プロパティを自動的に追加できます。
///
/// ```swift
/// import EventStoreAdapter
/// import EventStoreAdapterSupport
/// import Foundation
///
/// // 何らかのAggregateの定義
/// struct Account: Aggregate {
///     var id: Id
///     var sequenceNumber: Int
///     var version: Int
///     var lastUpdatedAt: Date
///
///     struct Id: AggregateId {
///         static let name = "account"
///         init?(_ description: String) {
///             guard let value = UUID(uuidString: description) else {
///                 return nil
///             }
///             self.value = value
///         }
///         var description: String { value.uuidString }
///         init(value: UUID) {
///             self.value = value
///         }
///         var value: UUID
///     }
///
///     // イベント定義
///     @EventSupport
///     enum Event: EventStoreAdapter.Event {
///         case created(AccountCreated)
///         case deleted(AccountDeleted)
///
///         // マクロが自動生成したプロパティが
///         // 参照するための型エイリアス
///         typealias Id = UUID
///         typealias AggregateId = Account.Id
///     }
/// }
///
/// // イベントの実装例
/// struct AccountCreated: EventStoreAdapter.Event {
///     var id: UUID
///     var name: String
///     var aggregateId: Account.Id
///     var sequenceNumber: Int
///     var occurredAt: Date
///     var isCreated: Bool { true }
/// }
///
/// struct AccountDeleted: EventStoreAdapter.Event {
///     var id: UUID
///     var aggregateId: Account.Id
///     var sequenceNumber: Int
///     var occurredAt: Date
///     var isCreated: Bool { false }
/// }
/// ```
///
/// ## 適用前後のコード例
///
/// マクロを付与する前後で、コンパイラが生成してくれるコードは次のようになります。
/// （アクセス修飾子が明示されていない場合は `internal` として出力されます。）
///
/// ### `@EventSupport` 適用前
///
/// ```swift
/// enum Event: EventStoreAdapter.Event {
///     case created(AccountCreated)
///     case deleted(AccountDeleted)
///
///     typealias Id = UUID
///     typealias AggregateId = Account.Id
/// }
/// ```
///
/// ### `@EventSupport` 適用後
///
/// ```swift
/// enum Event: EventStoreAdapter.Event {
///     case created(AccountCreated)
///     case deleted(AccountDeleted)
///
///     typealias Id = UUID
///     typealias AggregateId = Account.Id
///
///     internal var id: Self.Id {
///         switch self {
///         case .created(let event):
///             event.id
///         case .deleted(let event):
///             event.id
///         }
///     }
///
///     internal var aggregateId: Self.AggregateId {
///         switch self {
///         case .created(let event):
///             event.aggregateId
///         case .deleted(let event):
///             event.aggregateId
///         }
///     }
///
///     internal var sequenceNumber: Int {
///         switch self {
///         case .created(let event):
///             event.sequenceNumber
///         case .deleted(let event):
///             event.sequenceNumber
///         }
///     }
///
///     internal var occurredAt: Date {
///         switch self {
///         case .created(let event):
///             event.occurredAt
///         case .deleted(let event):
///             event.occurredAt
///         }
///     }
///
///     internal var isCreated: Bool {
///         switch self {
///         case .created(let event):
///             event.isCreated
///         case .deleted(let event):
///             event.isCreated
///         }
///     }
/// }
/// ```
///
/// - Note: `enum` 以外に付与したり、`EventStoreAdapter.Event` への準拠がない場合はコンパイルエラーとなります。
@attached(
    member, names: named(id), named(aggregateId), named(sequenceNumber), named(occurredAt),
    named(isCreated))
public macro EventSupport() =
    #externalMacro(module: "EventStoreAdapterSupportMacro", type: "EventSupport")
