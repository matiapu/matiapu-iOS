//
//  FirebaseAuthRepository.swift
//  matiapu
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation
import os
import UIKit

final class FirebaseAuthRepository: AuthRepository, @unchecked Sendable {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let profileStore = LocalUserProfileStore.shared
    private let cachedProfile = OSAllocatedUnfairLock<UserProfile?>(initialState: nil)
    private let verificationDisplayName = OSAllocatedUnfairLock<String?>(initialState: nil)

    var isAuthenticated: Bool {
        guard let user = FirebaseAuthSession.currentUser else { return false }
        return !FirebaseAuthSession.needsEmailVerification(user: user)
    }

    var pendingVerificationDisplayName: String? {
        verificationDisplayName.withLock { $0 }
    }

    func fetchCurrentUser(forceRefresh: Bool) async throws -> UserProfile {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        guard let user = FirebaseAuthSession.currentUser else {
            throw AuthError.notAuthenticated
        }
        if FirebaseAuthSession.needsEmailVerification(user: user) {
            throw AuthError.emailNotVerified
        }

        if !forceRefresh, let cached = cachedProfile(for: uid) {
            return cached
        }

        let profile = try await fetchProfileFromFirestore(uid: uid, user: user)
        storeCachedProfile(profile)
        return profile
    }

    func cachedCurrentUser() -> UserProfile? {
        guard let uid = FirebaseAuthSession.currentUser?.uid else { return nil }
        return cachedProfile(for: uid)
    }

    private func cachedProfile(for uid: String) -> UserProfile? {
        if let memory = cachedProfile.withLock({ $0 }), memory.id == uid {
            return memory
        }
        if let disk = profileStore.load(uid: uid) {
            cachedProfile.withLock { $0 = disk }
            return disk
        }
        return nil
    }

    private func storeCachedProfile(_ profile: UserProfile) {
        cachedProfile.withLock { $0 = profile }
        profileStore.save(profile)
    }

    private func clearCachedProfile() {
        if let profile = cachedProfile.withLock({ $0 }) {
            profileStore.remove(uid: profile.id)
            LocalProfileImageStore.shared.remove(forUID: profile.id)
            if let imageURL = profile.profileImageURL {
                LocalProfileImageStore.shared.remove(forURL: imageURL)
            }
        }
        cachedProfile.withLock { $0 = nil }
    }

    private func fetchProfileFromFirestore(uid: String, user: User) async throws -> UserProfile {
        let document = try await db.collection(FirestoreCollections.users).document(uid).getDocument()
        if let data = document.data() {
            return FirestoreUserMapper.profile(from: data, uid: uid)
        }

        let email = user.email ?? ""
        let defaultData = FirestoreUserMapper.defaultProfile(uid: uid, email: email)
        try await db.collection(FirestoreCollections.users).document(uid).setData(defaultData, merge: true)
        return FirestoreUserMapper.profile(from: defaultData, uid: uid)
    }

    private func refreshCachedProfile() async throws {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        guard let user = FirebaseAuthSession.currentUser else {
            throw AuthError.notAuthenticated
        }
        let profile = try await fetchProfileFromFirestore(uid: uid, user: user)
        storeCachedProfile(profile)
    }

    func fetchUserPosts() async throws -> [ProfilePostItem] {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        let snapshot = try await db.collection(FirestoreCollections.posts)
            .whereField(FirestoreFields.Post.authorUID, isEqualTo: uid)
            .order(by: FirestoreFields.Post.createdAt, descending: true)
            .limit(to: 12)
            .getDocuments()

        return snapshot.documents.compactMap { document in
            guard let post = FirestorePostMapper.post(id: document.documentID, data: document.data()) else {
                return nil
            }
            return ProfilePostItem(
                id: post.id,
                imageName: post.imageName ?? "",
                imageURL: post.imageURL
            )
        }
    }

    func fetchPublicProfiles(userIDs: [String]) async throws -> [String: UserPublicProfile] {
        let uniqueIDs = Array(Set(userIDs))
        guard !uniqueIDs.isEmpty else { return [:] }

        return try await withThrowingTaskGroup(of: (String, UserPublicProfile?).self) { group in
            for uid in uniqueIDs {
                group.addTask {
                    let snapshot = try await self.db
                        .collection(FirestoreCollections.users)
                        .document(uid)
                        .getDocument()
                    guard let data = snapshot.data() else { return (uid, nil) }
                    return (uid, FirestoreUserPublicProfileMapper.map(from: data, uid: uid))
                }
            }

            var profiles: [String: UserPublicProfile] = [:]
            profiles.reserveCapacity(uniqueIDs.count)
            for try await (uid, profile) in group {
                if let profile {
                    profiles[uid] = profile
                }
            }
            return profiles
        }
    }

    private func patchCachedProfile(_ transform: (UserProfile) -> UserProfile) {
        guard let uid = FirebaseAuthSession.currentUser?.uid,
              let current = cachedProfile(for: uid) else { return }
        storeCachedProfile(transform(current))
    }

    func updateDisplayName(_ name: String) async throws {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        try await db.collection(FirestoreCollections.users)
            .document(uid)
            .setData(FirestoreUserMapper.displayNameUpdate(name), merge: true)
        patchCachedProfile { $0.updating(displayName: name, nickname: name) }
    }

    func updateProfileImage(_ image: UIImage) async throws {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        guard let imageURL = try await uploadProfileImageIfNeeded(image, uid: uid) else {
            throw AuthError.unknown("プロフィール画像のアップロードに失敗しました。")
        }
        try await db.collection(FirestoreCollections.users)
            .document(uid)
            .setData(FirestoreUserMapper.profileImageUpdate(imageURL), merge: true)
        patchCachedProfile { $0.updating(profileImageURL: imageURL) }
    }

    func updateRegisteredArea(_ area: String) async throws {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        try await db.collection(FirestoreCollections.users)
            .document(uid)
            .setData(FirestoreUserMapper.registeredAreaUpdate(area), merge: true)
        patchCachedProfile { $0.updatingRegisteredArea(area) }
    }

    func updateEmail(_ email: String) async throws {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        try await db.collection(FirestoreCollections.users)
            .document(uid)
            .setData(FirestoreUserMapper.emailUpdate(email), merge: true)
        patchCachedProfile { $0.updating(email: email) }
    }

    func updatePassword(_ password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.notAuthenticated
        }
        try await user.updatePassword(to: password)
    }

    func signOut() async throws {
        try Auth.auth().signOut()
        verificationDisplayName.withLock { $0 = nil }
        clearCachedProfile()
    }

    func deleteAccount() async throws {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        guard let user = FirebaseAuthSession.currentUser else {
            throw AuthError.notAuthenticated
        }

        do {
            try await deleteUserFirestoreData(uid: uid)
            try? await storage.reference().child("users/\(uid)/profile.jpg").delete()
            try await user.delete()
            clearPendingVerification()
            clearCachedProfile()
        } catch {
            throw FirebaseAuthErrorMapper.map(error)
        }
    }

    func signIn(email: String, password: String) async throws {
        clearCachedProfile()
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            try await ensureFirestoreProfile(for: result.user, displayName: nil)
            if FirebaseAuthSession.needsEmailVerification(user: result.user) {
                storePendingVerification(displayName: result.user.displayName ?? "ユーザー")
                throw AuthError.emailNotVerified
            }
            clearPendingVerification()
            try await refreshCachedProfile()
        } catch let error as AuthError {
            throw error
        } catch {
            throw FirebaseAuthErrorMapper.map(error)
        }
    }

    func signUp(displayName: String, email: String, password: String, role: UserRole) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()

            // Firestore より先に送信する。プロフィール保存が失敗しても認証メールは届くようにする。
            try await FirebaseEmailVerificationSettings.send(to: result.user)
            storePendingVerification(displayName: displayName)

            let profileData = FirestoreUserMapper.registrationProfile(
                uid: result.user.uid,
                email: email,
                displayName: displayName,
                role: role
            )
            try await db.collection(FirestoreCollections.users)
                .document(result.user.uid)
                .setData(profileData, merge: true)
        } catch {
            throw FirebaseAuthErrorMapper.map(error)
        }
    }

    func updateRegistrationRole(_ role: UserRole) async throws {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        try await db.collection(FirestoreCollections.users)
            .document(uid)
            .setData(FirestoreUserMapper.roleUpdate(role), merge: true)
        try await refreshCachedProfile()
    }

    func completeProfile(_ input: ProfileCompletionInput) async throws {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        let imageURL = try await uploadProfileImageIfNeeded(input.profileImage, uid: uid)
        let payload = FirestoreUserMapper.profileCompletionPayload(input, profileImageURL: imageURL)
        try await db.collection(FirestoreCollections.users)
            .document(uid)
            .setData(payload, merge: true)
        try await refreshCachedProfile()
    }

    func signInWithGoogle() async throws {
        clearCachedProfile()
        do {
            try await GoogleSignInHelper.signIn()
            guard let user = FirebaseAuthSession.currentUser else {
                throw AuthError.notAuthenticated
            }
            try await ensureFirestoreProfile(for: user, displayName: user.displayName)
            clearPendingVerification()
            try await refreshCachedProfile()
        } catch let error as AuthError {
            throw error
        } catch {
            throw FirebaseAuthErrorMapper.map(error)
        }
    }

    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws {
        clearCachedProfile()
        do {
            let credential = AppleSignInHelper.credential(
                idToken: idToken,
                nonce: nonce,
                fullName: fullName
            )
            let result = try await Auth.auth().signIn(with: credential)
            try await ensureFirestoreProfile(for: result.user, displayName: fullName ?? result.user.displayName)
            clearPendingVerification()
            try await refreshCachedProfile()
        } catch {
            throw FirebaseAuthErrorMapper.map(error)
        }
    }

    func sendPasswordReset(to email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw FirebaseAuthErrorMapper.map(error)
        }
    }

    func sendEmailVerification() async throws {
        guard let user = FirebaseAuthSession.currentUser else {
            throw AuthError.notAuthenticated
        }
        try await FirebaseEmailVerificationSettings.send(to: user)
    }

    func reloadAndCheckEmailVerified() async throws -> Bool {
        guard let user = FirebaseAuthSession.currentUser else {
            throw AuthError.notAuthenticated
        }
        try await user.reload()
        guard let refreshed = FirebaseAuthSession.currentUser else {
            throw AuthError.notAuthenticated
        }
        if refreshed.isEmailVerified {
            clearPendingVerification()
            try await db.collection(FirestoreCollections.users)
                .document(refreshed.uid)
                .setData([
                    FirestoreFields.User.isVerified: true,
                    FirestoreFields.User.updatedAt: FirestoreDateCodec.isoString(),
                ], merge: true)
            try await refreshCachedProfile()
            return true
        }
        return false
    }

    private func ensureFirestoreProfile(for user: User, displayName: String?) async throws {
        let snapshot = try await db.collection(FirestoreCollections.users).document(user.uid).getDocument()
        guard snapshot.exists else {
            let profileData = FirestoreUserMapper.registrationProfile(
                uid: user.uid,
                email: user.email ?? "",
                displayName: displayName ?? user.displayName ?? "ユーザー"
            )
            try await db.collection(FirestoreCollections.users).document(user.uid).setData(profileData, merge: true)
            return
        }
    }

    private func deleteUserFirestoreData(uid: String) async throws {
        let postsSnapshot = try await db.collection(FirestoreCollections.posts)
            .whereField(FirestoreFields.Post.authorUID, isEqualTo: uid)
            .getDocuments()
        for document in postsSnapshot.documents {
            try await document.reference.delete()
        }

        try await db.collection(FirestoreCollections.users).document(uid).delete()
    }

    private func storePendingVerification(displayName: String) {
        verificationDisplayName.withLock { $0 = displayName }
    }

    private func clearPendingVerification() {
        verificationDisplayName.withLock { $0 = nil }
    }

    private func uploadProfileImageIfNeeded(_ image: UIImage?, uid: String) async throws -> String? {
        guard let image, let data = image.jpegData(compressionQuality: 0.8) else { return nil }

        let path = "users/\(uid)/profile.jpg"
        let reference = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await reference.putDataAsync(data, metadata: metadata)
        let imageURL = try await reference.downloadURL().absoluteString
        LocalProfileImageStore.shared.save(data: data, forURL: imageURL, uid: uid)
        return imageURL
    }
}
