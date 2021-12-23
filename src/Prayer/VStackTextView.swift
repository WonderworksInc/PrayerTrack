//
//  VStackTextView.swift
//  Prayer
//
//  Created by Ben on 3/15/20.
//  Copyright © 2020 Ben. All rights reserved.
//

import SwiftUI

struct VStackTextView: View
{
    @Binding var top: String
    let bottom: String
    // Save the user's edits to temporary_text to avoid the UI changes that occur when editing
    // top, which can slow the UI down noticeably.
    @State private var temporaryText: String

    init(top: Binding<String>, bottom: String)
    {
        self._top = top
        self.bottom = bottom
        self._temporaryText = .init(initialValue: top.wrappedValue)
    }
    
    var body: some View
    {
        VStack(alignment: .leading){
            //TextEditor(text: $top)
            TextField(
                bottom,
                text: $temporaryText,
                /// \todo Use @FocusState in iOS 15 instead of onEditingChanged.
                ///     https://stackoverflow.com/questions/69050952/swiftui-run-function-on-losing-focus-textfield
                onEditingChanged: {user_began_editing in
                    let user_finished_editing = !user_began_editing
                    if (user_finished_editing)
                    {
                        // Modify the actual text only when the user is done editing to avoid updating the UI
                        // unnecessarily, which can noticeably slow down the UI.
                        top = self.temporaryText
                    }
                }
            )
            .font(.headline)
            // Move down a tad so that it's closer to the label.
            .offset(x:0, y:5)
            //Text(top).font(.headline)
            Text(bottom).font(.subheadline).foregroundColor(.secondary)
        }
    }
}

/// \todo Could possibly start using this class again if TextEditor works with @FocusState (iOS 15 only).  See
///     https://stackoverflow.com/questions/69050952/swiftui-run-function-on-losing-focus-textfield
struct TextEditorCommitOnlyOnDisappear: View
{
    @Binding var text: String
    @State private var temporary_text: String

    init(text: Binding<String>)
    {
        self._text = text
        self._temporary_text = .init(initialValue: text.wrappedValue)
    }

    var body: some View
    {
        // Save the user's edits to temporary_text to avoid the UI changes that occur when editing
        // the actual text, which can slow the UI down noticeably.
        let temporary_text_binding = Binding<String>(
            get: {temporary_text},
            set: {temporary_text = $0}
        )

        return
            TextEditor(text: $temporary_text)
            // Commit the text changes only when the user quits editing the text.
            .onDisappear(
                perform: {
                    self.text = temporary_text
                }
            )
    }
}

struct VStackTextView_Previews: PreviewProvider {
    static var previews: some View {
        VStackTextView(top: .constant("Abc"), bottom: "Bottom text")
    }
}
