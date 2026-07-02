//
//  QARepository.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

final class FirebaseQARepository: QARepository, @unchecked Sendable {
    private let db = Firestore.firestore()

    func createQAQuestion(_ input: CreateQAQuestionInput) async throws -> QAQuestion {
        let documentRef = db.collection(FirestoreCollections.qaQuestions).document()
        let now = FirestoreDateCodec.timestamp()
        let payload: [String: Any] = [
            "author_uid": input.authorUID,
            "title": input.title,
            "content_text": input.contentText,
            "prefecture": input.prefecture,
            "created_at": now,
            "updated_at": now,
        ]
        try await documentRef.setData(payload)
        return QAQuestion(
            id: documentRef.documentID,
            authorUID: input.authorUID,
            title: input.title,
            contentText: input.contentText,
            prefecture: input.prefecture,
            createdAt: .now,
            updatedAt: .now
        )
    }

    func getQAQuestion(questionId: String) async throws -> QAQuestion {
        let snapshot = try await db.collection(FirestoreCollections.qaQuestions).document(questionId).getDocument()
        guard let data = snapshot.data(), let question = mapQuestion(id: snapshot.documentID, data: data) else {
            throw FirebaseRepositoryError.documentNotFound
        }
        return question
    }

    func updateQAQuestion(questionId: String, title: String, contentText: String, prefecture: String) async throws {
        try await db.collection(FirestoreCollections.qaQuestions).document(questionId).updateData([
            "title": title,
            "content_text": contentText,
            "prefecture": prefecture,
            "updated_at": FirestoreDateCodec.timestamp(),
        ])
    }

    func deleteQAQuestion(questionId: String) async throws {
        try await db.collection(FirestoreCollections.qaQuestions).document(questionId).delete()
    }

    func getQAQuestions(options: QAQuestionListOptions) async throws -> [QAQuestion] {
        var query: Query = db.collection(FirestoreCollections.qaQuestions)
            .order(by: "created_at", descending: true)

        if let prefecture = options.prefecture {
            query = query.whereField("prefecture", isEqualTo: prefecture)
        }
        if let limit = options.limit {
            query = query.limit(to: limit)
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { mapQuestion(id: $0.documentID, data: $0.data()) }
    }

    func createQAAnswer(questionId: String, input: CreateQAAnswerInput) async throws -> QAAnswer {
        let documentRef = db.collection(FirestoreCollections.qaQuestions)
            .document(questionId)
            .collection(FirestoreCollections.answers)
            .document()
        let now = FirestoreDateCodec.timestamp()
        let payload: [String: Any] = [
            "question_id": questionId,
            "author_uid": input.authorUID,
            "content_text": input.contentText,
            "created_at": now,
            "updated_at": now,
        ]
        try await documentRef.setData(payload)
        return QAAnswer(
            id: documentRef.documentID,
            questionID: questionId,
            authorUID: input.authorUID,
            contentText: input.contentText,
            createdAt: .now,
            updatedAt: .now
        )
    }

    func getQAAnswersForQuestion(questionId: String) async throws -> [QAAnswer] {
        let snapshot = try await db.collection(FirestoreCollections.qaQuestions)
            .document(questionId)
            .collection(FirestoreCollections.answers)
            .order(by: "created_at", descending: false)
            .getDocuments()
        return snapshot.documents.compactMap { mapAnswer(questionID: questionId, id: $0.documentID, data: $0.data()) }
    }

    func updateQAAnswer(questionId: String, answerId: String, contentText: String) async throws {
        try await db.collection(FirestoreCollections.qaQuestions)
            .document(questionId)
            .collection(FirestoreCollections.answers)
            .document(answerId)
            .updateData([
                "content_text": contentText,
                "updated_at": FirestoreDateCodec.timestamp(),
            ])
    }

    func deleteQAAnswer(questionId: String, answerId: String) async throws {
        try await db.collection(FirestoreCollections.qaQuestions)
            .document(questionId)
            .collection(FirestoreCollections.answers)
            .document(answerId)
            .delete()
    }

    private func mapQuestion(id: String, data: [String: Any]) -> QAQuestion? {
        guard
            let authorUID = data["author_uid"] as? String,
            let title = data["title"] as? String,
            let contentText = data["content_text"] as? String,
            let prefecture = data["prefecture"] as? String
        else {
            return nil
        }

        return QAQuestion(
            id: id,
            authorUID: authorUID,
            title: title,
            contentText: contentText,
            prefecture: prefecture,
            createdAt: FirestoreDateCodec.date(from: data["created_at"]) ?? .now,
            updatedAt: FirestoreDateCodec.date(from: data["updated_at"])
        )
    }

    private func mapAnswer(questionID: String, id: String, data: [String: Any]) -> QAAnswer? {
        guard
            let authorUID = data["author_uid"] as? String,
            let contentText = data["content_text"] as? String
        else {
            return nil
        }

        return QAAnswer(
            id: id,
            questionID: questionID,
            authorUID: authorUID,
            contentText: contentText,
            createdAt: FirestoreDateCodec.date(from: data["created_at"]) ?? .now,
            updatedAt: FirestoreDateCodec.date(from: data["updated_at"])
        )
    }
}
