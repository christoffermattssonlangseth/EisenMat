import Foundation
import SwiftData

enum SharedModelContainer {
    static let appGroupID = "group.com.langseth.eisenmat"

    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([TaskItem.self, Tag.self])
        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(isStoredInMemoryOnly: true)
        } else {
            config = ModelConfiguration(
                "EisenMat",
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier(appGroupID),
                cloudKitDatabase: .none
            )
        }
        return try ModelContainer(for: schema, configurations: [config])
    }
}
