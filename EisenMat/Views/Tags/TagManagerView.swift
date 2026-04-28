import SwiftUI
import SwiftData

struct TagManagerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Tag.name) private var tags: [Tag]
    @State private var newName = ""
    @State private var newColor: Color = .blue

    var body: some View {
        NavigationStack {
            List {
                Section("New tag") {
                    TextField("Name", text: $newName)
                    ColorPicker("Color", selection: $newColor, supportsOpacity: false)
                    Button("Add tag") { addTag() }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Section("Tags") {
                    ForEach(tags) { tag in
                        HStack {
                            Circle().fill(tag.color).frame(width: 14, height: 14)
                            Text(tag.name)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Tags")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func addTag() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let tag = Tag(name: name, colorHex: newColor.hexString)
        context.insert(tag)
        try? context.save()
        newName = ""
    }

    private func delete(at offsets: IndexSet) {
        for idx in offsets {
            context.delete(tags[idx])
        }
        try? context.save()
    }
}
