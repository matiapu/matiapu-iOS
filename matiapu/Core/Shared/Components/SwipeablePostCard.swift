//
//  SwipeablePostCard.swift
//  matiapu
//

import SwiftUI

struct SwipeablePostCard: View {
    let post: Post
    let display: PostCardDisplay
    var isBodyExpanded: Bool = true
    var onSeeMore: () -> Void = {}
    let onSwipe: (PostSwipeAction) -> Void

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0

    var body: some View {
        PostCardView(
            post: post,
            display: display,
            isBodyExpanded: isBodyExpanded,
            onSeeMore: onSeeMore
        )
        .overlay {
            swipeStampOverlay
        }
        .contentShape(
            RoundedRectangle(cornerRadius: AppRadius.postCard, style: .continuous)
        )
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .highPriorityGesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: PostSwipeMetrics.dragMinimumDistance)
            .onChanged { value in
                offset = value.translation
                rotation = Double(value.translation.width / 18)
            }
            .onEnded { value in
                switch PostSwipeDecision.from(translation: value.translation) {
                case .committed(let action):
                    completeSwipe(action, translation: value.translation)
                case .cancelled:
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        resetDragState()
                    }
                }
            }
    }

    @ViewBuilder
    private var swipeStampOverlay: some View {
        if let kind = PostSwipeStampKind.from(translation: offset) {
            swipeStamp(
                kind: kind,
                opacity: PostSwipeMetrics.stampOpacity(for: offset),
                scale: PostSwipeMetrics.stampScale(for: offset)
            )
        }
    }

    private func swipeStamp(kind: PostSwipeStampKind, opacity: Double, scale: CGFloat) -> some View {
        let alignment: Alignment = switch kind.placement {
        case .bottom: .bottom
        case .topLeading: .topLeading
        case .topTrailing: .topTrailing
        }

        return ZStack {
            Circle()
                .fill(stampBackgroundColor(for: kind))
                .frame(
                    width: PostSwipeMetrics.stampCircleSize,
                    height: PostSwipeMetrics.stampCircleSize
                )
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)

            Image(systemName: kind.symbolName)
                .font(.system(size: PostSwipeMetrics.stampSymbolSize, weight: .bold))
                .foregroundStyle(AppColors.swipeStampIcon)
        }
        .opacity(opacity)
        .scaleEffect(scale)
        .rotationEffect(.degrees(-rotation))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        .padding(28)
        .allowsHitTesting(false)
        .animation(.easeOut(duration: 0.12), value: opacity)
    }

    private func stampBackgroundColor(for kind: PostSwipeStampKind) -> Color {
        switch kind {
        case .empathy:
            return AppColors.swipeStampEmpathy
        case .skipLeft:
            return AppColors.swipeStampSkip
        case .skipDown:
            return AppColors.swipeStampSkipDown
        }
    }

    private func completeSwipe(_ action: PostSwipeAction, translation: CGSize) {
        let exitOffset: CGSize
        let exitRotation: Double

        switch action {
        case .empathy:
            exitOffset = CGSize(width: 600, height: translation.height)
            exitRotation = 14
        case .skip:
            if translation.height > abs(translation.width) {
                exitOffset = CGSize(width: translation.width, height: 800)
                exitRotation = 0
            } else {
                exitOffset = CGSize(width: -600, height: translation.height)
                exitRotation = -14
            }
        }

        withAnimation(.easeIn(duration: 0.22)) {
            offset = exitOffset
            rotation = exitRotation
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            onSwipe(action)
            resetDragState()
        }
    }

    private func resetDragState() {
        offset = .zero
        rotation = 0
    }
}

#Preview {
    SwipeablePostCard(
        post: PostPreviewData.match,
        display: .match,
        onSwipe: { _ in }
    )
    .padding()
}
