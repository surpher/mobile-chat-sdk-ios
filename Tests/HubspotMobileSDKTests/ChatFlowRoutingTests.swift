// ChatFlowRoutingTests.swift
// Hubspot Mobile SDK
//
// Copyright © 2026 Hubspot, Inc.

import Combine
import Testing
import WebKit

@testable import HubspotMobileSDK

@MainActor
struct ResolveChatFlowTests {

    @Test
    func usesConfiguredDefaultWhenNothingElseProvided() {
        let manager = HubspotManager()
        manager.configure(portalId: "123", hublet: "na1", defaultChatFlow: "default-flow")

        #expect(manager.resolveChatFlow(withPushData: nil, forChatFlow: nil) == "default-flow")
    }

    @Test
    func explicitChatFlowOverridesConfiguredDefault() {
        let manager = HubspotManager()
        manager.configure(portalId: "123", hublet: "na1", defaultChatFlow: "default-flow")

        #expect(manager.resolveChatFlow(withPushData: nil, forChatFlow: "explicit-flow") == "explicit-flow")
    }

    @Test
    func pushDataChatFlowTakesPrecedenceOverExplicitAndDefault() {
        let manager = HubspotManager()
        manager.configure(portalId: "123", hublet: "na1", defaultChatFlow: "default-flow")
        let pushData = PushNotificationChatData(notificationData: ["hsChatflowParam": "push-flow"])

        #expect(manager.resolveChatFlow(withPushData: pushData, forChatFlow: "explicit-flow") == "push-flow")
    }

    @Test
    func returnsNilWhenNoChatFlowIsResolvable() {
        let manager = HubspotManager()
        manager.configure(portalId: "123", hublet: "na1", defaultChatFlow: nil)

        #expect(manager.resolveChatFlow(withPushData: nil, forChatFlow: nil) == nil)
    }
}

@MainActor
struct ChatUrlTests {
    @Test
    func includesResolvedChatFlowInQuery() throws {
        let manager = HubspotManager()
        manager.configure(portalId: "123", hublet: "na1", defaultChatFlow: nil)

        let url = try manager.chatUrl(withPushData: nil, forChatFlow: "sales")

        let query = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(query.contains { $0.name == "chatflow" && $0.value == "sales" })
        #expect(query.contains { $0.name == "portalId" && $0.value == "123" })
    }

    @Test
    func throwsMissingChatFlowWhenNoneResolvable() {
        let manager = HubspotManager()
        manager.configure(portalId: "123", hublet: "na1", defaultChatFlow: nil)

        do {
            _ = try manager.chatUrl(withPushData: nil, forChatFlow: nil)
            Issue.record("Expected chatUrl to throw missingChatFlow")
        } catch HubspotConfigError.missingChatFlow {
            // expected
        } catch {
            Issue.record("Expected missingChatFlow, got \(error)")
        }
    }

    @Test
    func throwsMissingConfigurationWhenUnconfigured() {
        let manager = HubspotManager()

        do {
            _ = try manager.chatUrl(withPushData: nil, forChatFlow: "sales")
            Issue.record("Expected chatUrl to throw missingConfiguration")
        } catch HubspotConfigError.missingConfiguration {
            // expected
        } catch {
            Issue.record("Expected missingConfiguration, got \(error)")
        }
    }
}

@MainActor
struct WebsiteDataStoreIsolationTests {
    @Test
    func sameChatFlowReusesTheSamePersistentStore() async throws {
        let manager = HubspotManager()
        manager.configure(portalId: "isolation-test-portal", hublet: "na1", defaultChatFlow: nil)

        let firstLookup = manager.websiteDataStore(withPushData: nil, forChatFlow: "flow-a")
        let secondLookup = manager.websiteDataStore(withPushData: nil, forChatFlow: "flow-a")

        let cookie = try #require(HTTPCookie(properties: [
            .name: "hubspotutk",
            .value: "same-flow-value",
            .domain: "example.com",
            .path: "/",
        ]))
        await firstLookup.httpCookieStore.setCookie(cookie)

        let cookiesSeenBySecondLookup = await secondLookup.httpCookieStore.allCookies()
        #expect(cookiesSeenBySecondLookup.contains { $0.name == "hubspotutk" && $0.value == "same-flow-value" })

        // cleanup so repeated test runs on the same simulator don't accumulate cookies
        await firstLookup.httpCookieStore.deleteCookie(cookie)
    }

    @Test
    func differentChatFlowsGetIsolatedStores() async throws {
        let manager = HubspotManager()
        manager.configure(portalId: "isolation-test-portal", hublet: "na1", defaultChatFlow: nil)

        let flowAStore = manager.websiteDataStore(withPushData: nil, forChatFlow: "flow-b1")
        let flowBStore = manager.websiteDataStore(withPushData: nil, forChatFlow: "flow-b2")

        let cookie = try #require(HTTPCookie(properties: [
            .name: "hubspotutk",
            .value: "flow-a-value",
            .domain: "example.com",
            .path: "/",
        ]))
        await flowAStore.httpCookieStore.setCookie(cookie)

        let cookiesSeenByOtherFlow = await flowBStore.httpCookieStore.allCookies()
        #expect(!cookiesSeenByOtherFlow.contains { $0.name == "hubspotutk" })

        await flowAStore.httpCookieStore.deleteCookie(cookie)
    }

    @Test
    func fallsBackToDefaultStoreWhenChatFlowUnresolvable() {
        let manager = HubspotManager()
        manager.configure(portalId: "isolation-test-portal", hublet: "na1", defaultChatFlow: nil)

        let store = manager.websiteDataStore(withPushData: nil, forChatFlow: nil)

        #expect(store === WKWebsiteDataStore.default())
    }
}

@MainActor
struct ThreadOpenedReportingTests {
    @Test
    func reportsChatThreadInfoViaCallbackAndPublisher() async {
        let manager = HubspotManager()

        var reportedViaCallback: ChatThreadInfo?
        manager.threadOpenedCallback = { info in
            reportedViaCallback = info
        }

        var reportedViaPublisher: ChatThreadInfo?
        var cancellables = Set<AnyCancellable>()
        manager.threadOpened.sink { info in
            reportedViaPublisher = info
        }.store(in: &cancellables)

        manager.handleThreadOpened(threadId: "999", chatFlow: "sales")

        #expect(reportedViaCallback == ChatThreadInfo(chatFlow: "sales", threadId: "999"))
        #expect(reportedViaPublisher == ChatThreadInfo(chatFlow: "sales", threadId: "999"))
    }

    @Test
    func doesNotReportWhenChatFlowIsUnknown() {
        let manager = HubspotManager()

        var reported = false
        manager.threadOpenedCallback = { _ in
            reported = true
        }

        manager.handleThreadOpened(threadId: "999", chatFlow: nil)

        #expect(!reported)
    }
}
