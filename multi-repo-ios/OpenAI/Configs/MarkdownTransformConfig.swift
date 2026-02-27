//
//  MarkdownTransformConfig.swift
//  multi-repo-ios
//
//  TransformConfig presets for markdown editor AI features.
//  Uses the existing TransformService infrastructure with custom system prompts.
//
//  These configs are simple text-in / text-out transforms with no tools.
//  The text content (selected or full document) is passed as TransformInput
//  to TransformService.shared.stream(config:input:).

import Foundation

// MARK: - MarkdownTransformConfig

enum MarkdownTransformConfig {

    /// Summarise the provided text into a concise summary.
    static let summarise = TransformConfig(
        id: "md-summarise",
        systemPrompt: "Summarise the following text concisely. Return only the summary, no preamble. Use markdown formatting if helpful.",
        tools: [],
        inputTypes: [.text],
        toolHandlers: [:]
    )

    /// Extract key pointers from the provided text.
    static let keyPointers = TransformConfig(
        id: "md-key-pointers",
        systemPrompt: "Extract the key points from the following text as a markdown bullet list. Be concise. Return only the bullet list, no preamble.",
        tools: [],
        inputTypes: [.text],
        toolHandlers: [:]
    )

    /// Extract action items from the provided text.
    static let listActions = TransformConfig(
        id: "md-list-actions",
        systemPrompt: "Extract all action items and tasks from the following text as a markdown task list using - [ ] format. Return only the task list, no preamble.",
        tools: [],
        inputTypes: [.text],
        toolHandlers: [:]
    )

    /// Custom transformation with a user-provided prompt.
    static func custom(prompt: String) -> TransformConfig {
        TransformConfig(
            id: "md-custom",
            systemPrompt: "You are a text transformation assistant. Apply the following instruction to the provided text. Return only the transformed text, no preamble.\n\nInstruction: \(prompt)",
            tools: [],
            inputTypes: [.text],
            toolHandlers: [:]
        )
    }
}
