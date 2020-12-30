//
//  File.swift
//  Prayer
//
//  Created by Ben on 5/1/20.
//  Copyright © 2020 Ben. All rights reserved.
//

import SwiftUI

/// A button for explicitly dismissing a sheet instead of having to swipe down on it.
/// \date   2020-05-01
struct DismissSheetDoneButton: View
{
    @Binding var isPresented: Bool

    var body: some View
    {
        Button(
            action: {self.isPresented = false},
            label: {Text("Done")})
    }
}
