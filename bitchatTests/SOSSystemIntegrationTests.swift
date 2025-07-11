//
// SOSSystemIntegrationTests.swift
// bitchatTests
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import XCTest
@testable import bitchat

class SOSSystemIntegrationTests: XCTestCase {
    
    var chatViewModel: ChatViewModel!
    var sosService: SOSService!
    var locationService: LocationService!
    
    override func setUp() {
        super.setUp()
        chatViewModel = ChatViewModel()
        sosService = SOSService.shared
        locationService = LocationService.shared
    }
    
    override func tearDown() {
        chatViewModel = nil
        sosService = nil
        locationService = nil
        super.tearDown()
    }
    
    func testSOSServiceInitialization() {
        XCTAssertNotNil(sosService)
        XCTAssertTrue(sosService.activeSOSMessages.isEmpty)
        XCTAssertTrue(sosService.sosResponses.isEmpty)
        XCTAssertTrue(sosService.emergencyServices.isEmpty)
        XCTAssertFalse(sosService.isEmergencyServiceProvider)
    }
    
    func testLocationServiceInitialization() {
        XCTAssertNotNil(locationService)
        XCTAssertEqual(locationService.locationPermissionStatus, .notDetermined)
        XCTAssertFalse(locationService.isLocationEnabled)
    }
    
    func testChatViewModelSOSProperties() {
        XCTAssertNotNil(chatViewModel)
        XCTAssertTrue(chatViewModel.sosMessages.isEmpty)
        XCTAssertTrue(chatViewModel.sosResponses.isEmpty)
        XCTAssertTrue(chatViewModel.emergencyServices.isEmpty)
        XCTAssertFalse(chatViewModel.showSOSInterface)
        XCTAssertFalse(chatViewModel.isEmergencyServiceProvider)
        XCTAssertTrue(chatViewModel.activeSOSAlerts.isEmpty)
    }
    
    func testSOSMessageTypesComplete() {
        // Ensure all SOS types are properly defined
        let allTypes = SOSType.allCases
        XCTAssertTrue(allTypes.contains(.medical))
        XCTAssertTrue(allTypes.contains(.fire))
        XCTAssertTrue(allTypes.contains(.police))
        XCTAssertTrue(allTypes.contains(.accident))
        XCTAssertTrue(allTypes.contains(.natural_disaster))
        XCTAssertTrue(allTypes.contains(.personal_safety))
        XCTAssertTrue(allTypes.contains(.other))
        
        // Test that all have proper display values
        for type in allTypes {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertFalse(type.emoji.isEmpty)
            XCTAssertFalse(type.rawValue.isEmpty)
        }
    }
    
    func testUrgencyLevelsComplete() {
        let allLevels = UrgencyLevel.allCases
        XCTAssertTrue(allLevels.contains(.low))
        XCTAssertTrue(allLevels.contains(.medium))
        XCTAssertTrue(allLevels.contains(.high))
        XCTAssertTrue(allLevels.contains(.critical))
        
        // Test that all have proper display values
        for level in allLevels {
            XCTAssertFalse(level.displayName.isEmpty)
            XCTAssertFalse(level.color.isEmpty)
            XCTAssertFalse(level.rawValue.isEmpty)
        }
    }
    
    func testResponseTypesComplete() {
        let allTypes = ResponseType.allCases
        XCTAssertTrue(allTypes.contains(.acknowledged))
        XCTAssertTrue(allTypes.contains(.enroute))
        XCTAssertTrue(allTypes.contains(.onsite))
        XCTAssertTrue(allTypes.contains(.referral))
        XCTAssertTrue(allTypes.contains(.unable))
        
        // Test that all have proper display values
        for type in allTypes {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertFalse(type.emoji.isEmpty)
            XCTAssertFalse(type.rawValue.isEmpty)
        }
    }
    
    func testLocationDataFormatting() {
        let location = LocationData(
            latitude: 40.7128,
            longitude: -74.0060,
            address: "New York, NY"
        )
        
        let formatted = locationService.formatLocation(location)
        XCTAssertEqual(formatted, "New York, NY")
        
        let locationWithoutAddress = LocationData(
            latitude: 40.7128,
            longitude: -74.0060
        )
        
        let formattedWithoutAddress = locationService.formatLocation(locationWithoutAddress)
        XCTAssertTrue(formattedWithoutAddress.contains("40.712800"))
        XCTAssertTrue(formattedWithoutAddress.contains("-74.006000"))
    }
    
    func testDistanceCalculation() {
        let location1 = LocationData(latitude: 40.7128, longitude: -74.0060)
        let location2 = LocationData(latitude: 40.7589, longitude: -73.9851)
        
        let distance = locationService.distance(from: location1, to: location2)
        XCTAssertGreaterThan(distance, 0)
        XCTAssertLessThan(distance, 10000) // Should be less than 10km
        
        let formattedDistance = locationService.formatDistance(distance)
        XCTAssertTrue(formattedDistance.contains("km") || formattedDistance.contains("m"))
    }
    
    func testSOSMessageFormatting() {
        let sosMessage = SOSMessage(
            type: .medical,
            urgency: .critical,
            location: LocationData(latitude: 40.7128, longitude: -74.0060),
            description: "Heart attack emergency",
            senderName: "John Doe",
            senderID: "user123",
            contactInfo: "555-1234"
        )
        
        let formatted = chatViewModel.formatSOSMessage(sosMessage)
        XCTAssertTrue(formatted.contains("🚑"))
        XCTAssertTrue(formatted.contains("Medical Emergency"))
        XCTAssertTrue(formatted.contains("Critical"))
        XCTAssertTrue(formatted.contains("Heart attack emergency"))
        XCTAssertTrue(formatted.contains("John Doe"))
        XCTAssertTrue(formatted.contains("555-1234"))
        XCTAssertTrue(formatted.contains("40.712800"))
        XCTAssertTrue(formatted.contains("-74.006000"))
    }
    
    func testSOSResponseFormatting() {
        let sosResponse = SOSResponse(
            originalSOSID: "sos123",
            responderName: "Dr. Smith",
            responderID: "medic456",
            responseType: .enroute,
            message: "On my way, ETA 5 minutes",
            eta: Date().addingTimeInterval(300),
            capabilities: ["Medical", "CPR"]
        )
        
        let formatted = chatViewModel.formatSOSResponse(sosResponse)
        XCTAssertTrue(formatted.contains("🚗"))
        XCTAssertTrue(formatted.contains("En Route"))
        XCTAssertTrue(formatted.contains("On my way, ETA 5 minutes"))
        XCTAssertTrue(formatted.contains("Dr. Smith"))
        XCTAssertTrue(formatted.contains("ETA:"))
        XCTAssertTrue(formatted.contains("Medical, CPR"))
    }
    
    func testSOSPriorityHandling() {
        let criticalSOS = SOSMessage(
            type: .medical,
            urgency: .critical,
            description: "Critical emergency",
            senderName: "User",
            senderID: "user1"
        )
        
        let lowSOS = SOSMessage(
            type: .other,
            urgency: .low,
            description: "Low priority",
            senderName: "User",
            senderID: "user2"
        )
        
        let criticalPriority = chatViewModel.getSOSMessagePriority(criticalSOS)
        let lowPriority = chatViewModel.getSOSMessagePriority(lowSOS)
        
        XCTAssertGreaterThan(criticalPriority, lowPriority)
        XCTAssertEqual(criticalPriority, 1000)
        XCTAssertEqual(lowPriority, 400)
    }
    
    func testSOSServiceStatistics() {
        let stats = sosService.getSOSStatistics()
        
        XCTAssertNotNil(stats["totalActiveSOSMessages"])
        XCTAssertNotNil(stats["totalSOSMessages"])
        XCTAssertNotNil(stats["totalResponses"])
        XCTAssertNotNil(stats["totalEmergencyServices"])
        XCTAssertNotNil(stats["criticalMessages"])
        XCTAssertNotNil(stats["recentMessages"])
        XCTAssertNotNil(stats["isEmergencyServiceProvider"])
        XCTAssertNotNil(stats["myEmergencyServices"])
        
        // Should be zero for a fresh service
        XCTAssertEqual(stats["totalActiveSOSMessages"] as? Int, 0)
        XCTAssertEqual(stats["totalSOSMessages"] as? Int, 0)
        XCTAssertEqual(stats["totalResponses"] as? Int, 0)
        XCTAssertEqual(stats["totalEmergencyServices"] as? Int, 0)
        XCTAssertEqual(stats["isEmergencyServiceProvider"] as? Bool, false)
        XCTAssertEqual(stats["myEmergencyServices"] as? Int, 0)
    }
    
    func testMessageTypeHandling() {
        // Test that MessageType enum includes all SOS types
        XCTAssertNotNil(MessageType.sosMessage)
        XCTAssertNotNil(MessageType.sosResponse)
        XCTAssertNotNil(MessageType.emergencyServiceAnnounce)
        
        // Test that values are unique
        let sosMessageValue = MessageType.sosMessage.rawValue
        let sosResponseValue = MessageType.sosResponse.rawValue
        let emergencyServiceValue = MessageType.emergencyServiceAnnounce.rawValue
        
        XCTAssertNotEqual(sosMessageValue, sosResponseValue)
        XCTAssertNotEqual(sosMessageValue, emergencyServiceValue)
        XCTAssertNotEqual(sosResponseValue, emergencyServiceValue)
    }
    
    func testBitchatMessageEmergencyFlag() {
        // Test regular message
        let regularMessage = BitchatMessage(
            sender: "User",
            content: "Hello",
            timestamp: Date(),
            isRelay: false
        )
        XCTAssertFalse(regularMessage.isEmergency)
        
        // Test SOS message
        let sosMessage = SOSMessage(
            type: .medical,
            urgency: .high,
            description: "Emergency",
            senderName: "User",
            senderID: "user1"
        )
        let sosMessageBitchat = BitchatMessage(
            sosMessage: sosMessage,
            sender: "User",
            senderPeerID: "user1"
        )
        XCTAssertTrue(sosMessageBitchat.isEmergency)
        
        // Test SOS response
        let sosResponse = SOSResponse(
            originalSOSID: "sos123",
            responderName: "Responder",
            responderID: "resp1",
            responseType: .acknowledged,
            message: "Got it"
        )
        let sosResponseBitchat = BitchatMessage(
            sosResponse: sosResponse,
            sender: "Responder",
            senderPeerID: "resp1"
        )
        XCTAssertTrue(sosResponseBitchat.isEmergency)
        
        // Test emergency service announcement
        let serviceAnnouncement = EmergencyServiceAnnouncement(
            serviceType: .medical,
            serviceName: "Hospital",
            serviceID: "hosp1"
        )
        let serviceMessageBitchat = BitchatMessage(
            emergencyServiceAnnouncement: serviceAnnouncement,
            sender: "Hospital",
            senderPeerID: "hosp1"
        )
        XCTAssertTrue(serviceMessageBitchat.isEmergency)
    }
}