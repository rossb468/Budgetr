//
//  Typography.swift
//  SwiftTestApp
//
//  Created by Ross Bower on 9/2/25.
//

import SwiftUI

extension Font {
    static let appHeader  = Font.system(size: 22, weight: .bold)
    static let appBody    = Font.system(size: 16)
    static let appCaption = Font.system(size: 12)
}

struct TextStyle: ViewModifier {
    enum Style {
        case header
        case body
        case caption
    }
    
    let style: Style
    
    func body(content: Content) -> some View {
        switch style {
        case .header:
            content
                .font(.appHeader)
                .foregroundColor(.primary)
        case .body:
            content
                .font(.appBody)
                .foregroundColor(.primary)
                .padding(4)
        case .caption:
            content
                .font(.appCaption)
                .foregroundColor(.secondary)
        }
    }
}

extension View {
    func appText(_ style: TextStyle.Style) -> some View {
        modifier(TextStyle(style: style))
    }
}
