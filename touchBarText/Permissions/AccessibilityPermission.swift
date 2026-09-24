import ApplicationServices

enum AccessibilityPermission {
    static func isTrusted(promptIfNeeded: Bool) -> Bool {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options: NSDictionary = [promptKey: promptIfNeeded]
        return AXIsProcessTrustedWithOptions(options)
    }
}
