//
//  MockQARepository.swift
//  matiapu
//

import Foundation

final class MockQARepository: QARepository, @unchecked Sendable {
    private let questions: [QAQuestion] = [
        QAQuestion(
            id: "mock-qa-1",
            authorUID: "mock-user",
            title: "避難所の開設はどこで確認できますか？",
            contentText: "災害時に避難所の情報をどこで確認すればよいか教えてください。",
            prefecture: "東京都",
            createdAt: .now.addingTimeInterval(-172_800),
            updatedAt: nil
        ),
        QAQuestion(
            id: "mock-qa-2",
            authorUID: "mock-user",
            title: "マッチ機能の使い方",
            contentText: "議員とマッチするにはどうすればいいですか？",
            prefecture: "東京都",
            createdAt: .now.addingTimeInterval(-86_400),
            updatedAt: nil
        ),
    ]

    private var answers: [String: [QAAnswer]] = [
        "mock-qa-1": [
            QAAnswer(
                id: "mock-answer-1",
                questionID: "mock-qa-1",
                authorUID: "mock-admin",
                contentText: "マップ画面で避難所マーカーを確認できます。",
                createdAt: .now.addingTimeInterval(-86_400),
                updatedAt: nil
            ),
        ],
    ]

    func createQAQuestion(_ input: CreateQAQuestionInput) async throws -> QAQuestion {
        QAQuestion(
            id: UUID().uuidString,
            authorUID: input.authorUID,
            title: input.title,
            contentText: input.contentText,
            prefecture: input.prefecture,
            createdAt: .now,
            updatedAt: .now
        )
    }

    func getQAQuestion(questionId: String) async throws -> QAQuestion {
        guard let question = questions.first(where: { $0.id == questionId }) else {
            throw FirebaseRepositoryError.documentNotFound
        }
        return question
    }

    func updateQAQuestion(questionId: String, title: String, contentText: String, prefecture: String) async throws {}
    func deleteQAQuestion(questionId: String) async throws {}

    func getQAQuestions(options: QAQuestionListOptions) async throws -> [QAQuestion] {
        var result = questions.sorted { $0.createdAt > $1.createdAt }
        if let prefecture = options.prefecture {
            result = result.filter { $0.prefecture == prefecture }
        }
        if let limit = options.limit {
            result = Array(result.prefix(limit))
        }
        return result
    }

    func createQAAnswer(questionId: String, input: CreateQAAnswerInput) async throws -> QAAnswer {
        let answer = QAAnswer(
            id: UUID().uuidString,
            questionID: questionId,
            authorUID: input.authorUID,
            contentText: input.contentText,
            createdAt: .now,
            updatedAt: .now
        )
        answers[questionId, default: []].append(answer)
        return answer
    }

    func getQAAnswersForQuestion(questionId: String) async throws -> [QAAnswer] {
        answers[questionId] ?? []
    }

    func updateQAAnswer(questionId: String, answerId: String, contentText: String) async throws {}
    func deleteQAAnswer(questionId: String, answerId: String) async throws {}
}
