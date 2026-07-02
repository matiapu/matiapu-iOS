//
//  PostViewModel.swift
//  matiapu
//

import CoreLocation
import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class PostViewModel {
    private(set) var post: Post?
    var detailPost: Post?
    private(set) var isCameraPresented = false
    private(set) var capturedImage: UIImage?
    private(set) var capturedLocation: PostLocation?
    private(set) var createPostViewModel: CreatePostViewModel?
    var showMatchAlert = false
    var matchedPartnerName: String?
    private(set) var isLoading = false

    var onPostCreated: ((Post) async -> Void)?
    var onMatched: ((ChatConversation) async -> Void)?

    private var swipeQueue = PostSwipeQueue()
    private let fetchFeedPosts: FetchFeedPostsUseCase
    private let recordPostSwipe: RecordPostSwipeUseCase
    private let createPost: CreatePostUseCase
    private var locationCaptureService: LocationCaptureService?

    init(useCases: AppUseCases, initialQueue: [Post]? = nil) {
        self.fetchFeedPosts = useCases.fetchFeedPosts
        self.recordPostSwipe = useCases.recordPostSwipe
        self.createPost = useCases.createPost
        if let initialQueue {
            swipeQueue = PostSwipeQueue(candidates: initialQueue)
            post = swipeQueue.current
        }
    }

    func loadPosts() async {
        guard swipeQueue.isEmpty, post == nil, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let candidates = (try? await fetchFeedPosts.execute()) ?? []
        swipeQueue = PostSwipeQueue(candidates: candidates)
        post = swipeQueue.current
    }

    func handleSwipe(_ action: PostSwipeAction) {
        guard let current = post else { return }

        detailPost = nil
        if swipeQueue.advance(with: action) != nil {
            Task {
                guard let outcome = try? await recordPostSwipe.execute(post: current, action: action) else { return }
                if case .matched(let conversation) = outcome {
                    matchedPartnerName = conversation.partnerName
                    showMatchAlert = true
                    await onMatched?(conversation)
                }
            }
        }
        post = swipeQueue.current
    }

    func dismissMatchAlert() {
        showMatchAlert = false
        matchedPartnerName = nil
    }

    func openDetail() {
        detailPost = post
    }

    func openCreatePost() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        locationService.prepareForCapture()
        isCameraPresented = true
    }

    func handleCapturedImage(_ image: UIImage, coordinate: CLLocationCoordinate2D?) {
        isCameraPresented = false

        Task {
            let location = await locationService.acquireCoordinate(
                photoCoordinate: coordinate,
                timeout: 12
            )

            capturedImage = image
            capturedLocation = location

            createPostViewModel = CreatePostViewModel(
                capturedImage: image,
                capturedLocation: location,
                createPost: createPost,
                locationCaptureService: locationService,
                onComplete: { [weak self] createdPost in
                    guard let self else { return }
                    self.dismissCreatePost()
                    Task {
                        await self.onPostCreated?(createdPost)
                    }
                }
            )
        }
    }

    func cancelCamera() {
        locationService.stopCapture()
        isCameraPresented = false
    }

    func dismissCreatePost() {
        locationService.stopCapture()
        capturedImage = nil
        capturedLocation = nil
        createPostViewModel = nil
    }

    private var locationService: LocationCaptureService {
        if locationCaptureService == nil {
            locationCaptureService = LocationCaptureService()
        }
        return locationCaptureService!
    }
}

#if DEBUG
extension PostViewModel {
    static var preview: PostViewModel {
        PostViewModel(
            useCases: AppUseCases.make(from: .live),
            initialQueue: PostPreviewData.feedCandidates
        )
    }
}
#endif
