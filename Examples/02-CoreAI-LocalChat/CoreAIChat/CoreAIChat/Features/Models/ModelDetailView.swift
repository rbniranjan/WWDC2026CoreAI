import SwiftUI

struct ModelDetailView: View {
    let reference: CatalogModelReference
    @ObservedObject var viewModel: ModelLibraryViewModel

    private var internalModel: ModelVariant? {
        viewModel.internalModel(for: reference)
    }

    private var externalModel: CoreAIExternalModelProfile? {
        viewModel.externalModel(for: reference)
    }

    var body: some View {
        ScrollView {
            if let model = internalModel {
                internalDetail(for: model)
            } else if let model = externalModel {
                externalDetail(for: model)
            } else {
                EmptyStateView(
                    title: "Model not found",
                    message: "Reload the catalog and try again.",
                    systemImage: "exclamationmark.triangle"
                )
                .padding(AppSpacing.xl)
            }
        }
        .background(AppColors.background)
        .navigationTitle(internalModel?.name ?? externalModel?.name ?? "Model")
    }

    private func internalDetail(for model: ModelVariant) -> some View {
        let isAvailable = viewModel.isAvailable(model)
        let downloadState = viewModel.downloadState(for: model)

        return VStack(alignment: .leading, spacing: AppSpacing.lg) {
            CardView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack(alignment: .top, spacing: AppSpacing.md) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text(model.name)
                                .font(.largeTitle.bold())
                                .lineLimit(3)
                                .minimumScaleFactor(0.75)
                            Text(model.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if viewModel.isActive(reference) {
                            StatusBadgeView(title: "Active", systemImage: "checkmark.seal.fill", tint: Color.accentColor)
                        }
                    }

                    HStack(spacing: AppSpacing.sm) {
                        ModelAvailabilityBadge(availability: viewModel.availability(for: model))
                        StatusBadgeView(
                            title: downloadState.displayText,
                            systemImage: model.downloadSupported ? "arrow.down.circle" : "hand.raised",
                            tint: model.downloadSupported ? Color.accentColor : AppColors.neutral
                        )
                    }
                }
            }

            if !isAvailable {
                CardView(background: AppColors.warning.opacity(0.12)) {
                    Label("This model is not runtime-ready. Chat will use the mock runtime until a matching local `.aimodel` is available.", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.warning)
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Actions", subtitle: "Set the active model or manage a downloadable artifact.")

                    Button {
                        viewModel.setActive(model)
                    } label: {
                        Label("Set Active Model", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isAvailable)

                    internalDownloadActions(for: model, state: downloadState)
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Model Metadata", subtitle: "Values come from the bundled manifest.")
                    LazyVGrid(columns: metadataColumns, alignment: .leading, spacing: AppSpacing.md) {
                        metadataItem("Family", model.family)
                        metadataItem("Format", model.format)
                        metadataItem("Quantization", model.quantization)
                        metadataItem("Context window", "\(model.contextWindow) tokens")
                        metadataItem("Expected size", expectedSizeText(for: model))
                        metadataItem("Artifact type", model.artifactType ?? "Manual .aimodel")
                        metadataItem("Checksum", model.sha256 == nil ? "Not provided" : "SHA-256 provided")
                        metadataItem("Local availability", viewModel.availability(for: model).displayText)
                        metadataItem("Download state", downloadState.displayText)
                        metadataItem("Manifest source", viewModel.manifestSource.rawValue)
                        metadataItem("Minimum OS", model.minimumOS ?? "Not specified")
                        metadataItem("Supported devices", model.supportedDevices?.joined(separator: ", ") ?? "Not specified")
                    }
                }
            }

            if !model.downloadSupported {
                CardView {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Label("Manual .aimodel required", systemImage: "folder.badge.questionmark")
                            .font(.headline)
                        Text("Copy `\(model.fileName)` into `CoreAIChat/Resources/AIModels/`. The file name must match the manifest entry exactly.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: AppSpacing.readableMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity)
    }

    private func externalDetail(for model: CoreAIExternalModelProfile) -> some View {
        let preflight = viewModel.preflight(for: model)
        let artifacts = viewModel.resolvedArtifacts(for: model)
        let missingArtifacts = viewModel.missingRequiredArtifacts(for: model)

        return VStack(alignment: .leading, spacing: AppSpacing.lg) {
            CardView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack(alignment: .top, spacing: AppSpacing.md) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text(model.name)
                                .font(.largeTitle.bold())
                                .lineLimit(3)
                                .minimumScaleFactor(0.75)
                            Text(model.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        StatusBadgeView(title: "External", systemImage: "globe", tint: Color.accentColor)
                    }

                    badgeScroller {
                        externalCapabilityBadges(model: model, preflight: preflight)
                    }

                    HStack(spacing: AppSpacing.sm) {
                        StatusBadgeView(
                            title: preflight.readiness.displayTitle,
                            systemImage: preflight.readiness.systemImage,
                            tint: preflight.readiness.tint
                        )
                        StatusBadgeView(title: model.license, systemImage: "doc.text", tint: AppColors.neutral)
                    }
                }
            }

            if !missingArtifacts.isEmpty {
                CardView(background: AppColors.warning.opacity(0.12)) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Label("Missing artifact files", systemImage: "shippingbox.fill")
                            .font(.headline)
                            .foregroundStyle(AppColors.warning)
                        Text(missingArtifacts.map(\.manualInstallDirectoryName).joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Preflight", subtitle: "Runner readiness comes from `CoreAIModelRunnerRegistry.knownExternalModelRegistry()`.")
                    HStack(spacing: AppSpacing.sm) {
                        StatusBadgeView(
                            title: preflight.readiness.displayTitle,
                            systemImage: preflight.readiness.systemImage,
                            tint: preflight.readiness.tint
                        )
                        StatusBadgeView(title: preflight.runnerName, systemImage: "gearshape.2", tint: AppColors.neutral)
                    }

                    if let inspection = preflight.bundleInspection {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            StatusBadgeView(
                                title: inspection.inspectorName,
                                systemImage: "shippingbox",
                                tint: AppColors.neutral
                            )

                            ForEach(inspection.checks) { check in
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    HStack(spacing: AppSpacing.sm) {
                                        StatusBadgeView(
                                            title: check.isSatisfied ? "Found" : "Missing",
                                            systemImage: check.isSatisfied ? "checkmark.circle.fill" : "xmark.octagon.fill",
                                            tint: check.isSatisfied ? AppColors.success : AppColors.warning
                                        )
                                        Text(check.title)
                                            .font(.subheadline.weight(.semibold))
                                    }

                                    Text(inspectionPathText(for: check))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    ForEach(preflight.findings) { finding in
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            HStack(spacing: AppSpacing.sm) {
                                StatusBadgeView(
                                    title: finding.severity.displayTitle,
                                    systemImage: finding.severity.systemImage,
                                    tint: finding.severity.tint
                                )
                                Text(finding.code)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(finding.message)
                                .font(.subheadline)
                            if let remediation = finding.remediation {
                                Text(remediation)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Source And License")
                    metadataItem("License", model.license)
                    metadataItem("Provider", model.source.provider)
                    linkItem("Repository", model.source.repositoryURL)
                    linkItem("Model Card", model.source.modelCardURL)
                    if let upstreamURL = model.source.upstreamModelURL {
                        linkItem("Upstream", upstreamURL)
                    }
                    if let zooCardURL = model.source.zooCardURL {
                        linkItem("Zoo Card", zooCardURL)
                    }
                    if let licenseURL = model.source.licenseURL {
                        linkItem("License URL", licenseURL)
                    }
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Capabilities")
                    metadataItem("Modalities", model.capabilities.modalities.map(\.displayTitle).joined(separator: ", "))
                    metadataItem("Input modes", model.capabilities.inputModes.map(\.displayTitle).joined(separator: ", "))
                    metadataItem("Output modes", model.capabilities.outputModes.map(\.displayTitle).joined(separator: ", "))
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Artifacts", subtitle: "Manual-install directories and runtime files required by this model.")
                    ForEach(model.artifacts) { artifact in
                        let resolved = artifacts.first(where: { $0.id == artifact.id })
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            HStack(alignment: .top, spacing: AppSpacing.md) {
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text(artifact.id)
                                        .font(.headline)
                                    Text("\(artifact.role.displayTitle) • \(artifact.format.displayTitle)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                StatusBadgeView(
                                    title: resolved?.exists == true ? "Present" : "Missing",
                                    systemImage: resolved?.exists == true ? "checkmark.circle.fill" : "shippingbox",
                                    tint: resolved?.exists == true ? AppColors.success : AppColors.warning
                                )
                            }

                            metadataItem("Manual install directory", artifact.manualInstallDirectoryName)
                            metadataItem("Artifact file", artifact.fileName)
                            metadataItem("Expected size", artifact.expectedSizeBytes.map(byteCountString) ?? "Not specified")
                            metadataItem("Checksum", artifact.sha256 ?? "Not provided")

                            if let localURL = resolved?.localURL {
                                metadataItem("Resolved path", localURL.path)
                            }

                            if let downloadURL = artifact.downloadURL {
                                Link(destination: downloadURL) {
                                    Label("Source download URL", systemImage: "arrow.down.circle")
                                }
                                .font(.subheadline)
                            } else {
                                Button("Download unavailable") { }
                                    .buttonStyle(.bordered)
                                    .disabled(true)
                            }
                        }
                        .padding(.vertical, AppSpacing.sm)

                        if artifact.id != model.artifacts.last?.id {
                            Divider()
                        }
                    }
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Tokenizer")
                    metadataItem("Source", model.tokenizer.source)
                    metadataItem("Type", model.tokenizer.type)
                    metadataItem("Chat template", model.tokenizer.chatTemplate)
                    metadataItem("Tokenizer files", model.tokenizer.tokenizerFiles.joined(separator: ", "))
                    metadataItem("Stop token IDs", model.tokenizer.stopTokenIds.map(String.init).joined(separator: ", ").ifEmpty("None"))
                    metadataItem("Stop strings", model.tokenizer.stopStrings.joined(separator: ", ").ifEmpty("None"))
                    metadataItem("Notes", model.tokenizer.notes.joined(separator: " • ").ifEmpty("None"))
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Generation Defaults")
                    LazyVGrid(columns: metadataColumns, alignment: .leading, spacing: AppSpacing.md) {
                        metadataItem("Default context window", "\(model.generation.defaultContextWindow)")
                        metadataItem("Max context window", model.generation.maxContextWindow.map(String.init) ?? "Not specified")
                        metadataItem("Max output tokens", "\(model.generation.maxOutputTokens)")
                        metadataItem("Temperature", numberString(model.generation.temperature))
                        metadataItem("Top P", numberString(model.generation.topP))
                        metadataItem("Top K", model.generation.topK.map(String.init) ?? "Not specified")
                        metadataItem("Do sample", yesNo(model.generation.doSample))
                        metadataItem("Greedy supported", yesNo(model.generation.greedySupported))
                    }
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Runtime Adapter And Status")
                    LazyVGrid(columns: metadataColumns, alignment: .leading, spacing: AppSpacing.md) {
                        metadataItem("Adapter", model.runtime.adapter.displayTitle)
                        metadataItem("Status", model.runtime.status.displayTitle)
                        metadataItem("Runner", preflight.runnerName)
                        metadataItem("Engine", model.runtime.engine)
                        metadataItem("Function", model.runtime.functionName)
                        metadataItem("Input names", model.runtime.inputNames.joined(separator: ", ").ifEmpty("None"))
                        metadataItem("Output names", model.runtime.outputNames.joined(separator: ", ").ifEmpty("None"))
                        metadataItem("State names", model.runtime.stateNames.joined(separator: ", ").ifEmpty("None"))
                        metadataItem("Static inputs", model.runtime.staticInputNames?.joined(separator: ", ") ?? "None")
                        metadataItem("Preferred compute", model.runtime.preferredCompute.displayTitle)
                        metadataItem("Custom Metal kernels", yesNo(model.runtime.requiresCustomMetalKernels))
                        metadataItem("Core AI model patches", yesNo(model.runtime.requiresCoreAIModelsPatches))
                        metadataItem("Runtime flags", runtimeFlagsText(model.runtime.requiredRuntimeFlags))
                        metadataItem("Increased memory entitlement", model.runtime.requiresIncreasedMemoryEntitlement.map(yesNo) ?? "Not specified")
                        metadataItem("Runtime notes", model.runtime.notes.joined(separator: " • ").ifEmpty("None"))
                    }
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Device Policy")
                    LazyVGrid(columns: metadataColumns, alignment: .leading, spacing: AppSpacing.md) {
                        metadataItem("iPhone", model.devicePolicy.iPhone.displayTitle)
                        metadataItem("iPad", model.devicePolicy.iPad.displayTitle)
                        metadataItem("Mac", model.devicePolicy.Mac.displayTitle)
                        metadataItem("Minimum iOS", model.devicePolicy.minimumOS.iOS ?? "Not specified")
                        metadataItem("Minimum iPadOS", model.devicePolicy.minimumOS.iPadOS ?? "Not specified")
                        metadataItem("Minimum macOS", model.devicePolicy.minimumOS.macOS ?? "Not specified")
                        metadataItem("Policy notes", model.devicePolicy.notes.joined(separator: " • ").ifEmpty("None"))
                    }
                }
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: AppSpacing.readableMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func internalDownloadActions(for model: ModelVariant, state: ModelDownloadState) -> some View {
        switch state {
        case .notAvailable:
            Text("Downloads are not configured for this manifest entry.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .notDownloaded, .unavailable:
            Button {
                Task { await viewModel.downloadModel(model) }
            } label: {
                Label("Download Model", systemImage: "arrow.down.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!(model.downloadSupported && model.downloadURL != nil))
        case .downloading:
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ProgressView()
                Button("Cancel Download") {
                    viewModel.cancelDownload(model)
                }
                .buttonStyle(.bordered)
            }
        case .downloaded:
            Button(role: .destructive) {
                viewModel.deleteDownloadedArtifact(model)
            } label: {
                Label("Delete Downloaded Artifact", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        case .failed:
            Button {
                Task { await viewModel.retryDownload(model) }
            } label: {
                Label("Retry Download", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private func externalCapabilityBadges(
        model: CoreAIExternalModelProfile,
        preflight: CoreAIRunnerPreflightResult
    ) -> some View {
        if model.capabilities.supportsTextChat {
            StatusBadgeView(title: "Text Chat", systemImage: "text.bubble", tint: AppColors.success)
        }
        if model.capabilities.supportsImageUpload {
            StatusBadgeView(title: "Image Upload", systemImage: "photo", tint: AppColors.success)
        }
        if model.capabilities.supportsImageTextToText || model.capabilities.supportsImageToText {
            StatusBadgeView(title: "Vision Language", systemImage: "viewfinder", tint: AppColors.success)
        }
        if preflight.readiness == .adapterRequired || model.runtime.status == .adapterRequired {
            StatusBadgeView(title: "Runtime Adapter Required", systemImage: "wrench.and.screwdriver", tint: AppColors.warning)
        }
        if model.artifacts.allSatisfy(\.isManualInstallOnly) {
            StatusBadgeView(title: "Manual Install", systemImage: "shippingbox", tint: AppColors.warning)
        }
    }

    private func badgeScroller<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                content()
            }
        }
    }

    private var metadataColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 220), spacing: AppSpacing.md, alignment: .topLeading),
        ]
    }

    private func expectedSizeText(for model: ModelVariant) -> String {
        if let expectedSizeBytes = model.expectedSizeBytes {
            return byteCountString(expectedSizeBytes)
        }
        return model.estimatedSize ?? "Not specified"
    }

    private func byteCountString<T: BinaryInteger>(_ value: T) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .file)
    }

    private func numberString(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)))
    }

    private func yesNo(_ value: Bool) -> String {
        value ? "Yes" : "No"
    }

    private func runtimeFlagsText(_ flags: [CoreAIRuntimeFlag]) -> String {
        guard !flags.isEmpty else { return "None" }
        return flags.map { "\($0.name)=\($0.value)" }.joined(separator: ", ")
    }

    private func inspectionPathText(for check: ArtifactCheckResult) -> String {
        let location = check.relativePath ?? "bundle root"
        let expectedKind = check.expectedKind == .directory ? "directory" : "file"
        let resolvedPath = check.actualURL?.path ?? "No resolved local path"
        return "\(location) • expected \(expectedKind) • \(resolvedPath)"
    }

    private func metadataItem(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
    }

    private func linkItem(_ title: String, _ url: URL) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Link(url.absoluteString, destination: url)
                .font(.subheadline)
        }
    }
}

private extension CoreAIRunnerReadiness {
    var displayTitle: String {
        switch self {
        case .ready:
            "Ready"
        case .experimental:
            "Experimental"
        case .adapterRequired:
            "Adapter Required"
        case .unsupported:
            "Unsupported"
        case .missingArtifacts:
            "Missing Artifacts"
        case .invalidProfile:
            "Invalid Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .ready:
            "checkmark.circle.fill"
        case .experimental:
            "flask"
        case .adapterRequired:
            "wrench.and.screwdriver"
        case .unsupported:
            "xmark.octagon.fill"
        case .missingArtifacts:
            "shippingbox"
        case .invalidProfile:
            "exclamationmark.triangle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .ready:
            AppColors.success
        case .experimental:
            Color.accentColor
        case .adapterRequired, .missingArtifacts:
            AppColors.warning
        case .unsupported, .invalidProfile:
            AppColors.danger
        }
    }
}

private extension CoreAIRunnerFindingSeverity {
    var displayTitle: String {
        rawValue.capitalized
    }

    var systemImage: String {
        switch self {
        case .info:
            "info.circle.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        case .error:
            "xmark.octagon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .info:
            Color.accentColor
        case .warning:
            AppColors.warning
        case .error:
            AppColors.danger
        }
    }
}

private extension CoreAIModelModality {
    var displayTitle: String {
        rawValue.capitalized
    }
}

private extension CoreAIModelInputMode {
    var displayTitle: String {
        switch self {
        case .text:
            "Text"
        case .image:
            "Image"
        case .imageText:
            "Image + Text"
        case .audio:
            "Audio"
        case .textImage:
            "Text + Image"
        case .embeddingInput:
            "Embedding Input"
        }
    }
}

private extension CoreAIModelOutputMode {
    var displayTitle: String {
        switch self {
        case .text:
            "Text"
        case .image:
            "Image"
        case .embedding:
            "Embedding"
        case .classification:
            "Classification"
        case .detections:
            "Detections"
        }
    }
}

private extension CoreAIArtifactRole {
    var displayTitle: String {
        switch self {
        case .languageBundle:
            "Language Bundle"
        case .languageDecoder:
            "Language Decoder"
        case .visionEncoder:
            "Vision Encoder"
        case .frontendGather:
            "Frontend Gather"
        case .tokenizer:
            "Tokenizer"
        case .metadata:
            "Metadata"
        case .configuration:
            "Configuration"
        case .weights:
            "Weights"
        }
    }
}

private extension CoreAIArtifactFormat {
    var displayTitle: String {
        switch self {
        case .aimodel:
            "aimodel"
        case .aimodelBundle:
            "aimodel bundle"
        case .aimodelLanguageBundle:
            "aimodel language bundle"
        case .rawTableBundle:
            "raw table bundle"
        case .aimodelOrRawTableBundle:
            "aimodel/raw table bundle"
        case .zipArchive:
            "zip archive"
        case .directory:
            "directory"
        }
    }
}

private extension CoreAIRuntimeAdapter {
    var displayTitle: String {
        switch self {
        case .coreaiPipelinedNStateText:
            "Core AI Pipelined N-State Text"
        case .coreaiPipelinedExtraStateText:
            "Core AI Pipelined Extra-State Text"
        case .gemma4MultiStagePipelinedText:
            "Gemma 4 Multi-Stage Text"
        case .coreaiPipelinedVisionLanguage:
            "Core AI Vision Language"
        case .coreaiStandardLanguageModel:
            "Core AI Standard Language Model"
        case .mock:
            "Mock"
        case .unknown:
            "Unknown"
        }
    }
}

private extension CoreAIRuntimeStatus {
    var displayTitle: String {
        switch self {
        case .ready:
            "Ready"
        case .experimental:
            "Experimental"
        case .adapterRequired:
            "Adapter Required"
        case .unsupported:
            "Unsupported"
        }
    }
}

private extension CoreAIComputePreference {
    var displayTitle: String {
        switch self {
        case .automatic:
            "Automatic"
        case .cpu:
            "CPU"
        case .gpu:
            "GPU"
        case .neuralEngine:
            "Neural Engine"
        }
    }
}

private extension CoreAIDeviceSupportLevel {
    var displayTitle: String {
        switch self {
        case .supported:
            "Supported"
        case .supportedWithHighMemory:
            "Supported With High Memory"
        case .macRecommended:
            "Mac Recommended"
        case .recommended:
            "Recommended"
        case .unsupported:
            "Unsupported"
        case .unknown:
            "Unknown"
        }
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}
