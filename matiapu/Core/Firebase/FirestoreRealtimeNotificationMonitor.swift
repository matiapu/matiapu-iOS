//
//  FirestoreRealtimeNotificationMonitor.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

struct RealtimeNotificationEvent: Sendable {
    let kind: AppNotificationKind
    let id: String
    let title: String
    let body: String
    let relatedID: String?
    let publishedAt: Date
}

final class FirestoreRealtimeNotificationMonitor: @unchecked Sendable {
    private let db = Firestore.firestore()
    private let inboxStore: LocalNotificationInboxStore
    private var listeners: [ListenerRegistration] = []
    private let lock = NSLock()

    private var userID: String?
    private var openConversationID: String?
    private var roomLastMessageAt: [String: Date] = [:]
    private var knownMatchIDs: Set<String> = []
    private var knownAnnouncementIDs: Set<String> = []
    private var isPriming = true

    var onEvent: (@Sendable (RealtimeNotificationEvent) -> Void)?

    init(inboxStore: LocalNotificationInboxStore) {
        self.inboxStore = inboxStore
    }

    func setOpenConversationID(_ conversationID: String?) {
        locked { openConversationID = conversationID }
    }

    func start(userID: String) {
        stop()
        locked {
            self.userID = userID
            isPriming = true
            roomLastMessageAt = [:]
            knownMatchIDs = []
            knownAnnouncementIDs = []
        }

        listenMatches(userID: userID)
        listenChatRooms(userID: userID)
        listenAnnouncements()

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            self.locked { self.isPriming = false }
        }
    }

    func markMatchAsKnown(_ matchID: String) {
        locked { _ = knownMatchIDs.insert(matchID) }
    }

    func stop() {
        listeners.forEach { $0.remove() }
        listeners = []
        locked {
            userID = nil
            openConversationID = nil
        }
    }

    private func listenMatches(userID: String) {
        let collection = db.collection(FirestoreCollections.matches)

        let userListener = collection
            .whereField(FirestoreFields.Match.userUID, isEqualTo: userID)
            .whereField(FirestoreFields.Match.status, isEqualTo: FirestoreMatchStatus.matched.rawValue)
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.handleMatchSnapshot(snapshot)
            }

        let politicianListener = collection
            .whereField(FirestoreFields.Match.politicianUID, isEqualTo: userID)
            .whereField(FirestoreFields.Match.status, isEqualTo: FirestoreMatchStatus.matched.rawValue)
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.handleMatchSnapshot(snapshot)
            }

        listeners.append(contentsOf: [userListener, politicianListener])
    }

    private func listenChatRooms(userID: String) {
        let listener = db.collection(FirestoreCollections.chatRooms)
            .whereField(FirestoreFields.ChatRoom.userIDs, arrayContains: userID)
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.handleChatRoomSnapshot(snapshot, userID: userID)
            }
        listeners.append(listener)
    }

    private func listenAnnouncements() {
        let listener = db.collection(FirestoreCollections.announcements)
            .order(by: FirestoreFields.Announcement.publishedAt, descending: true)
            .limit(to: 20)
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.handleAnnouncementSnapshot(snapshot)
            }
        listeners.append(listener)
    }

    private func handleMatchSnapshot(_ snapshot: QuerySnapshot?) {
        guard let documents = snapshot?.documentChanges else { return }

        for change in documents where change.type != .removed {
            let data = change.document.data()
            guard
                (data[FirestoreFields.Match.status] as? String) == FirestoreMatchStatus.matched.rawValue,
                let userUID = data[FirestoreFields.Match.userUID] as? String,
                let politicianUID = data[FirestoreFields.Match.politicianUID] as? String
            else {
                continue
            }

            let matchID = change.document.documentID
            let shouldNotify = locked {
                guard !isPriming else {
                    knownMatchIDs.insert(matchID)
                    return false
                }
                guard !knownMatchIDs.contains(matchID) else { return false }
                knownMatchIDs.insert(matchID)
                return true
            }
            guard shouldNotify else { continue }

            let currentUID = locked { userID }
            guard let currentUID else { continue }

            let partnerID = currentUID == userUID ? politicianUID : userUID
            let roomID = ChatCrypto.chatRoomID(uid1: userUID, uid2: politicianUID)
            let matchedAt = FirestoreDateCodec.date(from: data[FirestoreFields.Match.matchedAt]) ?? .now

            Task {
                let partnerName = await self.partnerName(for: partnerID)
                self.emit(
                    RealtimeNotificationEvent(
                        kind: .match,
                        id: "match-\(matchID)",
                        title: "マッチしました！",
                        body: "\(partnerName)さんとマッチしました。チャットを始めましょう。",
                        relatedID: roomID,
                        publishedAt: matchedAt
                    )
                )
            }
        }
    }

    private func handleChatRoomSnapshot(_ snapshot: QuerySnapshot?, userID: String) {
        guard let documents = snapshot?.documents else { return }

        for document in documents {
            guard let room = FirestoreChatRoomMapper.room(from: document) else { continue }

            let latestAt = room.lastMessageAt
            let previousAt = locked { roomLastMessageAt[room.id] }
            locked { roomLastMessageAt[room.id] = latestAt }

            let isInitial = locked { isPriming }
            if isInitial || previousAt == nil {
                continue
            }

            guard latestAt > (previousAt ?? .distantPast) else { continue }
            guard locked({ openConversationID != room.id }) else { continue }
            guard room.lastMessageSenderID != userID else { continue }
            guard let partnerID = room.partnerID(currentUID: userID) else { continue }

            let preview = room.decryptedLastMessage() ?? "新しいメッセージが届きました"
            if preview == ChatCrypto.undecryptableMessageText {
                continue
            }

            Task {
                let partnerName = await self.partnerName(for: partnerID)
                self.emit(
                    RealtimeNotificationEvent(
                        kind: .message,
                        id: "message-\(room.id)-\(Int(latestAt.timeIntervalSince1970))",
                        title: partnerName,
                        body: preview,
                        relatedID: room.id,
                        publishedAt: latestAt
                    )
                )
            }
        }
    }

    private func handleAnnouncementSnapshot(_ snapshot: QuerySnapshot?) {
        guard let documents = snapshot?.documentChanges else { return }

        for change in documents where change.type == .added {
            let documentID = change.document.documentID
            let shouldNotify = locked {
                guard !isPriming else {
                    knownAnnouncementIDs.insert(documentID)
                    return false
                }
                guard !knownAnnouncementIDs.contains(documentID) else { return false }
                knownAnnouncementIDs.insert(documentID)
                return true
            }
            guard shouldNotify else { continue }
            guard
                let announcement = FirestoreAnnouncementMapper.announcement(
                    from: change.document,
                    isRead: false
                )
            else {
                continue
            }

            emit(
                RealtimeNotificationEvent(
                    kind: .announcement,
                    id: announcement.id,
                    title: announcement.title,
                    body: announcement.body,
                    relatedID: announcement.relatedID,
                    publishedAt: announcement.publishedAt
                )
            )
        }
    }

    private func partnerName(for partnerID: String) async -> String {
        do {
            let snapshot = try await db.collection(FirestoreCollections.users).document(partnerID).getDocument()
            guard let data = snapshot.data() else { return UserPublicProfile.fallbackDisplayName }
            return FirestoreUserPublicProfileMapper.map(from: data, uid: partnerID).displayName
        } catch {
            return UserPublicProfile.fallbackDisplayName
        }
    }

    private func emit(_ event: RealtimeNotificationEvent) {
        let notification = AppNotification(
            id: event.id,
            kind: event.kind,
            title: event.title,
            body: event.body,
            publishedAt: event.publishedAt,
            isRead: false,
            relatedID: event.relatedID
        )

        if event.kind != .announcement {
            inboxStore.append(notification)
        }

        onEvent?(event)
    }

    private func locked<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}
