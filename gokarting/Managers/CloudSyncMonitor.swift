//
//  CloudSyncMonitor.swift
//  gokarting
//
//  Created by Andres on 2/11/2026.
//

import SwiftUI
import CoreData
import CloudKit
import Combine

enum SyncState {
    case synced
    case syncing
    case error
    case notAvailable
}

@MainActor
final class CloudSyncMonitor: ObservableObject {
    @Published var syncState: SyncState = .syncing

    private var cancellable: AnyCancellable?

    init() {
        // Listen for CloudKit sync events from the underlying Core Data stack
        cancellable = NotificationCenter.default
            .publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleEvent(notification)
            }

        // Check iCloud account availability on launch
        Task {
            await checkAccountStatus()
        }
    }

    private func handleEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else { return }

        if event.endDate == nil {
            // Event is still in progress
            syncState = .syncing
        } else if event.succeeded {
            syncState = .synced
        } else {
            syncState = .error
        }
    }

    private func checkAccountStatus() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            if status != .available {
                syncState = .notAvailable
            }
        } catch {
            syncState = .notAvailable
        }
    }
}
