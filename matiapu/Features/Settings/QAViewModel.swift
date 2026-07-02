//
//  QAViewModel.swift
//  matiapu
//

import Foundation
import Observation

@Observable
@MainActor
final class QAViewModel {
    private(set) var questions: [QAQuestion] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let fetchQAQuestions: FetchQAQuestionsUseCase

    init(fetchQAQuestions: FetchQAQuestionsUseCase) {
        self.fetchQAQuestions = fetchQAQuestions
    }

    func loadQuestions() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            questions = try await fetchQAQuestions.execute()
        } catch {
            questions = []
            errorMessage = "Q&Aの読み込みに失敗しました。"
        }
    }
}

@Observable
@MainActor
final class QADetailViewModel {
    private(set) var question: QAQuestion?
    private(set) var answers: [QAAnswer] = []
    private(set) var isLoading = false
    var errorMessage: String?

    let questionId: String
    private let loadQADetail: LoadQADetailUseCase

    init(questionId: String, loadQADetail: LoadQADetailUseCase) {
        self.questionId = questionId
        self.loadQADetail = loadQADetail
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let snapshot = try await loadQADetail.execute(questionId: questionId)
            question = snapshot.question
            answers = snapshot.answers
        } catch {
            question = nil
            answers = []
            errorMessage = "Q&Aの読み込みに失敗しました。"
        }
    }
}

extension QAViewModel {
    static var preview: QAViewModel {
        QAViewModel(fetchQAQuestions: FetchQAQuestionsUseCase(qaRepository: MockQARepository()))
    }
}
