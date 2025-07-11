//
// SOSView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

struct SOSView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedSOSType: SOSType = .medical
    @State private var selectedUrgency: UrgencyLevel = .high
    @State private var description: String = ""
    @State private var includeLocation: Bool = true
    @State private var contactInfo: String = ""
    @State private var showingConfirmation = false
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.red : Color.red
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.red.opacity(0.8) : Color.red.opacity(0.8)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text("🆘")
                                .font(.system(size: 60))
                            Text("EMERGENCY SOS")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(textColor)
                            Text("This will broadcast an emergency message to all nearby devices")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(secondaryTextColor)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 20)
                        
                        // Emergency Type Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Emergency Type")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(textColor)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(SOSType.allCases, id: \.self) { type in
                                    Button(action: {
                                        selectedSOSType = type
                                    }) {
                                        VStack(spacing: 8) {
                                            Text(type.emoji)
                                                .font(.system(size: 24))
                                            Text(type.displayName)
                                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 60)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedSOSType == type ? Color.red.opacity(0.3) : Color.gray.opacity(0.1))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedSOSType == type ? Color.red : Color.gray, lineWidth: 2)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(selectedSOSType == type ? textColor : secondaryTextColor)
                                }
                            }
                        }
                        
                        // Urgency Level
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Urgency Level")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(textColor)
                            
                            HStack(spacing: 8) {
                                ForEach(UrgencyLevel.allCases, id: \.self) { urgency in
                                    Button(action: {
                                        selectedUrgency = urgency
                                    }) {
                                        Text(urgency.displayName)
                                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(selectedUrgency == urgency ? Color.red.opacity(0.3) : Color.gray.opacity(0.1))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(selectedUrgency == urgency ? Color.red : Color.gray, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(selectedUrgency == urgency ? textColor : secondaryTextColor)
                                }
                            }
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(textColor)
                            
                            TextField("Describe the emergency situation...", text: $description, axis: .vertical)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14, design: .monospaced))
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .foregroundColor(textColor)
                        }
                        
                        // Contact Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contact Info (Optional)")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(textColor)
                            
                            TextField("Phone number or other contact info...", text: $contactInfo)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14, design: .monospaced))
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .foregroundColor(textColor)
                        }
                        
                        // Location Toggle
                        HStack {
                            Toggle("Include Location", isOn: $includeLocation)
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(textColor)
                            Spacer()
                        }
                        
                        // Send Button
                        Button(action: {
                            showingConfirmation = true
                        }) {
                            HStack {
                                Text("🚨 SEND SOS MESSAGE")
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(description.isEmpty)
                        .opacity(description.isEmpty ? 0.5 : 1.0)
                        
                        Spacer()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Emergency SOS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(textColor)
                }
            }
            .alert("Confirm Emergency SOS", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Send SOS", role: .destructive) {
                    sendSOS()
                }
            } message: {
                Text("This will send an emergency SOS message to all nearby devices. Are you sure you want to proceed?")
            }
        }
    }
    
    private func sendSOS() {
        viewModel.sendSOSMessage(
            type: selectedSOSType,
            urgency: selectedUrgency,
            description: description,
            includeLocation: includeLocation,
            contactInfo: contactInfo.isEmpty ? nil : contactInfo
        )
        
        dismiss()
    }
}

struct SOSView_Previews: PreviewProvider {
    static var previews: some View {
        SOSView()
            .environmentObject(ChatViewModel())
    }
}