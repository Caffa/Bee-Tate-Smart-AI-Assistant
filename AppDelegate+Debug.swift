import SwiftUI
import Foundation
import OSLog

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// This extension can be applied to your existing AppDelegate
// If you don't have one, you'll need to create it and configure it properly
extension AppDelegate {
    func setupDebugMode() {
        let logger = Logger(subsystem: "com.beetate.assistant", category: "AppSetup")
        logger.info("🚀 Application is starting in debug mode")

        // Check for common issues
        checkEnvironment()

        // Register for notifications that might help debug
        #if os(macOS)
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let window = notification.object as? NSWindow {
                logger.info("Window became key: \(window.title)")
            }
        }
        #elseif os(iOS)
        NotificationCenter.default.addObserver(
            forName: UIWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { notification in
            logger.info("Window became key")
        }
        #endif

        // Log memory warnings
        #if os(iOS)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            logger.warning("⚠️ Memory warning received!")
        }
        #endif
    }

    private func checkEnvironment() {
        let logger = Logger(subsystem: "com.beetate.assistant", category: "Environment")

        // Check for development vs production
        #if DEBUG
        logger.info("Running in DEBUG mode")
        #else
        logger.info("Running in RELEASE mode")
        #endif

        // Log available disk space
        do {
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                let capacityInGB = Double(capacity) / (1024 * 1024 * 1024)
                logger.info("Available disk space: \(String(format: "%.2f GB", capacityInGB))")
            }
        } catch {
            logger.error("Error retrieving disk space: \(error.localizedDescription)")
        }
    }

    func presentDebugView() {
        #if os(macOS)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 800),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Debug View"
        window.contentView = NSHostingView(rootView: DiagnosticView())
        window.center()
        window.makeKeyAndOrderFront(nil)
        #elseif os(iOS)
        // For iOS, you would present this as a modal or push to navigation stack
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            let hostingController = UIHostingController(rootView: DiagnosticView())
            rootViewController.present(hostingController, animated: true)
        }
        #endif
    }
}

