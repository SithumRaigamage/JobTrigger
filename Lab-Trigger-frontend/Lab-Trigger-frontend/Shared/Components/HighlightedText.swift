//
//  HighlightedText.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-20.
//

import SwiftUI

struct HighlightedText: View {
  let text: String
  let highlight: String

  var body: some View {
    if highlight.isEmpty {
      Text(text)
    } else {
      Text(attributedText)
    }
  }

  private var attributedText: AttributedString {
    var attributedString = AttributedString(text)
    let pattern = NSRegularExpression.escapedPattern(for: highlight)

    do {
      let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
      let range = NSRange(text.startIndex..<text.endIndex, in: text)
      let matches = regex.matches(in: text, options: [], range: range)

      for match in matches.reversed() {
        if let range = Range(match.range, in: attributedString) {
          attributedString[range].backgroundColor = .blue.opacity(0.15)
          attributedString[range].foregroundColor = .blue
          attributedString[range].font = .system(size: 17, weight: .bold, design: .rounded)
        }
      }
    } catch {
      print("❌ HighlightedText regex error: \(error)")
    }

    return attributedString
  }
}

#Preview {
  VStack(spacing: 20) {
    HighlightedText(text: "Hello World", highlight: "hello")
    HighlightedText(text: "SwiftUI is Awesome", highlight: "is")
    HighlightedText(text: "Test search results", highlight: "search")
  }
  .padding()
}
