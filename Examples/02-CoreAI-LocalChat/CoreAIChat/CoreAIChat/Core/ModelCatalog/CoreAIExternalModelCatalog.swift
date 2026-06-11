//
//  CoreAIExternalModelCatalog.swift
//  CoreAIChat
//
//  Generic schema-v3 model catalog for external Core AI model profiles.
//
//  Intended location:
//  Examples/02-CoreAI-LocalChat/CoreAIChat/CoreAIChat/Core/ModelCatalog/CoreAIExternalModelCatalog.swift
//
//  Notes:
//  - This file only models metadata/runtime profiles.
//  - It does not implement tokenization, sampling, Core AI execution, image preprocessing, or download logic.
//  - Unknown/unchecked downloadURL and sha256 values should remain nil until verified.
//

import Foundation

// MARK: - Catalog

struct CoreAIExternalModelCatalog: Codable, Equatable {
    var schemaVersion: Int
    var catalogId: String
    var catalogName: String
    var catalogVersion: String
    var description: String
    var sourcePolicy: CoreAIExternalCatalogSourcePolicy
    var defaultGeneration: CoreAIExternalDefaultGeneration
    var models: [CoreAIExternalModelProfile]

    var textModels: [CoreAIExternalModelProfile] {
        models.filter { $0.capabilities.supportsTextChat }
    }

    var visionLanguageModels: [CoreAIExternalModelProfile] {
        models.filter { $0.capabilities.supportsImageTextToText || $0.capabilities.supportsImageUpload }
    }

    var modelsRequiringRuntimeAdapter: [CoreAIExternalModelProfile] {
        models.filter { $0.runtime.status == .adapterRequired }
    }
}

struct CoreAIExternalCatalogSourcePolicy: Codable, Equatable {
    var artifactRedistribution: String
    var checksumPolicy: String
    var manualInstallPolicy: String
    var runtimePolicy: String
}

struct CoreAIExternalDefaultGeneration: Codable, Equatable {
    var contextWindow: Int
    var maxOutputTokens: Int
    var temperature: Double
    var topP: Double
    var repetitionPenalty: Double?
}

// MARK: - Model Profile

struct CoreAIExternalModelProfile: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var family: String
    var modelSeries: String
    var displayCategory: String
    var parameterScale: String
    var architecture: String
    var license: String
    var description: String
    var source: CoreAIExternalModelSource
    var capabilities: CoreAIModelCapabilities
    var artifacts: [CoreAIModelArtifact]
    var tokenizer: CoreAITokenizerProfile
    var generation: CoreAIGenerationProfile
    var vision: CoreAIVisionProfile?
    var runtime: CoreAIRuntimeProfile
    var devicePolicy: CoreAIDevicePolicy
    var performance: CoreAIPerformanceProfile?

    var requiredArtifacts: [CoreAIModelArtifact] {
        artifacts.filter(\.required)
    }

    var estimatedTotalSizeBytes: Int64? {
        let sizes = requiredArtifacts.compactMap(\.expectedSizeBytes)
        guard sizes.count == requiredArtifacts.count else { return nil }
        return sizes.reduce(0, +)
    }

    var hasImageInput: Bool {
        capabilities.supportsImageUpload || capabilities.supportsImageTextToText
    }

    var isTextOnly: Bool {
        capabilities.supportsTextToText && !hasImageInput
    }

    var canBeUsedByCurrentRuntime: Bool {
        runtime.status == .ready || runtime.status == .experimental
    }

    var shouldDisableSetActiveButton: Bool {
        runtime.status == .adapterRequired || runtime.status == .unsupported
    }
}

struct CoreAIExternalModelSource: Codable, Equatable {
    var provider: String
    var repositoryURL: URL
    var modelCardURL: URL
    var upstreamModelURL: URL?
    var zooCardURL: URL?
    var licenseURL: URL?
}

// MARK: - Capabilities

struct CoreAIModelCapabilities: Codable, Equatable {
    var modalities: [CoreAIModelModality]
    var inputModes: [CoreAIModelInputMode]
    var outputModes: [CoreAIModelOutputMode]

    var supportsTextChat: Bool
    var supportsImageUpload: Bool
    var supportsTextToText: Bool
    var supportsImageToText: Bool
    var supportsImageTextToText: Bool
    var supportsTextToImage: Bool
    var supportsImageToImage: Bool
    var supportsEmbedding: Bool
    var supportsReranking: Bool
    var supportsObjectDetection: Bool
    var supportsStreaming: Bool
    var supportsRAG: Bool
    var supportsToolCalling: Bool?
}

enum CoreAIModelModality: String, Codable, Equatable {
    case text
    case image
    case audio
    case video
}

enum CoreAIModelInputMode: String, Codable, Equatable {
    case text
    case image
    case imageText
    case audio
    case textImage
    case embeddingInput
}

enum CoreAIModelOutputMode: String, Codable, Equatable {
    case text
    case image
    case embedding
    case classification
    case detections
}

// MARK: - Artifacts

struct CoreAIModelArtifact: Codable, Equatable, Identifiable {
    var id: String
    var role: CoreAIArtifactRole
    var format: CoreAIArtifactFormat
    var repositorySubpath: String?
    var manualInstallDirectoryName: String
    var fileName: String
    var downloadURL: URL?
    var expectedSizeBytes: Int64?
    var sha256: String?
    var required: Bool
    var notes: [String]

    var isAutomaticDownloadReady: Bool {
        downloadURL != nil && sha256?.isEmpty == false
    }

    var isManualInstallOnly: Bool {
        downloadURL == nil
    }
}

enum CoreAIArtifactRole: String, Codable, Equatable {
    case languageBundle
    case languageDecoder
    case visionEncoder
    case frontendGather
    case tokenizer
    case metadata
    case configuration
    case weights
}

enum CoreAIArtifactFormat: String, Codable, Equatable {
    case aimodel
    case aimodelBundle
    case aimodelLanguageBundle
    case rawTableBundle
    case aimodelOrRawTableBundle
    case zipArchive
    case directory
}

// MARK: - Tokenizer / Generation / Vision

struct CoreAITokenizerProfile: Codable, Equatable {
    var source: String
    var type: String
    var chatTemplate: String
    var tokenizerFiles: [String]
    var stopTokenIds: [Int]
    var stopStrings: [String]
    var notes: [String]
}

struct CoreAIGenerationProfile: Codable, Equatable {
    var defaultContextWindow: Int
    var maxContextWindow: Int?
    var maxOutputTokens: Int
    var temperature: Double
    var topP: Double
    var topK: Int?
    var doSample: Bool
    var greedySupported: Bool
}

struct CoreAIVisionProfile: Codable, Equatable {
    var imageInputSupported: Bool
    var imageSize: Int?
    var imageTokenCount: Int?
    var imagePlaceholderToken: String?
    var preprocessing: String?
    var visionEncoderRunsPerImage: Int?
    var notes: [String]
}

// MARK: - Runtime

struct CoreAIRuntimeProfile: Codable, Equatable {
    var adapter: CoreAIRuntimeAdapter
    var status: CoreAIRuntimeStatus
    var engine: String
    var functionName: String
    var inputNames: [String]
    var outputNames: [String]
    var stateNames: [String]
    var preferredCompute: CoreAIComputePreference
    var requiresCustomMetalKernels: Bool
    var requiresCoreAIModelsPatches: Bool
    var requiredRuntimeFlags: [CoreAIRuntimeFlag]
    var requiresIncreasedMemoryEntitlement: Bool?
    var notes: [String]

    // Used by some vision-language profiles where image embeddings are bound as static inputs.
    var staticInputNames: [String]?
}

enum CoreAIRuntimeAdapter: String, Codable, Equatable {
    case coreaiPipelinedNStateText
    case coreaiPipelinedExtraStateText
    case gemma4MultiStagePipelinedText
    case coreaiPipelinedVisionLanguage
    case coreaiStandardLanguageModel
    case mock
    case unknown
}

enum CoreAIRuntimeStatus: String, Codable, Equatable {
    case ready
    case experimental
    case adapterRequired
    case unsupported
}

enum CoreAIComputePreference: String, Codable, Equatable {
    case automatic
    case cpu
    case gpu
    case neuralEngine
}

struct CoreAIRuntimeFlag: Codable, Equatable {
    var name: String
    var value: String
    var reason: String
}

// MARK: - Device / Performance

struct CoreAIDevicePolicy: Codable, Equatable {
    var iPhone: CoreAIDeviceSupportLevel
    var iPad: CoreAIDeviceSupportLevel
    var Mac: CoreAIDeviceSupportLevel
    var minimumOS: CoreAIMinimumOS
    var notes: [String]
}

enum CoreAIDeviceSupportLevel: String, Codable, Equatable {
    case supported
    case supportedWithHighMemory
    case macRecommended
    case recommended
    case unsupported
    case unknown
}

struct CoreAIMinimumOS: Codable, Equatable {
    var iOS: String?
    var iPadOS: String?
    var macOS: String?
}

struct CoreAIPerformanceProfile: Codable, Equatable {
    var macOSM4MaxGPUDecodeTokPerSec: CoreAIJSONScalar?
    var iPhone17ProGPUDecodeTokPerSec: CoreAIJSONScalar?
    var iPhone17ProANEDecodeTokPerSec: CoreAIJSONScalar?
    var visionEncodeLatencyMs: CoreAIJSONScalar?
    var benchmarkNotes: String
}

// MARK: - Flexible JSON Scalar

enum CoreAIJSONScalar: Codable, Equatable, CustomStringConvertible {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    var description: String {
        switch self {
        case .string(let value): return value
        case .int(let value): return String(value)
        case .double(let value): return String(value)
        case .bool(let value): return String(value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            throw DecodingError.typeMismatch(
                CoreAIJSONScalar.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected String, Int, Double, or Bool."
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        }
    }
}

// MARK: - Loader

enum CoreAIExternalModelCatalogLoader {
    enum LoaderError: Error, LocalizedError {
        case missingResource(name: String, extension: String)

        var errorDescription: String? {
            switch self {
            case .missingResource(let name, let ext):
                return "Missing bundled catalog resource: \(name).\(ext)"
            }
        }
    }

    static func loadBundled(
        resourceName: String = "external_coreai_model_catalog_v3",
        fileExtension: String = "json",
        subdirectory: String? = "Resources/ModelManifest",
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> CoreAIExternalModelCatalog {
        guard let url = bundle.url(forResource: resourceName, withExtension: fileExtension, subdirectory: subdirectory) else {
            throw LoaderError.missingResource(name: resourceName, extension: fileExtension)
        }

        let data = try Data(contentsOf: url)
        return try decoder.decode(CoreAIExternalModelCatalog.self, from: data)
    }

    static func decode(
        data: Data,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> CoreAIExternalModelCatalog {
        try decoder.decode(CoreAIExternalModelCatalog.self, from: data)
    }
}
