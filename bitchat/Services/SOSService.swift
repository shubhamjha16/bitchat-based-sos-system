//
// SOSService.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import Combine

class SOSService: ObservableObject {
    static let shared = SOSService()
    
    @Published var activeSOSMessages: [SOSMessage] = []
    @Published var sosResponses: [SOSResponse] = []
    @Published var emergencyServices: [EmergencyServiceAnnouncement] = []
    @Published var isEmergencyServiceProvider = false
    @Published var myEmergencyServices: [EmergencyServiceAnnouncement] = []
    
    private let locationService = LocationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Emergency service configuration
    @Published var emergencyServiceTypes: [SOSType] = []
    @Published var emergencyCapabilities: [String] = []
    @Published var emergencyServiceName: String = ""
    @Published var emergencyContactInfo: String = ""
    
    init() {
        // Clean up old SOS messages periodically
        setupCleanupTimer()
    }
    
    // MARK: - SOS Message Management
    
    func createSOSMessage(
        type: SOSType,
        urgency: UrgencyLevel,
        description: String,
        senderName: String,
        senderID: String,
        includeLocation: Bool = true,
        contactInfo: String? = nil,
        additionalInfo: [String: String]? = nil
    ) async -> SOSMessage {
        
        var location: LocationData?
        if includeLocation {
            location = await locationService.getCurrentLocation()
            if let locationData = location {
                // Geocode for better address information
                location = await locationService.geocodeLocation(locationData)
            }
        }
        
        let sosMessage = SOSMessage(
            type: type,
            urgency: urgency,
            location: location,
            description: description,
            senderName: senderName,
            senderID: senderID,
            contactInfo: contactInfo,
            additionalInfo: additionalInfo
        )
        
        // Add to active SOS messages
        DispatchQueue.main.async {
            self.activeSOSMessages.append(sosMessage)
        }
        
        return sosMessage
    }
    
    func receiveSOSMessage(_ sosMessage: SOSMessage) {
        DispatchQueue.main.async {
            // Check if we already have this SOS message
            if !self.activeSOSMessages.contains(where: { $0.id == sosMessage.id }) {
                self.activeSOSMessages.append(sosMessage)
            }
        }
    }
    
    func deactivateSOSMessage(_ sosID: String) {
        DispatchQueue.main.async {
            if let index = self.activeSOSMessages.firstIndex(where: { $0.id == sosID }) {
                var updatedSOS = self.activeSOSMessages[index]
                // Create a new SOS message with updated isActive status
                let deactivatedSOS = SOSMessage(
                    id: updatedSOS.id,
                    type: updatedSOS.type,
                    urgency: updatedSOS.urgency,
                    location: updatedSOS.location,
                    description: updatedSOS.description,
                    senderName: updatedSOS.senderName,
                    senderID: updatedSOS.senderID,
                    isActive: false,
                    contactInfo: updatedSOS.contactInfo,
                    additionalInfo: updatedSOS.additionalInfo
                )
                self.activeSOSMessages[index] = deactivatedSOS
            }
        }
    }
    
    // MARK: - SOS Response Management
    
    func createSOSResponse(
        originalSOSID: String,
        responderName: String,
        responderID: String,
        responseType: ResponseType,
        message: String,
        eta: Date? = nil,
        capabilities: [String]? = nil
    ) -> SOSResponse {
        
        let sosResponse = SOSResponse(
            originalSOSID: originalSOSID,
            responderName: responderName,
            responderID: responderID,
            responseType: responseType,
            message: message,
            eta: eta,
            capabilities: capabilities
        )
        
        DispatchQueue.main.async {
            self.sosResponses.append(sosResponse)
        }
        
        return sosResponse
    }
    
    func receiveSOSResponse(_ sosResponse: SOSResponse) {
        DispatchQueue.main.async {
            // Check if we already have this response
            if !self.sosResponses.contains(where: { $0.id == sosResponse.id }) {
                self.sosResponses.append(sosResponse)
            }
        }
    }
    
    func getResponsesForSOS(_ sosID: String) -> [SOSResponse] {
        return sosResponses.filter { $0.originalSOSID == sosID }
    }
    
    // MARK: - Emergency Service Management
    
    func enableEmergencyService(
        serviceType: SOSType,
        serviceName: String,
        serviceID: String,
        capabilities: [String] = [],
        contactInfo: String? = nil
    ) async {
        
        var location: LocationData?
        location = await locationService.getCurrentLocation()
        if let locationData = location {
            location = await locationService.geocodeLocation(locationData)
        }
        
        let serviceAnnouncement = EmergencyServiceAnnouncement(
            serviceType: serviceType,
            serviceName: serviceName,
            serviceID: serviceID,
            location: location,
            capabilities: capabilities,
            contactInfo: contactInfo
        )
        
        DispatchQueue.main.async {
            self.isEmergencyServiceProvider = true
            self.myEmergencyServices.append(serviceAnnouncement)
        }
    }
    
    func disableEmergencyService(_ serviceID: String) {
        DispatchQueue.main.async {
            self.myEmergencyServices.removeAll { $0.serviceID == serviceID }
            if self.myEmergencyServices.isEmpty {
                self.isEmergencyServiceProvider = false
            }
        }
    }
    
    func receiveEmergencyServiceAnnouncement(_ announcement: EmergencyServiceAnnouncement) {
        DispatchQueue.main.async {
            // Update existing announcement or add new one
            if let index = self.emergencyServices.firstIndex(where: { $0.serviceID == announcement.serviceID }) {
                self.emergencyServices[index] = announcement
            } else {
                self.emergencyServices.append(announcement)
            }
        }
    }
    
    func getEmergencyServicesForType(_ type: SOSType) -> [EmergencyServiceAnnouncement] {
        return emergencyServices.filter { $0.serviceType == type && $0.isActive }
    }
    
    func getNearbyEmergencyServices(_ location: LocationData, radius: Double = 5000) -> [EmergencyServiceAnnouncement] {
        return emergencyServices.filter { service in
            guard let serviceLocation = service.location else { return false }
            let distance = locationService.distance(from: location, to: serviceLocation)
            return distance <= radius && service.isActive
        }
    }
    
    // MARK: - Utility Methods
    
    func getSOSMessage(by id: String) -> SOSMessage? {
        return activeSOSMessages.first { $0.id == id }
    }
    
    func getActiveSOSMessages() -> [SOSMessage] {
        return activeSOSMessages.filter { $0.isActive }
    }
    
    func getSOSMessagesByUrgency(_ urgency: UrgencyLevel) -> [SOSMessage] {
        return activeSOSMessages.filter { $0.urgency == urgency && $0.isActive }
    }
    
    func getCriticalSOSMessages() -> [SOSMessage] {
        return getSOSMessagesByUrgency(.critical)
    }
    
    func getRecentSOSMessages(within timeInterval: TimeInterval = 3600) -> [SOSMessage] {
        let cutoffTime = Date().addingTimeInterval(-timeInterval)
        return activeSOSMessages.filter { $0.timestamp > cutoffTime }
    }
    
    // MARK: - Priority and Routing
    
    func getSOSMessagePriority(_ sosMessage: SOSMessage) -> Int {
        // Higher number = higher priority
        switch sosMessage.urgency {
        case .critical:
            return 1000
        case .high:
            return 800
        case .medium:
            return 600
        case .low:
            return 400
        }
    }
    
    func shouldPrioritizeMessage(_ sosMessage: SOSMessage) -> Bool {
        return sosMessage.urgency == .critical || sosMessage.urgency == .high
    }
    
    func getMaxTTLForUrgency(_ urgency: UrgencyLevel) -> UInt8 {
        // Critical messages should travel farther
        switch urgency {
        case .critical:
            return 10
        case .high:
            return 8
        case .medium:
            return 6
        case .low:
            return 4
        }
    }
    
    // MARK: - Cleanup
    
    private func setupCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            self.cleanupOldMessages()
        }
    }
    
    private func cleanupOldMessages() {
        let cutoffTime = Date().addingTimeInterval(-24 * 60 * 60) // 24 hours ago
        
        DispatchQueue.main.async {
            // Remove old SOS messages
            self.activeSOSMessages.removeAll { $0.timestamp < cutoffTime && !$0.isActive }
            
            // Remove old responses
            self.sosResponses.removeAll { $0.timestamp < cutoffTime }
            
            // Remove old emergency service announcements
            self.emergencyServices.removeAll { $0.timestamp < cutoffTime && !$0.isActive }
        }
    }
    
    // MARK: - Statistics
    
    func getSOSStatistics() -> [String: Any] {
        return [
            "totalActiveSOSMessages": activeSOSMessages.filter { $0.isActive }.count,
            "totalSOSMessages": activeSOSMessages.count,
            "totalResponses": sosResponses.count,
            "totalEmergencyServices": emergencyServices.count,
            "criticalMessages": getCriticalSOSMessages().count,
            "recentMessages": getRecentSOSMessages().count,
            "isEmergencyServiceProvider": isEmergencyServiceProvider,
            "myEmergencyServices": myEmergencyServices.count
        ]
    }
}

// MARK: - Emergency Contact Management
extension SOSService {
    func addEmergencyContact(name: String, phone: String, relationship: String) {
        // This could be extended to store emergency contacts
        // For now, we'll just use the contactInfo field in SOS messages
    }
    
    func getFormattedEmergencyInfo() -> String {
        var info = ""
        if !emergencyServiceName.isEmpty {
            info += "Service: \(emergencyServiceName)\n"
        }
        if !emergencyContactInfo.isEmpty {
            info += "Contact: \(emergencyContactInfo)\n"
        }
        if !emergencyCapabilities.isEmpty {
            info += "Capabilities: \(emergencyCapabilities.joined(separator: ", "))\n"
        }
        return info
    }
}