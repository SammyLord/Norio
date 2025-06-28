import SwiftUI
// TODO: Add 'import NorioUI' after adding package dependency in Xcode

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Norio Browser")
                .font(.title)
            Text("Ready for package setup!")
                .font(.caption)
        }
        .padding()
        
        // TODO: Replace with BrowserView() after adding NorioUI package
        // BrowserView()
    }
}

#Preview {
    ContentView()
}
