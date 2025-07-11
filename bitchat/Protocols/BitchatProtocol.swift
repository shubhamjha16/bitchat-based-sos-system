//
// BitchatProtocol.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import CryptoKit

// Privacy-preserving padding utilities
struct MessagePadding {
    // Standard block sizes for padding
    static let blockSizes = [256, 512, 1024, 2048]
    
    // Add PKCS#7-style padding to reach target size
    static func pad(_ data: Data, toSize targetSize: Int) -> Data {
        guard data.count < targetSize else { return data }
        
        let paddingNeeded = targetSize - data.count
        
        // PKCS#7 only supports padding up to 255 bytes
        // If we need more padding than that, don't pad - return original data
        guard paddingNeeded <= 255 else { return data }
        
        var padded = data
        
        // Standard PKCS#7 padding
        var randomBytes = [UInt8](repeating: 0, count: paddingNeeded - 1)
        _ = SecRandomCopyBytes(kSecRandomDefault, paddingNeeded - 1, &randomBytes)
        padded.append(contentsOf: randomBytes)
        padded.append(UInt8(paddingNeeded))
        
        return padded
    }
    
    // Remove padding from data
    static func unpad(_ data: Data) -> Data {
        guard !data.isEmpty else { return data }
        
        // Last byte tells us how much padding to remove
        let paddingLength = Int(data[data.count - 1])
        guard paddingLength > 0 && paddingLength <= data.count else { return data }
        
        return data.prefix(data.count - paddingLength)
    }
    
    // Find optimal block size for data
    static func optimalBlockSize(for dataSize: Int) -> Int {
        // Account for encryption overhead (~16 bytes for AES-GCM tag)
        let totalSize = dataSize + 16
        
        // Find smallest block that fits
        for blockSize in blockSizes {
            if totalSize <= blockSize {
                return blockSize
            }
        }
        
        // For very large messages, just use the original size
        // (will be fragmented anyway)
        return dataSize
    }
}

enum MessageType: UInt8 {
    case announce = 0x01
    case keyExchange = 0x02
    case leave = 0x03
    case message = 0x04  // All user messages (private and broadcast)
    case fragmentStart = 0x05
    case fragmentContinue = 0x06
    case fragmentEnd = 0x07
    case channelAnnounce = 0x08  // Announce password-protected channel status
    case channelRetention = 0x09  // Announce channel retention status
    case deliveryAck = 0x0A  // Acknowledge message received
    case deliveryStatusRequest = 0x0B  // Request delivery status update
    case readReceipt = 0x0C  // Message has been read/viewed
    case sosMessage = 0x0D  // Emergency SOS message
    case sosResponse = 0x0E  // Response to SOS message
    case emergencyServiceAnnounce = 0x0F  // Announce emergency service availability
}

// Special recipient ID for broadcast messages
struct SpecialRecipients {
    static let broadcast = Data(repeating: 0xFF, count: 8)  // All 0xFF = broadcast
}

struct BitchatPacket: Codable {
    let version: UInt8
    let type: UInt8
    let senderID: Data
    let recipientID: Data?
    let timestamp: UInt64
    let payload: Data
    let signature: Data?
    var ttl: UInt8
    
    init(type: UInt8, senderID: Data, recipientID: Data?, timestamp: UInt64, payload: Data, signature: Data?, ttl: UInt8) {
        self.version = 1
        self.type = type
        self.senderID = senderID
        self.recipientID = recipientID
        self.timestamp = timestamp
        self.payload = payload
        self.signature = signature
        self.ttl = ttl
    }
    
    // Convenience initializer for new binary format
    init(type: UInt8, ttl: UInt8, senderID: String, payload: Data) {
        self.version = 1
        self.type = type
        self.senderID = senderID.data(using: .utf8)!
        self.recipientID = nil
        self.timestamp = UInt64(Date().timeIntervalSince1970 * 1000) // milliseconds
        self.payload = payload
        self.signature = nil
        self.ttl = ttl
    }
    
    var data: Data? {
        BinaryProtocol.encode(self)
    }
    
    func toBinaryData() -> Data? {
        BinaryProtocol.encode(self)
    }
    
    static func from(_ data: Data) -> BitchatPacket? {
        BinaryProtocol.decode(data)
    }
}

// Delivery acknowledgment structure
struct DeliveryAck: Codable {
    let originalMessageID: String
    let ackID: String
    let recipientID: String  // Who received it
    let recipientNickname: String
    let timestamp: Date
    let hopCount: UInt8  // How many hops to reach recipient
    
    init(originalMessageID: String, recipientID: String, recipientNickname: String, hopCount: UInt8) {
        self.originalMessageID = originalMessageID
        self.ackID = UUID().uuidString
        self.recipientID = recipientID
        self.recipientNickname = recipientNickname
        self.timestamp = Date()
        self.hopCount = hopCount
    }
    
    func encode() -> Data? {
        try? JSONEncoder().encode(self)
    }
    
    static func decode(from data: Data) -> DeliveryAck? {
        try? JSONDecoder().decode(DeliveryAck.self, from: data)
    }
}

// Read receipt structure
struct ReadReceipt: Codable {
    let originalMessageID: String
    let receiptID: String
    let readerID: String  // Who read it
    let readerNickname: String
    let timestamp: Date
    
    init(originalMessageID: String, readerID: String, readerNickname: String) {
        self.originalMessageID = originalMessageID
        self.receiptID = UUID().uuidString
        self.readerID = readerID
        self.readerNickname = readerNickname
        self.timestamp = Date()
    }
    
    func encode() -> Data? {
        try? JSONEncoder().encode(self)
    }
    
    static func decode(from data: Data) -> ReadReceipt? {
        try? JSONDecoder().decode(ReadReceipt.self, from: data)
    }
}

// Delivery status for messages
enum DeliveryStatus: Codable, Equatable {
    case sending
    case sent  // Left our device
    case delivered(to: String, at: Date)  // Confirmed by recipient
    case read(by: String, at: Date)  // Seen by recipient
    case failed(reason: String)
    case partiallyDelivered(reached: Int, total: Int)  // For rooms
    
    var displayText: String {
        switch self {
        case .sending:
            return "Sending..."
        case .sent:
            return "Sent"
        case .delivered(let nickname, _):
            return "Delivered to \(nickname)"
        case .read(let nickname, _):
            return "Read by \(nickname)"
        case .failed(let reason):
            return "Failed: \(reason)"
        case .partiallyDelivered(let reached, let total):
            return "Delivered to \(reached)/\(total)"
        }
    }
}

// SOS message types
enum SOSType: String, Codable, CaseIterable {
    case medical = "medical"
    case fire = "fire"
    case police = "police"
    case accident = "accident"
    case natural_disaster = "natural_disaster"
    case personal_safety = "personal_safety"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .medical:
            return "Medical Emergency"
        case .fire:
            return "Fire Emergency"
        case .police:
            return "Police Emergency"
        case .accident:
            return "Accident"
        case .natural_disaster:
            return "Natural Disaster"
        case .personal_safety:
            return "Personal Safety"
        case .other:
            return "Other Emergency"
        }
    }
    
    var emoji: String {
        switch self {
        case .medical:
            return "🚑"
        case .fire:
            return "🚒"
        case .police:
            return "🚓"
        case .accident:
            return "🚨"
        case .natural_disaster:
            return "🌪️"
        case .personal_safety:
            return "🆘"
        case .other:
            return "⚠️"
        }
    }
}

// SOS message structure
struct SOSMessage: Codable, Equatable {
    let id: String
    let type: SOSType
    let urgency: UrgencyLevel
    let location: LocationData?
    let description: String
    let senderName: String
    let senderID: String
    let timestamp: Date
    let isActive: Bool // Whether the emergency is still active
    let contactInfo: String? // Optional contact information
    let additionalInfo: [String: String]? // Additional emergency-specific info
    
    init(
        id: String? = nil,
        type: SOSType,
        urgency: UrgencyLevel,
        location: LocationData? = nil,
        description: String,
        senderName: String,
        senderID: String,
        isActive: Bool = true,
        contactInfo: String? = nil,
        additionalInfo: [String: String]? = nil
    ) {
        self.id = id ?? UUID().uuidString
        self.type = type
        self.urgency = urgency
        self.location = location
        self.description = description
        self.senderName = senderName
        self.senderID = senderID
        self.timestamp = Date()
        self.isActive = isActive
        self.contactInfo = contactInfo
        self.additionalInfo = additionalInfo
    }
}

// Urgency levels for SOS messages
enum UrgencyLevel: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        case .critical:
            return "Critical"
        }
    }
    
    var color: String {
        switch self {
        case .low:
            return "yellow"
        case .medium:
            return "orange"
        case .high:
            return "red"
        case .critical:
            return "darkred"
        }
    }
}

// Location data for SOS messages
struct LocationData: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let accuracy: Double?
    let timestamp: Date
    let address: String? // Human-readable address if available
    let landmark: String? // Nearby landmark description
    
    init(
        latitude: Double,
        longitude: Double,
        altitude: Double? = nil,
        accuracy: Double? = nil,
        address: String? = nil,
        landmark: String? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.accuracy = accuracy
        self.timestamp = Date()
        self.address = address
        self.landmark = landmark
    }
}

// SOS Response message
struct SOSResponse: Codable, Equatable {
    let id: String
    let originalSOSID: String
    let responderName: String
    let responderID: String
    let responseType: ResponseType
    let message: String
    let timestamp: Date
    let eta: Date? // Estimated time of arrival
    let capabilities: [String]? // What the responder can help with
    
    init(
        id: String? = nil,
        originalSOSID: String,
        responderName: String,
        responderID: String,
        responseType: ResponseType,
        message: String,
        eta: Date? = nil,
        capabilities: [String]? = nil
    ) {
        self.id = id ?? UUID().uuidString
        self.originalSOSID = originalSOSID
        self.responderName = responderName
        self.responderID = responderID
        self.responseType = responseType
        self.message = message
        self.timestamp = Date()
        self.eta = eta
        self.capabilities = capabilities
    }
}

// Response types
enum ResponseType: String, Codable, CaseIterable {
    case acknowledged = "acknowledged"
    case enroute = "enroute"
    case onsite = "onsite"
    case referral = "referral"
    case unable = "unable"
    
    var displayName: String {
        switch self {
        case .acknowledged:
            return "Acknowledged"
        case .enroute:
            return "En Route"
        case .onsite:
            return "On Site"
        case .referral:
            return "Referring to Others"
        case .unable:
            return "Unable to Help"
        }
    }
    
    var emoji: String {
        switch self {
        case .acknowledged:
            return "👍"
        case .enroute:
            return "🚗"
        case .onsite:
            return "📍"
        case .referral:
            return "🔄"
        case .unable:
            return "❌"
        }
    }
}

// Emergency service announcement
struct EmergencyServiceAnnouncement: Codable, Equatable {
    let id: String
    let serviceType: SOSType
    let serviceName: String
    let serviceID: String
    let location: LocationData?
    let capabilities: [String]
    let isActive: Bool
    let timestamp: Date
    let contactInfo: String?
    
    init(
        id: String? = nil,
        serviceType: SOSType,
        serviceName: String,
        serviceID: String,
        location: LocationData? = nil,
        capabilities: [String] = [],
        isActive: Bool = true,
        contactInfo: String? = nil
    ) {
        self.id = id ?? UUID().uuidString
        self.serviceType = serviceType
        self.serviceName = serviceName
        self.serviceID = serviceID
        self.location = location
        self.capabilities = capabilities
        self.isActive = isActive
        self.timestamp = Date()
        self.contactInfo = contactInfo
    }
}

struct BitchatMessage: Codable, Equatable {
    let id: String
    let sender: String
    let content: String
    let timestamp: Date
    let isRelay: Bool
    let originalSender: String?
    let isPrivate: Bool
    let recipientNickname: String?
    let senderPeerID: String?
    let mentions: [String]?  // Array of mentioned nicknames
    let channel: String?  // Channel hashtag (e.g., "#general")
    let encryptedContent: Data?  // For password-protected rooms
    let isEncrypted: Bool  // Flag to indicate if content is encrypted
    var deliveryStatus: DeliveryStatus? // Delivery tracking
    
    // SOS-specific fields
    let sosMessage: SOSMessage?
    let sosResponse: SOSResponse?
    let emergencyServiceAnnouncement: EmergencyServiceAnnouncement?
    let isEmergency: Bool
    
    init(
        id: String? = nil,
        sender: String,
        content: String,
        timestamp: Date,
        isRelay: Bool,
        originalSender: String? = nil,
        isPrivate: Bool = false,
        recipientNickname: String? = nil,
        senderPeerID: String? = nil,
        mentions: [String]? = nil,
        channel: String? = nil,
        encryptedContent: Data? = nil,
        isEncrypted: Bool = false,
        deliveryStatus: DeliveryStatus? = nil,
        sosMessage: SOSMessage? = nil,
        sosResponse: SOSResponse? = nil,
        emergencyServiceAnnouncement: EmergencyServiceAnnouncement? = nil
    ) {
        self.id = id ?? UUID().uuidString
        self.sender = sender
        self.content = content
        self.timestamp = timestamp
        self.isRelay = isRelay
        self.originalSender = originalSender
        self.isPrivate = isPrivate
        self.recipientNickname = recipientNickname
        self.senderPeerID = senderPeerID
        self.mentions = mentions
        self.channel = channel
        self.encryptedContent = encryptedContent
        self.isEncrypted = isEncrypted
        self.deliveryStatus = deliveryStatus ?? (isPrivate ? .sending : nil)
        self.sosMessage = sosMessage
        self.sosResponse = sosResponse
        self.emergencyServiceAnnouncement = emergencyServiceAnnouncement
        self.isEmergency = sosMessage != nil || sosResponse != nil || emergencyServiceAnnouncement != nil
    }
    
    // Convenience initializer for SOS messages
    init(sosMessage: SOSMessage, sender: String, senderPeerID: String?) {
        self.init(
            sender: sender,
            content: "🆘 \(sosMessage.type.emoji) \(sosMessage.type.displayName): \(sosMessage.description)",
            timestamp: sosMessage.timestamp,
            isRelay: false,
            senderPeerID: senderPeerID,
            sosMessage: sosMessage
        )
    }
    
    // Convenience initializer for SOS responses
    init(sosResponse: SOSResponse, sender: String, senderPeerID: String?) {
        self.init(
            sender: sender,
            content: "🚨 Response: \(sosResponse.responseType.emoji) \(sosResponse.responseType.displayName) - \(sosResponse.message)",
            timestamp: sosResponse.timestamp,
            isRelay: false,
            senderPeerID: senderPeerID,
            sosResponse: sosResponse
        )
    }
    
    // Convenience initializer for emergency service announcements
    init(emergencyServiceAnnouncement: EmergencyServiceAnnouncement, sender: String, senderPeerID: String?) {
        self.init(
            sender: sender,
            content: "🚑 Emergency Service: \(emergencyServiceAnnouncement.serviceName) - \(emergencyServiceAnnouncement.serviceType.displayName)",
            timestamp: emergencyServiceAnnouncement.timestamp,
            isRelay: false,
            senderPeerID: senderPeerID,
            emergencyServiceAnnouncement: emergencyServiceAnnouncement
        )
    }
}

protocol BitchatDelegate: AnyObject {
    func didReceiveMessage(_ message: BitchatMessage)
    func didConnectToPeer(_ peerID: String)
    func didDisconnectFromPeer(_ peerID: String)
    func didUpdatePeerList(_ peers: [String])
    func didReceiveChannelLeave(_ channel: String, from peerID: String)
    func didReceivePasswordProtectedChannelAnnouncement(_ channel: String, isProtected: Bool, creatorID: String?, keyCommitment: String?)
    func didReceiveChannelRetentionAnnouncement(_ channel: String, enabled: Bool, creatorID: String?)
    func decryptChannelMessage(_ encryptedContent: Data, channel: String) -> String?
    
    // Optional method to check if a fingerprint belongs to a favorite peer
    func isFavorite(fingerprint: String) -> Bool
    
    // Delivery confirmation methods
    func didReceiveDeliveryAck(_ ack: DeliveryAck)
    func didReceiveReadReceipt(_ receipt: ReadReceipt)
    func didUpdateMessageDeliveryStatus(_ messageID: String, status: DeliveryStatus)
    
    // SOS-specific methods
    func didReceiveSOSMessage(_ sosMessage: SOSMessage)
    func didReceiveSOSResponse(_ sosResponse: SOSResponse)
    func didReceiveEmergencyServiceAnnouncement(_ announcement: EmergencyServiceAnnouncement)
}

// Provide default implementation to make it effectively optional
extension BitchatDelegate {
    func isFavorite(fingerprint: String) -> Bool {
        return false
    }
    
    func didReceiveChannelLeave(_ channel: String, from peerID: String) {
        // Default empty implementation
    }
    
    func didReceivePasswordProtectedChannelAnnouncement(_ channel: String, isProtected: Bool, creatorID: String?, keyCommitment: String?) {
        // Default empty implementation
    }
    
    func didReceiveChannelRetentionAnnouncement(_ channel: String, enabled: Bool, creatorID: String?) {
        // Default empty implementation
    }
    
    func decryptChannelMessage(_ encryptedContent: Data, channel: String) -> String? {
        // Default returns nil (unable to decrypt)
        return nil
    }
    
    func didReceiveDeliveryAck(_ ack: DeliveryAck) {
        // Default empty implementation
    }
    
    func didReceiveReadReceipt(_ receipt: ReadReceipt) {
        // Default empty implementation
    }
    
    func didUpdateMessageDeliveryStatus(_ messageID: String, status: DeliveryStatus) {
        // Default empty implementation
    }
    
    // Default implementations for SOS methods
    func didReceiveSOSMessage(_ sosMessage: SOSMessage) {
        // Default empty implementation
    }
    
    func didReceiveSOSResponse(_ sosResponse: SOSResponse) {
        // Default empty implementation
    }
    
    func didReceiveEmergencyServiceAnnouncement(_ announcement: EmergencyServiceAnnouncement) {
        // Default empty implementation
    }
}