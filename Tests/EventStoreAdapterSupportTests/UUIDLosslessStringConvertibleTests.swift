import Foundation
import Testing

@testable import EventStoreAdapterSupport

struct UUIDLosslessStringConvertibleTests {

    @Test func UUIDの文字列変換と復元が正しく動作する() {
        let original = UUID()
        let string = String(original)
        let restored = UUID(string)

        #expect(original == restored)
        #expect(string == original.uuidString)
    }

    @Test(
        arguments: [
            "550E8400-E29B-41D4-A716-446655440000",
            "550e8400-e29b-41d4-a716-446655440000",
            "00000000-0000-0000-0000-000000000000",
            "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF",
        ]
    )
    func 有効なUUID文字列形式から正しくUUIDを生成できる(uuidString: String) {
        let uuid = UUID(uuidString)
        #expect(uuid != nil)

        if let uuid = uuid {
            let restored = String(uuid)
            #expect(restored.uppercased() == uuidString.uppercased())
        }
    }

    @Test(
        arguments: [
            "",
            "not-a-uuid",
            "550E8400-E29B-41D4-A716",
            "550E8400-E29B-41D4-A716-446655440000-EXTRA",
            "550E8400-E29B-41D4-A716-44665544000G",
            "550E8400E29B41D4A716446655440000",
            "550E8400-E29B-41D4-A716-44665544000",
            "550E8400-E29B-41D4-A716-4466554400000",
            "550E8400-E29B-41D4-A716-446655440000 ",
            " 550E8400-E29B-41D4-A716-446655440000",
        ]
    )
    func 無効なUUID文字列からはnilが返される(invalidString: String) {
        let result = UUID(invalidString)
        #expect(result == nil, "Expected nil for invalid UUID string: '\(invalidString)'")
    }

    @Test(arguments: 1...100)
    func ランダムなUUIDでの往復変換が正しく動作する(iteration: Int) {
        let original = UUID()
        let string = String(original)
        let restored = UUID(string)

        #expect(
            original == restored, "Round trip failed for UUID: \(original) (iteration \(iteration))"
        )
    }
}
