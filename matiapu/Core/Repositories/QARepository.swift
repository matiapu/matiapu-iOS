//
//  QARepository.swift
//  matiapu
//

import Foundation

protocol QARepository: Sendable {
    func createQAQuestion(_ input: CreateQAQuestionInput) async throws -> QAQuestion
    func getQAQuestion(questionId: String) async throws -> QAQuestion
    func updateQAQuestion(questionId: String, title: String, contentText: String, prefecture: String) async throws
    func deleteQAQuestion(questionId: String) async throws
    func getQAQuestions(options: QAQuestionListOptions) async throws -> [QAQuestion]
    func createQAAnswer(questionId: String, input: CreateQAAnswerInput) async throws -> QAAnswer
    func getQAAnswersForQuestion(questionId: String) async throws -> [QAAnswer]
    func updateQAAnswer(questionId: String, answerId: String, contentText: String) async throws
    func deleteQAAnswer(questionId: String, answerId: String) async throws
}
