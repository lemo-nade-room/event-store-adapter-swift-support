@attached(member, names: named(init), named(snapshot), named(Snapshot))
public macro ActorAggregate() =
    #externalMacro(module: "EventStoreAdapterSupportMacro", type: "ActorAggregate")
