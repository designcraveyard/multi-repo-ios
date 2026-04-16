import Foundation

// MARK: - Pokemon Card

struct PokemonCardData: Codable, Identifiable {
    let name: String
    let id: Int
    let sprite: String
    let types: [String]
    let stats: [PokemonStat]
    let abilities: [String]
    let height: Double
    let weight: Double
}

struct PokemonStat: Codable {
    let name: String
    let value: Int
}

// MARK: - Evolution Card

struct EvolutionCardData: Codable {
    let chain: [EvolutionStage]
}

struct EvolutionStage: Codable, Identifiable {
    let name: String
    let id: Int
    let sprite: String
    let trigger: String
}

// MARK: - Type Matchup Card

struct TypeMatchupCardData: Codable {
    let pokemon: String
    let weaknesses: [TypeMultiplier]
    let resistances: [TypeMultiplier]
    let immunities: [String]
}

struct TypeMultiplier: Codable {
    let type: String
    let multiplier: Double
}

// MARK: - Team Card

struct TeamCardData: Codable {
    let team: [TeamMember]
    let coverage: TeamCoverage
}

struct TeamMember: Codable, Identifiable {
    let name: String
    let id: Int
    let sprite: String
    let types: [String]
    let role: String
}

struct TeamCoverage: Codable {
    let uncovered: [String]
    let doubleResisted: [String]
}
