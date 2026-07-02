//
//  CreatePostViewModel.swift
//  matiapu
//

import CoreLocation
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
    private(set) var isResolvingLocation = false
    private(set) var submitError: String?
    private(set) var capturedLocation: PostLocation?

    let capturedImage: UIImage

    private let createPost: CreatePostUseCase
    private let locationCaptureService: LocationCaptureService?
    private let onComplete: (Post) -> Void

    init(
        capturedImage: UIImage,
        capturedLocation: PostLocation?,
        createPost: CreatePostUseCase,
        locationCaptureService: LocationCaptureService?,
        onComplete: @escaping (Post) -> Void
    ) {
        self.capturedImage = capturedImage
        self.capturedLocation = capturedLocation
        self.createPost = createPost
        self.locationCaptureService = locationCaptureService
        self.onComplete = onComplete

        if capturedLocation != nil {
            locationCaptureService?.stopCapture()
        }
    }

    var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && capturedLocation != nil
            && !isSubmitting
            && !isResolvingLocation
    }

    var locationStatusMessage: String? {
        if isResolvingLocation {
            return "位置情報を取得しています…"
        }

        guard capturedLocation == nil else { return nil }

        if let locationCaptureService, !locationCaptureService.isLocationAuthorized {
            return "位置情報を取得できませんでした。設定アプリで位置情報サービスをオンにしてください。"
        }

        return "位置情報を取得できませんでした。屋外など電波の良い場所で再度お試しください。"
    }

    func resolveLocationIfNeeded() async {
        guard capturedLocation == nil, let locationCaptureService else { return }

        isResolvingLocation = true
        defer { isResolvingLocation = false }

        capturedLocation = await locationCaptureService.acquireCoordinate(
            photoCoordinate: nil,
            timeout: 12
        )
        locationCaptureService.stopCapture()
    }

    func submit() async {
        if capturedLocation == nil {
            await resolveLocationIfNeeded()
        }

        guard canSubmit, let capturedLocation else {
            submitError = PostRepositoryError.missingLocation.errorDescription
            return
        }

        isSubmitting = true
        submitError = nil
        defer { isSubmitting = false }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let createdPost = try await createPost.execute(
                title: trimmedTitle,
                body: trimmedBody,
                tag: selectedTag,
                image: capturedImage,
                location: capturedLocation
            )
            locationCaptureService?.stopCapture()
            onComplete(createdPost)
        } catch {
            submitError = PostSubmissionErrorMapper.message(for: error)
        }
    }
}

#if DEBUG
extension CreatePostViewModel {
    static func preview(onComplete: @escaping (Post) -> Void = { _ in }) -> CreatePostViewModel {
        CreatePostViewModel(
            capturedImage: UIImage(named: MockImages.postImage(at: 0)) ?? UIImage(),
            capturedLocation: PostLocation(
                latitude: PreviewMockRegion.center.latitude,
                longitude: PreviewMockRegion.center.longitude
            ),
            createPost: CreatePostUseCase(postRepository: MockPostRepository()),
            locationCaptureService: nil,
            onComplete: onComplete
        )
    }
}
#endif
