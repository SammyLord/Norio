import NorioUI
import SwiftUI

struct NorioApp {
    static func main() {
        #if os(macOS)
        NorioMac.main()
        #elseif os(iOS)
        NorioiOS.main()
        #endif
    }
}

NorioApp.main() 