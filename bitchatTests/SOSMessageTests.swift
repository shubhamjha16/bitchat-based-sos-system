//
// SOSMessageTests.swift
// bitchatTests
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import XCTest
@testable import bitchat

class SOSMessageTests: XCTestCase {
    
    func testSOSMessageCreation() {
        let locationData = LocationData(
            latitude: 37.7749,
            longitude: -122.4194,
            address: "San Francisco, CA"
        )
        
        let sosMessage = SOSMessage(
            type: .medical,
            urgency: .critical,
            location: locationData,
            description: "Heart attack emergency",
            senderName: "John Doe",
            senderID: "user123",
            contactInfo: "555-1234"
        )
        
        XCTAssertEqual(sosMessage.type, .medical)
        XCTAssertEqual(sosMessage.urgency, .critical)
        XCTAssertEqual(sosMessage.description, "Heart attack emergency")
        XCTAssertEqual(sosMessage.senderName, "John Doe")
        XCTAssertEqual(sosMessage.senderID, "user123")
        XCTAssertEqual(sosMessage.contactInfo, "555-1234")
        XCTAssertTrue(sosMessage.isActive)
        XCTAssertNotNil(sosMessage.location)
        XCTAssertEqual(sosMessage.location?.latitude, 37.7749)
        XCTAssertEqual(sosMessage.location?.longitude, -122.4194)
    }
    
    func testSOSMessageEncoding() {
        let sosMessage = SOSMessage(
            type: .fire,
            urgency: .high,
            location: nil,
            description: "House fire",
            senderName: "Jane Smith",
            senderID: "user456"
        )
        
        let bitchatMessage = BitchatMessage(
            sosMessage: sosMessage,
            sender: "Jane Smith",
            senderPeerID: "user456"
        )
        
        // Test encoding
        guard let encoded = bitchatMessage.toBinaryPayload() else {
            XCTFail("Failed to encode SOS message")
            return
        }
        
        // Test decoding
        guard let decoded = BitchatMessage.fromBinaryPayload(encoded) else {
            XCTFail("Failed to decode SOS message")
            return
        }
        
        XCTAssertTrue(decoded.isEmergency)
        XCTAssertNotNil(decoded.sosMessage)
        XCTAssertEqual(decoded.sosMessage?.type, .fire)
        XCTAssertEqual(decoded.sosMessage?.urgency, .high)
        XCTAssertEqual(decoded.sosMessage?.description, "House fire")
        XCTAssertEqual(decoded.sosMessage?.senderName, "Jane Smith")
        XCTAssertEqual(decoded.sosMessage?.senderID, "user456")
    }
    
    func testSOSResponseCreation() {
        let sosResponse = SOSResponse(
            originalSOSID: "sos123",
            responderName: "Dr. Brown",
            responderID: "medic789",
            responseType: .enroute,
            message: "On my way, ETA 5 minutes",
            eta: Date().addingTimeInterval(300),
            capabilities: ["Medical", "CPR"]
        )
        
        XCTAssertEqual(sosResponse.originalSOSID, "sos123")
        XCTAssertEqual(sosResponse.responderName, "Dr. Brown")
        XCTAssertEqual(sosResponse.responderID, "medic789")
        XCTAssertEqual(sosResponse.responseType, .enroute)
        XCTAssertEqual(sosResponse.message, "On my way, ETA 5 minutes")
        XCTAssertNotNil(sosResponse.eta)
        XCTAssertEqual(sosResponse.capabilities?.count, 2)
        XCTAssertTrue(sosResponse.capabilities?.contains("Medical") ?? false)
        XCTAssertTrue(sosResponse.capabilities?.contains("CPR") ?? false)
    }
    
    func testSOSResponseEncoding() {
        let sosResponse = SOSResponse(
            originalSOSID: "sos456",
            responderName: "Police Unit 1",
            responderID: "police123",
            responseType: .acknowledged,
            message: "Police unit dispatched"
        )
        
        let bitchatMessage = BitchatMessage(
            sosResponse: sosResponse,
            sender: "Police Unit 1",
            senderPeerID: "police123"
        )
        
        // Test encoding
        guard let encoded = bitchatMessage.toBinaryPayload() else {
            XCTFail("Failed to encode SOS response")
            return
        }
        
        // Test decoding
        guard let decoded = BitchatMessage.fromBinaryPayload(encoded) else {
            XCTFail("Failed to decode SOS response")
            return
        }
        
        XCTAssertTrue(decoded.isEmergency)
        XCTAssertNotNil(decoded.sosResponse)
        XCTAssertEqual(decoded.sosResponse?.originalSOSID, "sos456")
        XCTAssertEqual(decoded.sosResponse?.responderName, "Police Unit 1")
        XCTAssertEqual(decoded.sosResponse?.responderID, "police123")
        XCTAssertEqual(decoded.sosResponse?.responseType, .acknowledged)
        XCTAssertEqual(decoded.sosResponse?.message, "Police unit dispatched")
    }
    
    func testEmergencyServiceAnnouncement() {
        let announcement = EmergencyServiceAnnouncement(
            serviceType: .medical,
            serviceName: "City Hospital",
            serviceID: "hospital1",
            capabilities: ["Emergency Room", "Surgery", "Trauma Care"],
            contactInfo: "911"
        )
        
        let bitchatMessage = BitchatMessage(
            emergencyServiceAnnouncement: announcement,
            sender: "City Hospital",
            senderPeerID: "hospital1"
        )
        
        // Test encoding
        guard let encoded = bitchatMessage.toBinaryPayload() else {
            XCTFail("Failed to encode emergency service announcement")
            return
        }
        
        // Test decoding
        guard let decoded = BitchatMessage.fromBinaryPayload(encoded) else {
            XCTFail("Failed to decode emergency service announcement")
            return
        }
        
        XCTAssertTrue(decoded.isEmergency)
        XCTAssertNotNil(decoded.emergencyServiceAnnouncement)
        XCTAssertEqual(decoded.emergencyServiceAnnouncement?.serviceType, .medical)
        XCTAssertEqual(decoded.emergencyServiceAnnouncement?.serviceName, "City Hospital")
        XCTAssertEqual(decoded.emergencyServiceAnnouncement?.serviceID, "hospital1")
        XCTAssertEqual(decoded.emergencyServiceAnnouncement?.capabilities.count, 3)
        XCTAssertTrue(decoded.emergencyServiceAnnouncement?.capabilities.contains("Emergency Room") ?? false)
        XCTAssertEqual(decoded.emergencyServiceAnnouncement?.contactInfo, "911")
    }
    
    func testLocationData() {
        let location = LocationData(
            latitude: 40.7128,
            longitude: -74.0060,
            altitude: 10.0,
            accuracy: 5.0,
            address: "New York, NY",
            landmark: "Times Square"
        )
        
        XCTAssertEqual(location.latitude, 40.7128)
        XCTAssertEqual(location.longitude, -74.0060)
        XCTAssertEqual(location.altitude, 10.0)
        XCTAssertEqual(location.accuracy, 5.0)
        XCTAssertEqual(location.address, "New York, NY")
        XCTAssertEqual(location.landmark, "Times Square")
    }
    
    func testSOSTypeProperties() {
        // Test all SOS types have display names and emojis
        for sosType in SOSType.allCases {
            XCTAssertFalse(sosType.displayName.isEmpty)
            XCTAssertFalse(sosType.emoji.isEmpty)
        }
        
        // Test specific types
        XCTAssertEqual(SOSType.medical.displayName, "Medical Emergency")
        XCTAssertEqual(SOSType.medical.emoji, "🚑")
        XCTAssertEqual(SOSType.fire.displayName, "Fire Emergency")
        XCTAssertEqual(SOSType.fire.emoji, "🚒")
        XCTAssertEqual(SOSType.police.displayName, "Police Emergency")
        XCTAssertEqual(SOSType.police.emoji, "🚓")
    }
    
    func testUrgencyLevelProperties() {
        // Test all urgency levels have display names and colors
        for urgency in UrgencyLevel.allCases {
            XCTAssertFalse(urgency.displayName.isEmpty)
            XCTAssertFalse(urgency.color.isEmpty)
        }
        
        // Test specific urgency levels
        XCTAssertEqual(UrgencyLevel.critical.displayName, "Critical")
        XCTAssertEqual(UrgencyLevel.critical.color, "darkred")
        XCTAssertEqual(UrgencyLevel.high.displayName, "High")
        XCTAssertEqual(UrgencyLevel.high.color, "red")
        XCTAssertEqual(UrgencyLevel.medium.displayName, "Medium")
        XCTAssertEqual(UrgencyLevel.medium.color, "orange")
        XCTAssertEqual(UrgencyLevel.low.displayName, "Low")
        XCTAssertEqual(UrgencyLevel.low.color, "yellow")
    }
    
    func testResponseTypeProperties() {
        // Test all response types have display names and emojis
        for responseType in ResponseType.allCases {
            XCTAssertFalse(responseType.displayName.isEmpty)
            XCTAssertFalse(responseType.emoji.isEmpty)
        }
        
        // Test specific response types
        XCTAssertEqual(ResponseType.acknowledged.displayName, "Acknowledged")
        XCTAssertEqual(ResponseType.acknowledged.emoji, "👍")
        XCTAssertEqual(ResponseType.enroute.displayName, "En Route")
        XCTAssertEqual(ResponseType.enroute.emoji, "🚗")
        XCTAssertEqual(ResponseType.onsite.displayName, "On Site")
        XCTAssertEqual(ResponseType.onsite.emoji, "📍")
    }
}