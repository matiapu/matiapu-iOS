//
//  MapShelterCalloutView.swift
//  matiapu
//

import CoreLocation
import SwiftUI

struct MapShelterCalloutView: View {
    let shelter: Shelter

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.mapCalloutSpacing) {
            Label(shelter.shelterName, systemImage: "house.fill")
                .font(AppTypography.mapCalloutTitle)
                .foregroundStyle(AppColors.postDetailText)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let capacity = shelter.capacity {
                Text("収容人数: 約\(capacity)人")
                    .font(AppTypography.cardBody)
                    .foregroundStyle(AppColors.postDetailSecondaryText)
            }
        }
        .padding(AppSpacing.mapCalloutPadding)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.mapCallout, style: .continuous)
                .fill(AppColors.postDetailBackground)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.bottom, AppSpacing.mapCalloutBottom)
    }
}

#Preview {
    MapShelterCalloutView(
        shelter: Shelter(
            id: "preview",
            shelterName: "新宿区役所",
            latitude: PreviewMockRegion.center.latitude,
            longitude: PreviewMockRegion.center.longitude,
            capacity: 500,
            municipality: PreviewMockRegion.municipalityName
        )
    )
}