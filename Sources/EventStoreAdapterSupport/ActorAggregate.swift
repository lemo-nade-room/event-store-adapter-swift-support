//@attached(member, names: named(init), named(snapshot), named(Snapshot))
@attached(member, names: arbitrary)
public macro ActorAggregate() =
    #externalMacro(module: "EventStoreAdapterSupportMacro", type: "ActorAggregate")
