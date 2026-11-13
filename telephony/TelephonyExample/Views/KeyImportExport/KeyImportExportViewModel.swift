//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Observation
import SudoLogging

@Observable
@MainActor
final class KeyImportExportViewModel {

    // MARK: - Supplementary

    /// The password sheet currently shown.
    enum PasswordPrompt: Identifiable {
        case export
        case importBackup(KeyBackupFile)

        var id: String {
            switch self {
            case .export: return "export"
            case .importBackup: return "import"
            }
        }
    }

    /// A backup file written to a temporary location, ready to share.
    struct ExportedFile: Identifiable {
        let url: URL
        var id: URL { url }
    }

    // MARK: - Properties

    var passwordPrompt: PasswordPrompt?

    /// True while a backup is being encrypted or decrypted.
    var isWorking = false

    /// Why the last password attempt failed, shown in the password sheet.
    var passwordError: String?

    var exportedFile: ExportedFile?

    var showFileImporter = false

    /// True if the user should confirm replacing this device's keys with `pendingImport`.
    var showImportConfirmation = false

    /// The backup the user picked, awaiting confirmation.
    var pendingImport: KeyBackupFile?

    /// True once keys have been imported and `importResultMessage` should be presented.
    var showImportResult = false

    var importResultMessage = ""

    /// True if `errorMessage` should be presented to the user.
    var showError = false

    var errorMessage = ""

    @ObservationIgnored private var exportedFileAwaitingShare: ExportedFile?

    @ObservationIgnored private let dependencies: AppDependencies

    // MARK: - Lifecycle

    init(dependencies: AppDependencies = AppDelegate.dependencies) {
        self.dependencies = dependencies
    }

    // MARK: - Actions: Export

    func didTapExport() {
        passwordError = nil
        passwordPrompt = .export
    }

    func didEnterExportPassword(_ password: String) async {
        Logger.sampleLogger.info("Exporting keys...")
        isWorking = true
        defer { isWorking = false }
        Self.removeTemporaryBackups()
        do {
            let data = try await dependencies.keyBackupService.exportBackup(password: password)
            dependencies.didExportKeys()
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(Self.exportFileName())
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            exportedFileAwaitingShare = ExportedFile(url: url)
            passwordPrompt = nil
        } catch {
            Logger.sampleLogger.error("Failed to export keys: \(error)")
            passwordError = error.localizedDescription
        }
    }

    /// Shows the share sheet once the password sheet has gone, as only one sheet can be presented at a time.
    func didDismissPasswordPrompt() {
        exportedFile = exportedFileAwaitingShare
        exportedFileAwaitingShare = nil
    }

    /// Closes the share sheet once the user has shared the file or cancelled.
    func didFinishSharing() {
        exportedFile = nil
    }

    /// Removes the temporary backup file however the share sheet was closed, so the keys don't stay on disk.
    func didDismissShareSheet() {
        Self.removeTemporaryBackups()
    }

    // MARK: - Actions: Import

    func didTapImport() {
        showFileImporter = true
    }

    func didPickFile(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if isAccessing { url.stopAccessingSecurityScopedResource() }
            }
            let data = try Data(contentsOf: url)
            pendingImport = try dependencies.keyBackupService.readBackup(data)
            showImportConfirmation = true
        } catch {
            Logger.sampleLogger.error("Failed to read key backup: \(error)")
            presentError(error)
        }
    }

    func didConfirmImport() {
        guard let pendingImport else { return }
        passwordError = nil
        passwordPrompt = .importBackup(pendingImport)
    }

    /// Imports the keys, returning true if they were imported so the caller can refresh anything encrypted with them.
    func didEnterImportPassword(_ password: String, file: KeyBackupFile) async -> Bool {
        Logger.sampleLogger.info("Importing keys...")
        isWorking = true
        defer { isWorking = false }
        do {
            let result = try await dependencies.keyBackupService.importBackup(file, password: password)
            passwordPrompt = nil
            pendingImport = nil
            importResultMessage = Self.describe(result)
            showImportResult = true
            return true
        } catch {
            Logger.sampleLogger.error("Failed to import keys: \(error)")
            passwordError = error.localizedDescription
            return false
        }
    }

    func didCancelPasswordPrompt() {
        passwordPrompt = nil
        pendingImport = nil
    }

    // MARK: - Helpers

    /// Describes where a backup came from, e.g. "Exported from iOS on 30 Oct 2026".
    static func describe(_ file: KeyBackupFile) -> String {
        let platform: String
        switch file.platform {
        case "ios": platform = "iOS"
        case "android": platform = "Android"
        default: platform = file.platform
        }
        return "Exported from \(platform) on \(file.createdAt.formatted(date: .abbreviated, time: .omitted))"
    }

    private static func describe(_ result: KeyBackupImportResult) -> String {
        let sudoKeys = result.sudoKeyCount == 1 ? "1 Sudo key" : "\(result.sudoKeyCount) Sudo keys"
        var message = result.importedPhoneNumberKeys ? "Imported \(sudoKeys) and the phone number keys." : "Imported \(sudoKeys)."
        if !result.unrecognisedSDKs.isEmpty {
            message += " This backup also contains keys this app doesn't use (\(result.unrecognisedSDKs.joined(separator: ", "))), which were skipped."
        }
        return message
    }

    /// Removes any backup files left in the temporary directory, including ones from an export the app quit during.
    private static func removeTemporaryBackups() {
        let directory = FileManager.default.temporaryDirectory
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.lastPathComponent.hasPrefix("sudo-keys-") && file.pathExtension == "json" {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private static func exportFileName() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "sudo-keys-\(formatter.string(from: Date())).json"
    }

    private func presentError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}
