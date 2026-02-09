import Foundation
import WatchConnectivity
import SwiftData
import os

@Observable
class ConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = ConnectivityManager()
    
    var isReachable = false
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
            return
        }
        print("WCSession activated: \(activationState.rawValue)")
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate() // Reactivate if needed
    }
    #endif
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    // MARK: - Data Transfer
    
    // Struct for transfer
    struct SessionTransfer: Codable {
        let id: UUID
        let date: Date
        let laps: [LapTransfer]
        
        struct LapTransfer: Codable {
            let lapNumber: Int
            let duration: TimeInterval
            let timestamp: Date
        }
    }
    
    func sendSession(_ session: Session) {
        guard WCSession.default.activationState == .activated else { return }
        
        let lapTransfers = session.laps.map {
            SessionTransfer.LapTransfer(lapNumber: $0.lapNumber, duration: $0.duration, timestamp: $0.timestamp)
        }
        let transferObject = SessionTransfer(id: session.id, date: session.date, laps: lapTransfers)
        
        do {
            let data = try JSONEncoder().encode(transferObject)
            // Use transferUserInfo for reliable background transfer
            WCSession.default.transferUserInfo(["sessionData": data])
            print("Sent session via transferUserInfo")
        } catch {
            print("Failed to encode session: \(error)")
        }
    }
    
    // Receive Data
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        guard let data = userInfo["sessionData"] as? Data else { return }
        
        Task {
            await handleReceivedSessionData(data)
        }
    }
    
    @MainActor
    private func handleReceivedSessionData(_ data: Data) {
        do {
            let transferObject = try JSONDecoder().decode(SessionTransfer.self, from: data)
            // Save to SwiftData
            // Note: We need a ModelContext here. 
            // In a real app, inject the ModelContainer or use a shared actor.
            // For this snippet, I'll assume we can access the container via the App or pass it in.
            // This is a bit tricky in a singleton without context injection.
            // I'll emit a notification or use a callback.
            
            print("Received session with \(transferObject.laps.count) laps")
            
            // Post notification for the App to handle saving
            NotificationCenter.default.post(name: .didReceiveWatchSession, object: nil, userInfo: ["data": transferObject])
            
        } catch {
            print("Failed to decode session: \(error)")
        }
    }
}

extension Notification.Name {
    static let didReceiveWatchSession = Notification.Name("didReceiveWatchSession")
}
