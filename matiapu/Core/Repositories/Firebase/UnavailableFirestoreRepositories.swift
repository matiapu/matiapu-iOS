//
//  UnavailableFirestoreRepositories.swift
//  matiapu
//

import Foundation

final class UnavailableCommentRepository: CommentRepository, @unchecked Sendable {
    func createComment(_ input: CreateCommentInput) async throws -> Comment { throw FirebaseRepositoryError.notConfigured }
    func getComment(commentId: String) async throws -> Comment { throw FirebaseRepositoryError.notConfigured }
    func updateComment(commentId: String, contentText: String) async throws { throw FirebaseRepositoryError.notConfigured }
    func deleteComment(commentId: String) async throws { throw FirebaseRepositoryError.notConfigured }
    func getCommentsForPost(postId: String, options: CommentListOptions) async throws -> [Comment] { throw FirebaseRepositoryError.notConfigured }
    func getRepliesForComment(commentId: String) async throws -> [Comment] { throw FirebaseRepositoryError.notConfigured }
    func getThreadComments(rootCommentId: String) async throws -> [Comment] { throw FirebaseRepositoryError.notConfigured }
}

final class UnavailableShelterRepository: ShelterRepository, @unchecked Sendable {
    func createShelter(_ input: CreateShelterInput) async throws -> Shelter { throw FirebaseRepositoryError.notConfigured }
    func getShelter(shelterId: String) async throws -> Shelter { throw FirebaseRepositoryError.notConfigured }
    func updateShelter(shelterId: String, input: CreateShelterInput) async throws { throw FirebaseRepositoryError.notConfigured }
    func deleteShelter(shelterId: String) async throws { throw FirebaseRepositoryError.notConfigured }
    func getShelters(municipality: String?) async throws -> [Shelter] { throw FirebaseRepositoryError.notConfigured }
}

final class UnavailableDisasterRepository: DisasterRepository, @unchecked Sendable {
    func createDisaster(_ input: CreateDisasterInput) async throws -> Disaster { throw FirebaseRepositoryError.notConfigured }
    func getDisaster(disasterId: String) async throws -> Disaster { throw FirebaseRepositoryError.notConfigured }
    func updateDisaster(disasterId: String, input: CreateDisasterInput) async throws { throw FirebaseRepositoryError.notConfigured }
    func deleteDisaster(disasterId: String) async throws { throw FirebaseRepositoryError.notConfigured }
    func getDisasters(within bounds: MunicipalityBounds?) async throws -> [Disaster] { throw FirebaseRepositoryError.notConfigured }
}

final class UnavailableQARepository: QARepository, @unchecked Sendable {
    func createQAQuestion(_ input: CreateQAQuestionInput) async throws -> QAQuestion { throw FirebaseRepositoryError.notConfigured }
    func getQAQuestion(questionId: String) async throws -> QAQuestion { throw FirebaseRepositoryError.notConfigured }
    func updateQAQuestion(questionId: String, title: String, contentText: String, prefecture: String) async throws { throw FirebaseRepositoryError.notConfigured }
    func deleteQAQuestion(questionId: String) async throws { throw FirebaseRepositoryError.notConfigured }
    func getQAQuestions(options: QAQuestionListOptions) async throws -> [QAQuestion] { throw FirebaseRepositoryError.notConfigured }
    func createQAAnswer(questionId: String, input: CreateQAAnswerInput) async throws -> QAAnswer { throw FirebaseRepositoryError.notConfigured }
    func getQAAnswersForQuestion(questionId: String) async throws -> [QAAnswer] { throw FirebaseRepositoryError.notConfigured }
    func updateQAAnswer(questionId: String, answerId: String, contentText: String) async throws { throw FirebaseRepositoryError.notConfigured }
    func deleteQAAnswer(questionId: String, answerId: String) async throws { throw FirebaseRepositoryError.notConfigured }
}
