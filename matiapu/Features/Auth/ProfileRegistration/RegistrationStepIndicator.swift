//
//  RegistrationStepIndicator.swift
//  matiapu
//

import SwiftUI

struct RegistrationStepIndicator: View {
    let currentStep: Int

    private let labels = ["認証", "プロフィール", "完了"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                let step = index + 1
                HStack(spacing: 0) {
                    stepNode(step: step, label: label)

                    if step < labels.count {
                        connector(isCompleted: currentStep > step)
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.authHorizontal)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private func stepNode(step: Int, label: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(circleColor(for: step))
                    .frame(width: 32, height: 32)

                if currentStep > step {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(step)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(step == currentStep ? .white : AppColors.authSubtitle)
                }
            }

            Text(label)
                .font(.system(size: 12, weight: step == currentStep ? .bold : .regular))
                .foregroundStyle(step <= currentStep ? AppColors.authHeading : AppColors.authSubtitle)
        }
        .frame(maxWidth: .infinity)
    }

    private func connector(isCompleted: Bool) -> some View {
        Rectangle()
            .fill(isCompleted ? AppColors.authPrimary : AppColors.authDivider)
            .frame(height: 2)
            .frame(maxWidth: 48)
            .padding(.bottom, 24)
    }

    private func circleColor(for step: Int) -> Color {
        if currentStep > step {
            AppColors.authPrimaryAction
        } else if currentStep == step {
            AppColors.authPrimary
        } else {
            AppColors.authInputBackground
        }
    }
}
