//
//  FetchMapOverlaysUseCase.swift
//  matiapu
//

import Foundation

struct MapOverlays: Sendable {
    let shelters: [Shelter]
    let disasters: [Disaster]
}

struct FetchMapOverlaysUseCase: Sendable {
    private let shelterRepository: any ShelterRepository
    private let disasterRepository: any DisasterRepository

    init(
        shelterRepository: any ShelterRepository,
        disasterRepository: any DisasterRepository
    ) {
        self.shelterRepository = shelterRepository
        self.disasterRepository = disasterRepository
    }

    func execute(scope: MapMunicipalityScope?) async -> MapOverlays {
        let municipality = scope?.name
        let boundary = scope?.boundary

        let loadedShelters = (try? await shelterRepository.getShelters(municipality: municipality)) ?? []
        let shelters = MapMunicipalityFilter.shelters(
            loadedShelters,
            municipality: municipality,
            boundary: boundary
        )

        var disasters = (try? await disasterRepository.getDisasters(within: boundary?.boundingBox)) ?? []
        disasters = MapMunicipalityFilter.disasters(disasters, within: boundary)

        return MapOverlays(shelters: shelters, disasters: disasters)
    }
}
