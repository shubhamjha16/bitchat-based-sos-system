# BitChat-based SOS System

> [!WARNING]
> Private message and channel features have not received external security review and may contain vulnerabilities. Do not use for sensitive use cases, and do not rely on its security until it has been reviewed. Work in progress. Public local chat (the main feature) has no security concerns. 

A decentralized peer-to-peer emergency communication system that works over Bluetooth mesh networks. No internet required, no servers, no phone numbers. It's the emergency communication tool for when traditional networks fail.

## License

This project is released into the public domain. See the [LICENSE](LICENSE) file for details.

## Features

### Core Messaging Features
- **Decentralized Mesh Network**: Automatic peer discovery and multi-hop message relay over Bluetooth LE
- **End-to-End Encryption**: X25519 key exchange + AES-256-GCM for private messages and channels
- **Channel-Based Chats**: Topic-based group messaging with optional password protection
- **Store & Forward**: Messages cached for offline peers and delivered when they reconnect
- **Privacy First**: No accounts, no phone numbers, no persistent identifiers
- **IRC-Style Commands**: Familiar `/join`, `/msg`, `/who` style interface
- **Message Retention**: Optional channel-wide message saving controlled by channel owners
- **Universal App**: Native support for iOS and macOS
- **Cover Traffic**: Timing obfuscation and dummy messages for enhanced privacy
- **Emergency Wipe**: Triple-tap to instantly clear all data
- **Performance Optimizations**: LZ4 message compression, adaptive battery modes, and optimized networking

### Emergency SOS Features
- **🆘 Emergency SOS Messages**: Send emergency alerts to all nearby devices
- **📍 Location Integration**: Automatic GPS location sharing with emergency messages
- **⚡ Priority Routing**: Emergency messages get priority treatment in mesh routing
- **🏥 Emergency Service Discovery**: Announce and discover emergency services in the area
- **🚨 Multi-Type Emergencies**: Support for medical, fire, police, accident, natural disaster, and personal safety emergencies
- **📱 Urgency Levels**: Critical, high, medium, and low urgency classification
- **🔁 Response System**: Responders can acknowledge, indicate en route status, or provide updates
- **📞 Contact Information**: Optional contact details with emergency messages
- **🌐 Internetless Operation**: Works completely offline using Bluetooth mesh networking
- **🔋 Battery Optimized**: Adaptive power management for extended emergency operation

## Setup

### Option 1: Using XcodeGen (Recommended)

1. Install XcodeGen if you haven't already:
   ```bash
   brew install xcodegen
   ```

2. Generate the Xcode project:
   ```bash
   cd bitchat
   xcodegen generate
   ```

3. Open the generated project:
   ```bash
   open bitchat.xcodeproj
   ```

### Option 2: Using Swift Package Manager

1. Open the project in Xcode:
   ```bash
   cd bitchat
   open Package.swift
   ```

2. Select your target device and run

### Option 3: Manual Xcode Project

1. Open Xcode and create a new iOS/macOS App
2. Copy all Swift files from the `bitchat` directory into your project
3. Update Info.plist with Bluetooth and Location permissions
4. Set deployment target to iOS 16.0 / macOS 13.0

## Usage

### Emergency SOS Usage

#### Sending an Emergency SOS
1. Tap the 🆘 button in the main interface
2. Select emergency type: Medical, Fire, Police, Accident, Natural Disaster, Personal Safety, or Other
3. Choose urgency level: Critical, High, Medium, or Low
4. Enter a description of the emergency
5. Optionally add contact information
6. Choose whether to include your location
7. Tap "SEND SOS MESSAGE" to broadcast to all nearby devices

#### Responding to Emergency SOS
1. When an SOS message appears, tap to view details
2. Use the response options to indicate your status:
   - **Acknowledged**: You've received the emergency message
   - **En Route**: You're on your way to help
   - **On Site**: You've arrived at the emergency location
   - **Referring**: You're forwarding to appropriate services
   - **Unable**: You cannot help at this time

#### Emergency Service Provider
1. Announce your emergency service capability
2. Specify service type and capabilities
3. Your service will be discoverable by those needing help

### Basic Chat Commands

- `/j #channel` - Join or create a channel
- `/m @name message` - Send a private message
- `/w` - List online users
- `/channels` - Show all discovered channels
- `/block @name` - Block a peer from messaging you
- `/block` - List all blocked peers
- `/unblock @name` - Unblock a peer
- `/clear` - Clear chat messages
- `/pass [password]` - Set/change channel password (owner only)
- `/transfer @name` - Transfer channel ownership
- `/save` - Toggle message retention for channel (owner only)

### Getting Started

1. Launch the app on your device
2. Set your nickname (or use the auto-generated one)
3. You'll automatically connect to nearby peers
4. For emergencies: Tap the 🆘 button to send emergency messages
5. For regular chat: Join a channel with `/j #general` or start chatting in public
6. Messages relay through the mesh network to reach distant peers

### Channel Features

- **Password Protection**: Channel owners can set passwords with `/pass`
- **Message Retention**: Owners can enable mandatory message saving with `/save`
- **@ Mentions**: Use `@nickname` to mention users (with autocomplete)
- **Ownership Transfer**: Pass control to trusted users with `/transfer`

## Emergency Use Cases

### Natural Disaster Response
- Communicate when cellular towers are down
- Coordinate rescue efforts in affected areas
- Share location and status updates
- Connect with emergency services

### Medical Emergencies
- Request immediate medical assistance
- Share location with responders
- Coordinate with nearby medical professionals
- Provide updates on patient status

### Fire Emergency
- Alert neighbors and emergency services
- Share evacuation routes and safe zones
- Coordinate fire suppression efforts
- Report fire status and spread

### Personal Safety
- Send discreet emergency alerts
- Share location with trusted contacts
- Request immediate assistance
- Coordinate with law enforcement

### Mass Events
- Emergency communication at concerts, festivals
- Lost person alerts and reunification
- Evacuation coordination
- Service provider announcements

## Security & Privacy

### Encryption
- **Private Messages**: X25519 key exchange + AES-256-GCM encryption
- **Channel Messages**: Argon2id password derivation + AES-256-GCM
- **Digital Signatures**: Ed25519 for message authenticity
- **Forward Secrecy**: New key pairs generated each session

### Privacy Features
- **No Registration**: No accounts, emails, or phone numbers required
- **Ephemeral by Default**: Messages exist only in device memory
- **Cover Traffic**: Random delays and dummy messages prevent traffic analysis
- **Emergency Wipe**: Triple-tap logo to instantly clear all data
- **Local-First**: Works completely offline, no servers involved

### Emergency Privacy
- **Optional Location**: Location sharing is optional for SOS messages
- **Selective Information**: Choose what personal information to share
- **Urgent Override**: Critical emergencies can override some privacy settings
- **Anonymous Response**: Responders can choose how much information to share

## Performance & Efficiency

### Message Compression
- **LZ4 Compression**: Automatic compression for messages >100 bytes
- **30-70% bandwidth savings** on typical text messages
- **Smart compression**: Skips already-compressed data

### Battery Optimization
- **Adaptive Power Modes**: Automatically adjusts based on battery level
  - Performance mode: Full features when charging or >60% battery
  - Balanced mode: Default operation (30-60% battery)
  - Power saver: Reduced scanning when <30% battery
  - Ultra-low power: Emergency mode when <10% battery
- **Background efficiency**: Automatic power saving when app backgrounded
- **Configurable scanning**: Duty cycle adapts to battery state

### Network Efficiency
- **Optimized Bloom filters**: Faster duplicate detection with less memory
- **Message aggregation**: Batches small messages to reduce transmissions
- **Adaptive connection limits**: Adjusts peer connections based on power mode
- **Emergency Priority**: SOS messages get priority routing and higher TTL

## Technical Architecture

### Emergency Message Protocol
- **SOS Message Type**: Dedicated message type for emergency communications
- **Priority Routing**: Emergency messages bypass normal queuing
- **Extended TTL**: Emergency messages travel farther through the mesh
- **Location Data**: Structured GPS coordinates with address resolution
- **Response Tracking**: Structured response system with delivery confirmation

### Binary Protocol
bitchat uses an efficient binary protocol optimized for Bluetooth LE:
- Compact packet format with 1-byte type field
- TTL-based message routing (max 10 hops for emergencies)
- Automatic fragmentation for large messages
- Message deduplication via unique IDs
- Emergency message priority handling

### Mesh Networking
- Each device acts as both client and peripheral
- Automatic peer discovery and connection management
- Store-and-forward for offline message delivery
- Adaptive duty cycling for battery optimization
- Emergency message prioritization and extended routing

For detailed protocol documentation, see the [Technical Whitepaper](WHITEPAPER.md).

## Building for Production

1. Set your development team in project settings
2. Configure code signing
3. Add location permissions to Info.plist for SOS functionality
4. Archive and distribute through App Store or TestFlight

## Android Compatibility

The protocol is designed to be platform-agnostic. An Android client can be built using:
- Bluetooth LE APIs
- Same packet structure and encryption
- Compatible service/characteristic UUIDs
- Location Services API for emergency features

## MacOS

Want to try this on macOS: `just run` will set it up and run from source. 
Run `just clean` afterwards to restore things to original state for mobile app building and development.

## Contributing

This project is in the public domain. Contributions are welcome, especially:
- Additional emergency service integrations
- Enhanced location services
- Battery optimization improvements
- Extended platform support
- UI/UX improvements for emergency scenarios

## Disclaimer

This emergency communication system is designed to supplement, not replace, official emergency services. Always contact official emergency services (911, etc.) when available. This system is provided as-is without warranty for emergency situations.
