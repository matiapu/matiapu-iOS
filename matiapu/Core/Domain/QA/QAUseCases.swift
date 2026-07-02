//
//  QAUseCases.swift
//  matiapu
//

import Foundation

struct FetchQAQuestionsUseCase: Sendable {
    private let qaRepository: any QARepository

    init(qaRepository: any QARepository) {
        self.qaRepository = qaRepository
    }

    func execute(limit: Int = 50) async throws -> [QAQuestion] {
        try await qaRepository.getQAQuestions(options: QAQuestionListOptions(limit: limit))
    }
}

struct QADetailSnapshot: Sendable {
    let question: QAQuestion
    let answers: [QAAnswer]
}

struct LoadQADetailUseCase: Sendable {
    private let qaRepository: any QARepository

    init(qaRepository: any QARepository) {
        self.qaRepository = qaRepository
    }

    func execute(questionId: String) async throws -> QADetailSnapshot {
        async let question = qaRepository.getQAQuestion(questionId: questionId)
        async let answers = qaRepository.getQAAnswersForQuestion(questionId: questionId)
        return try await QADetailSnapshot(
            question: question,
            answers: answers
        )
    }
}
