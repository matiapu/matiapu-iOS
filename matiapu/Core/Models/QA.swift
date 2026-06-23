//
//  QA.swift
//  matiapu
//

import Foundation

struct QAQuestion: Identifiable, Hashable {
    let id: String
    let authorUID: String
    let title: String
    let contentText: String
    let prefecture: String
    let createdAt: Date
    let updatedAt: Date?
}

struct QAAnswer: Identifiable, Hashable {
    let id: String
    let questionID: String
    let authorUID: String
    let contentText: String
    let createdAt: Date
    let updatedAt: Date?
}

struct CreateQAQuestionInput: Sendable {
    let authorUID: String
    let title: String
    let contentText: String
    let prefecture: String
}

struct CreateQAAnswerInput: Sendable {
    let authorUID: String
    let contentText: String
}

struct QAQuestionListOptions: Sendable {
    var prefecture: String?
    var limit: Int?
}
