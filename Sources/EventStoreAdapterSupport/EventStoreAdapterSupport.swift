@attached(
    member, names: named(id), named(aid), named(seqNr), named(occurredAt),
    named(isCreated))
public macro EventSupport() =
    #externalMacro(module: "EventStoreAdapterSupportMacro", type: "EventSupport")
