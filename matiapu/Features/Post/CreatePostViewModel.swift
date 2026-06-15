//
//  CreatePostViewModel.swift
//  matiapu
//

import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class CreatePostViewModel: Identifiable {
    let id = UUID()
    var title = ""
    var body = ""
    var selectedTag: MapFilter = .disaster
    private(set) var isSubmitting = false
    private(set) var submitError: String?

    let capturedImage: UIImage
    let capturedLocation: PostLocation?

    private let postRepository: any PostRepository
    private let onComplete: () -> Void

    init(
        capturedImage: UIImage,
        capturedLocation: PostLocation?,
        postRepository: any PostRepository,
        onComplete: @escaping () -> Void
    ) {
        self.capturedImage = capturedImage
        self.capturedLocation = capturedLocation
        self.postRepository = postRepository
        self.onComplete = onComplete
    }

    var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && capturedLocation != nil
            && !isSubmitting
    }

    var locationStatusMessage: String? {
        guard capturedLocation == nil else { return nil }
        return "位置情報を取得できませんでした。設定アプリで位置情報サービスとカメラの位置情報利用をオンにしてください。"
    }

    func submit() async {
        guard canSubmit, let capturedLocation else { return }

        isSubmitting = true
        submitError = nil
        defer { isSubmitting = false }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            _ = try await postRepository.createPost(
                title: trimmedTitle,
                body: trimmedBody,
                tag: selectedTag,
                image: capturedImage,
                location: capturedLocation
            )
            onComplete()
        } catch {
            submitError = error.localizedDescription
        }
    }
}

#if DEBUG
extension CreatePostViewModel {
    static func preview(onComplete: @escaping () -> Void = {}) -> CreatePostViewModel {
        CreatePostViewModel(
            capturedImage: UIImage(named: MockImages.postImage(at: 0)) ?? UIImage(),
            capturedLocation: PostLocation(latitude: 35.681228, longitude: 139.767052),
            postRepository: MockPostRepository(),
            onComplete: onComplete
        )
    }
}
#endif
