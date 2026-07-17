// TextChatButtonChatButton.swift
// Hubspot Mobile SDK
//
// Copyright © 2024 Hubspot, Inc.

import SwiftUI

/// This is another button what displays an icon as well as text for starting a chat. Similar to ``FloatingActionButton`` , it can be placed anywhere in your UI that makes sense for you, and it will present the chat view modally with a `.sheet` modifier
///
///
///
/// Warning: This UI element was created for another proof of concept - it may or may not be included in the final release.
///
public struct TextChatButton: View {
    private let customText: LocalizedStringKey?
    private let manager: HubspotManager
    private let chatFlow: String?
    private let openToNewThread: Bool

    @State var showingChat: Bool = false

    /// Create button, optionally specifying the manager to use
    ///
    /// - Parameters:
    ///   - text: The text in the button - if nil, default text is used.
    ///   - manager: The manager to use for getting a chat session. By defautl the shared manager is used.
    ///   - chatFlow: The specific chat flow to open. Optional.
    ///   - openToNewThread: Forces the widget to start a new conversation thread instead of resuming the
    ///                      visitor's last active thread - see ``HubspotChatView/init(manager:pushData:chatFlow:openToNewThread:dismissChat:)``.
    ///                      Defaults to `false`.
    public init(text: LocalizedStringKey? = nil, manager: HubspotManager? = nil, chatFlow: String? = nil, openToNewThread: Bool = false) {
        customText = text
        self.manager = manager ?? .shared
        self.chatFlow = chatFlow
        self.openToNewThread = openToNewThread
    }

    public var body: some View {
        Button(
            action: {
                withAnimation {
                    showingChat = true
                }
            },
            label: {
                HStack {
                    Image(.genericChatIcon)
                    if let customText {
                        Text(customText)
                    } else {
                        Text("chat.label", bundle: .module)
                    }
                }

            }
        )
        .labelStyle(.titleAndIcon)
        .buttonStyle(TextChatButtonStyle())
        .sheet(
            isPresented: $showingChat,
            content: {
                HubspotChatView(manager: manager, chatFlow: chatFlow, openToNewThread: openToNewThread)
            })
    }
}

private struct TextChatButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal)
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.tint)
            )
    }
}

#Preview {
    TextChatButton().fixedSize(horizontal: true, vertical: false)
}
