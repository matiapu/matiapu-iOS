//
//  ChatRoomComponents.swift
//  matiapu
//

import SwiftUI

struct ChatMessageSection: Identifiable {
    let id: String
    let dateLabel: String
    let messages: [ChatMessage]
}

enum ChatMessageGrouper {
    static func sections(from messages: [ChatMessage]) -> [ChatMessageSection] {
        let calendar = Calendar.current
        var sections: [ChatMessageSection] = []
        var currentDay: Date?
        var currentMessages: [ChatMessage] = []

        for message in messages {
            let day = calendar.startOfDay(for: message.sentAt)
            if currentDay != day {
                if let currentDay, !currentMessages.isEmpty {
                    sections.append(
                        ChatMessageSection(
                            id: sectionID(for: currentDay),
                            dateLabel: dateLabel(for: currentDay),
                            messages: currentMessages
                        )
                    )
                }
                currentDay = day
                currentMessages = [message]
            } else {
                currentMessages.append(message)
            }
        }

        if let currentDay, !currentMessages.isEmpty {
            sections.append(
                ChatMessageSection(
                    id: sectionID(for: currentDay),
                    dateLabel: dateLabel(for: currentDay),
                    messages: currentMessages
                )
            )
        }

        return sections
    }

    private static func sectionID(for day: Date) -> String {
        ISO8601DateFormatter().string(from: day)
    }

    private static func dateLabel(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) {
            return "今日"
        }
        if calendar.isDateInYesterday(day) {
            return "昨日"
        }
        return day.formatted(.dateTime.year().month().day())
    }
}

struct ChatDateSeparator: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.chatDateSeparatorBackground)
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }
}

struct ChatIncomingMessageRow: View {
    let message: ChatMessage
    let partnerProfileImageURL: String?

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ProfileAvatarView(imageURL: partnerProfileImageURL, size: AppSize.chatAvatar)

            HStack(alignment: .bottom, spacing: 6) {
                ChatMessageBubble(text: message.text, direction: .incoming)
                ChatMessageTimestamp(message.sentAt)
            }

            Spacer(minLength: 32)
        }
    }
}

struct ChatOutgoingMessageRow: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            Spacer(minLength: 48)

            VStack(alignment: .trailing, spacing: 2) {
                Text("既読")
                    .font(.caption2)
                    .foregroundStyle(AppColors.chatTimestamp)
                ChatMessageTimestamp(message.sentAt)
            }

            ChatMessageBubble(text: message.text, direction: .outgoing)
        }
    }
}

private struct ChatMessageTimestamp: View {
    let date: Date

    init(_ date: Date) {
        self.date = date
    }

    var body: some View {
        Text(date, format: .dateTime.hour().minute())
            .font(.caption2)
            .foregroundStyle(AppColors.chatTimestamp)
            .lineLimit(1)
    }
}

private struct ChatMessageBubble: View {
    enum Direction {
        case incoming
        case outgoing
    }

    let text: String
    let direction: Direction

    var body: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(.black)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                bubbleShape
                    .fill(direction == .incoming ? AppColors.chatIncomingBubble : AppColors.chatOutgoingBubble)
            )
    }

    private var bubbleShape: UnevenRoundedRectangle {
        switch direction {
        case .incoming:
            UnevenRoundedRectangle(
                topLeadingRadius: AppSize.chatBubbleRadius,
                bottomLeadingRadius: AppSize.chatBubbleTailRadius,
                bottomTrailingRadius: AppSize.chatBubbleRadius,
                topTrailingRadius: AppSize.chatBubbleRadius,
                style: .continuous
            )
        case .outgoing:
            UnevenRoundedRectangle(
                topLeadingRadius: AppSize.chatBubbleRadius,
                bottomLeadingRadius: AppSize.chatBubbleRadius,
                bottomTrailingRadius: AppSize.chatBubbleTailRadius,
                topTrailingRadius: AppSize.chatBubbleRadius,
                style: .continuous
            )
        }
    }
}

struct ChatInputBar: View {
    @Binding var text: String
    let onSend: () -> Void

    private var isDraftEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: AppSpacing.settingsProfileCardSpacing) {
            TextField("", text: $text, prompt: prompt, axis: .vertical)
                .font(AppTypography.settingsEditField)
                .foregroundStyle(AppColors.settingsCardText)
                .lineLimit(1...4)
                .padding(.horizontal, AppSpacing.createPostFieldHorizontal)
                .frame(minHeight: AppSize.createPostTitleFieldHeight)
                .background(
                    Capsule(style: .continuous)
                        .fill(AppColors.settingsCardBackground)
                )

            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(AppTypography.fabIcon)
                    .foregroundStyle(AppColors.onTagText)
                    .frame(width: AppSize.fab, height: AppSize.fab)
                    .background(
                        Circle()
                            .fill(AppColors.postTag)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isDraftEmpty)
            .opacity(isDraftEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, AppSpacing.settingsHorizontal)
        .padding(.vertical, AppSpacing.settingsContentTop)
        .padding(.bottom, AppSpacing.screenTop)
    }

    private var prompt: Text {
        Text("メッセージを入力")
            .font(AppTypography.settingsEditField)
            .foregroundStyle(AppColors.settingsSearchPlaceholder)
    }
}
