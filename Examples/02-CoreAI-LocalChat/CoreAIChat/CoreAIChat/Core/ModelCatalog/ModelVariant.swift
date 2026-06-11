import Foundation

struct ModelVariant: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let family: String
    let format: String
    let quantization: String
    let fileName: String
    let contextWindow: Int
    let estimatedSize: String?
    let description: String
    let expectedSizeBytes: Int?
    let isBundled: Bool
    let downloadSupported: Bool
    let downloadURL: String?
    let artifactFileName: String?
    let artifactType: String?
    let sha256: String?
    let minimumOS: String?
    let supportedDevices: [String]?

    init(
        id: String,
        name: String,
        family: String,
        format: String,
        quantization: String,
        fileName: String,
        contextWindow: Int,
        estimatedSize: String? = nil,
        description: String,
        expectedSizeBytes: Int? = nil,
        isBundled: Bool = false,
        downloadSupported: Bool = false,
        downloadURL: String? = nil,
        artifactFileName: String? = nil,
        artifactType: String? = nil,
        sha256: String? = nil,
        minimumOS: String? = nil,
        supportedDevices: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.family = family
        self.format = format
        self.quantization = quantization
        self.fileName = fileName
        self.contextWindow = contextWindow
        self.estimatedSize = estimatedSize
        self.description = description
        self.expectedSizeBytes = expectedSizeBytes
        self.isBundled = isBundled
        self.downloadSupported = downloadSupported
        self.downloadURL = downloadURL
        self.artifactFileName = artifactFileName
        self.artifactType = artifactType
        self.sha256 = sha256
        self.minimumOS = minimumOS
        self.supportedDevices = supportedDevices
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case family
        case format
        case quantization
        case fileName
        case contextWindow
        case estimatedSize
        case description
        case expectedSizeBytes
        case isBundled
        case downloadSupported
        case downloadURL
        case artifactFileName
        case artifactType
        case sha256
        case minimumOS
        case supportedDevices
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        family = try container.decode(String.self, forKey: .family)
        format = try container.decode(String.self, forKey: .format)
        quantization = try container.decode(String.self, forKey: .quantization)
        fileName = try container.decode(String.self, forKey: .fileName)
        contextWindow = try container.decode(Int.self, forKey: .contextWindow)
        estimatedSize = try container.decodeIfPresent(String.self, forKey: .estimatedSize)
        description = try container.decode(String.self, forKey: .description)
        expectedSizeBytes = try container.decodeIfPresent(Int.self, forKey: .expectedSizeBytes)
        isBundled = try container.decodeIfPresent(Bool.self, forKey: .isBundled) ?? false
        downloadSupported = try container.decodeIfPresent(Bool.self, forKey: .downloadSupported) ?? false
        downloadURL = try container.decodeIfPresent(String.self, forKey: .downloadURL)
        artifactFileName = try container.decodeIfPresent(String.self, forKey: .artifactFileName)
        artifactType = try container.decodeIfPresent(String.self, forKey: .artifactType)
        sha256 = try container.decodeIfPresent(String.self, forKey: .sha256)
        minimumOS = try container.decodeIfPresent(String.self, forKey: .minimumOS)
        supportedDevices = try container.decodeIfPresent([String].self, forKey: .supportedDevices)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(family, forKey: .family)
        try container.encode(format, forKey: .format)
        try container.encode(quantization, forKey: .quantization)
        try container.encode(fileName, forKey: .fileName)
        try container.encode(contextWindow, forKey: .contextWindow)
        try container.encodeIfPresent(estimatedSize, forKey: .estimatedSize)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(expectedSizeBytes, forKey: .expectedSizeBytes)
        try container.encode(isBundled, forKey: .isBundled)
        try container.encode(downloadSupported, forKey: .downloadSupported)
        try container.encodeIfPresent(downloadURL, forKey: .downloadURL)
        try container.encodeIfPresent(artifactFileName, forKey: .artifactFileName)
        try container.encodeIfPresent(artifactType, forKey: .artifactType)
        try container.encodeIfPresent(sha256, forKey: .sha256)
        try container.encodeIfPresent(minimumOS, forKey: .minimumOS)
        try container.encodeIfPresent(supportedDevices, forKey: .supportedDevices)
    }
}
