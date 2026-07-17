// ChatThreadInfo.swift
// Hubspot Mobile SDK
//
// Copyright © 2026 Hubspot, Inc.

import Foundation

/// Describes a chat flow's active conversation thread, reported via ``HubspotManager/threadOpened`` and ``HubspotManager/threadOpenedCallback`` whenever the widget starts a new conversation or the visitor selects an existing one.
///
/// This is read-only, informational data - useful for your own persistence or analytics, for example remembering which thread was last active for a given chat flow. It does not control which thread the widget opens.
public struct ChatThreadInfo: Sendable, Equatable {
    /// The chat flow this thread belongs to - the same value passed as `chatFlow` when opening ``HubspotChatView``.
    public let chatFlow: String

    /// The id of the conversation thread.
    public let threadId: String
}
