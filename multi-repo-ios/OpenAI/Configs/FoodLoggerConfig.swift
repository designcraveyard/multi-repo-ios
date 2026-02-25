//
//  FoodLoggerConfig.swift
//  multi-repo-ios
//
//  TransformConfig for the food logging feature. Demonstrates how to wire up
//  a custom tool (USDA FoodData Central search) into the TransformService pipeline.
//
//  Architecture:
//  This file is a self-contained config — it defines the system prompt, declares the
//  `food_search` function tool schema, and provides the ToolHandler closure that
//  executes the tool locally when the model invokes it. No changes to TransformService
//  are needed; just pass `FoodLoggerConfig.config` to `TransformService.shared.stream()`.
//
//  How it works end-to-end:
//  1. User says "I ate a chicken sandwich" (text) or sends a photo of food (image)
//  2. TransformService sends the input + system prompt + tool definitions to the model
//  3. The model decides to call `food_search(query: "chicken sandwich")`
//  4. TransformService looks up "food_search" in `toolHandlers` and invokes `foodSearchHandler`
//  5. The handler calls the USDA API, extracts nutrient data, returns JSON to the model
//  6. TransformService sends the tool output back; the model generates a formatted response
//  7. The caller sees `.textDelta` events with the nutritional breakdown
//

import Foundation

// MARK: - FoodLoggerConfig
// Uses `enum` as a pure namespace (no instances) following the OpenAIConfig pattern.

enum FoodLoggerConfig {

    /// The complete TransformConfig for food logging. Pass this to
    /// `TransformService.shared.stream(config: FoodLoggerConfig.config, input: ...)`.
    ///
    /// Capabilities:
    /// - Accepts both text and image input (user can describe food or photograph it)
    /// - Has `web_search_preview` for general food questions the USDA doesn't cover
    /// - Has `food_search` custom function for structured USDA nutritional lookups
    static let config = TransformConfig(
        id: "food-logger",
        systemPrompt: """
            You are a food logging assistant. When the user describes food they ate, \
            ALWAYS call the food_search function tool to look up nutritional information from the USDA database \
            — do NOT use web search for this. \
            Present the results in a clear, readable format with calories and macronutrients. \
            If there are multiple matches, help the user pick the right one.
            """,
        tools: [
            // Built-in web search — lets the model look up general food info beyond USDA
            .webSearchPreview,
            // Custom function tool — schema tells the model what arguments to provide.
            // The `parameters` dict is a JSON Schema object sent verbatim to the API.
            .function(
                name: "food_search",
                description: "Search the USDA FoodData Central database for nutritional information",
                parameters: [
                    "type": "object",
                    "properties": [
                        "query": [
                            "type": "string",
                            "description": "The food item to search for, e.g. 'apple' or 'chicken breast'",
                        ] as [String: Any],
                    ] as [String: Any],
                    "required": ["query"],
                    "additionalProperties": false,
                ]
            ),
        ],
        inputTypes: [.text, .image],
        // Map tool name -> handler closure. TransformService uses this dict to dispatch calls.
        toolHandlers: [
            "food_search": foodSearchHandler,
        ]
    )

    // MARK: - USDA Food Search Handler
    // This ToolHandler closure is invoked by TransformService when the model calls "food_search".
    // It receives the raw JSON arguments string from the model, calls the USDA FoodData Central
    // API, and returns a JSON string of results that the model can interpret.

    /// Searches the USDA FoodData Central API and returns up to 5 results with key nutrients.
    ///
    /// Expected input JSON: `{"query": "chicken breast"}`
    /// Returns JSON: `{"results": [{"fdcId": ..., "description": ..., "nutrients": {...}}, ...]}`
    ///
    /// On USDA API failure or empty results, returns `{"results": []}` rather than throwing,
    /// so the model can gracefully tell the user no results were found.
    private static let foodSearchHandler: ToolHandler = { argsJSON in
        // Parse the model's JSON arguments to extract the search query
        guard let data = argsJSON.data(using: .utf8),
              let args = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let query = args["query"] as? String else {
            return "{\"error\": \"Invalid arguments\"}"
        }

        // Build the USDA API URL with the query, API key, and a page size limit of 5
        let apiKey = OpenAIConfig.usdaApiKey
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(encoded)&api_key=\(apiKey)&pageSize=5") else {
            return "{\"error\": \"Invalid URL\"}"
        }

        // Call the USDA API. This is async and may take a few hundred ms.
        let (responseData, _) = try await URLSession.shared.data(from: url)
        guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let foods = json["foods"] as? [[String: Any]] else {
            return "{\"results\": []}"
        }

        // Transform each USDA food item into a simplified structure with just the
        // four key macronutrients. The model uses these to format its response.
        let results = foods.map { food -> [String: Any] in
            let nutrients = food["foodNutrients"] as? [[String: Any]] ?? []

            // Helper to extract a nutrient value by its USDA nutrient ID.
            // Returns NSNull() instead of nil so JSONSerialization can handle it.
            // USDA nutrient IDs are stable numeric identifiers:
            //   1008 = Energy (kcal)     — calories
            //   1003 = Protein (g)
            //   1004 = Total lipid/fat (g)
            //   1005 = Carbohydrate (g)
            func nutrientValue(_ id: Int) -> Any {
                nutrients.first { ($0["nutrientId"] as? Int) == id }?["value"] ?? NSNull()
            }
            return [
                "fdcId": food["fdcId"] ?? NSNull(),
                "description": food["description"] ?? NSNull(),
                "brand": food["brandName"] ?? NSNull(),
                "nutrients": [
                    "calories": nutrientValue(1008),   // Energy in kcal
                    "protein": nutrientValue(1003),    // Protein in grams
                    "fat": nutrientValue(1004),        // Total fat in grams
                    "carbs": nutrientValue(1005),      // Carbohydrates in grams
                ],
            ]
        }

        // Serialize results back to JSON string for the model to consume
        let resultData = try JSONSerialization.data(withJSONObject: ["results": results])
        return String(data: resultData, encoding: .utf8) ?? "{\"results\": []}"
    }
}
