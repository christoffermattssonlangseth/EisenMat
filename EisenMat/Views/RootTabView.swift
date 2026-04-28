import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            MatrixView()
                .tabItem { Label("Matrix", systemImage: "square.grid.2x2") }
            ArchiveView()
                .tabItem { Label("Archive", systemImage: "archivebox") }
            CompletedView()
                .tabItem { Label("Done", systemImage: "checkmark.circle") }
        }
    }
}
