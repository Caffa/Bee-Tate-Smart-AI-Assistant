import SwiftUI
import Foundation
import OSLog

class AppDebugger {
    static let shared = AppDebugger()
    private let logger = Logger(subsystem: "com.beetate.assistant", category: "AppDebugger")

    func checkAppSetup() {
        logger.info("🔍 App Debugger: Starting diagnostics")

        // Check app bundle info
        if let bundleInfo = Bundle.main.infoDictionary {
            logger.info("📱 App Bundle: \(bundleInfo["CFBundleName"] as? String ?? "Unknown")")
            logger.info("📱 App Version: \(bundleInfo["CFBundleShortVersionString"] as? String ?? "Unknown")")
        } else {
            logger.error("❌ Could not access bundle information")
        }

        // Check file system access
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        logger.info("📁 Documents directory: \(documentsPath?.absoluteString ?? "Unknown")")

        // Check available memory
        let processInfo = ProcessInfo.processInfo
        let physicalMemory = Float(processInfo.physicalMemory) / (1024.0 * 1024.0 * 1024.0)
        logger.info("💾 System memory: \(String(format: "%.2f GB", physicalMemory))")

        // Log device info
        #if os(macOS)
        logger.info("💻 Running on macOS \(processInfo.operatingSystemVersionString)")
        #elseif os(iOS)
        logger.info("📱 Running on iOS \(UIDevice.current.systemVersion)")
        #endif
    }

    func validateViewRendering(_ view: some View, name: String) {
        logger.info("🖼 Attempting to render view: \(name)")
    }
}

struct DebugOverlay: ViewModifier {
    let viewName: String

    func body(content: Content) -> some View {
        content
            .border(Color.red, width: 1)
            .overlay(
                Text(viewName)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .padding(4)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(4),
                alignment: .topLeading
            )
            .onAppear {
                AppDebugger.shared.validateViewRendering(content, name: viewName)
            }
    }
}

extension View {
    func debugBorder(_ viewName: String) -> some View {
        self.modifier(DebugOverlay(viewName: viewName))
    }
}

