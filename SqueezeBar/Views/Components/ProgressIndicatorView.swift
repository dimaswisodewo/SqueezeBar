//
//  ProgressIndicatorView.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 15/12/25.
//

import SwiftUI

struct ProgressIndicatorView: View {
    let isCompressing: Bool
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            if isCompressing {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.8)
            }

            Text(message)
                .font(.caption)
                .foregroundColor(isCompressing ? .accentColor : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack {
        ProgressIndicatorView(isCompressing: false, message: "Drag a file here")
        ProgressIndicatorView(isCompressing: true, message: "Compressing...")
    }
}
