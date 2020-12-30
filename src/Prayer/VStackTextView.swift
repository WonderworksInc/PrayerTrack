//
//  VStackTextView.swift
//  Prayer
//
//  Created by Ben on 3/15/20.
//  Copyright © 2020 Ben. All rights reserved.
//

import SwiftUI

struct VStackTextView: View{
    @Binding var top: String
    let bottom: String
    
    var body: some View{
        VStack(alignment: .leading){
            TextField(bottom, text: $top).font(.headline)
            // Move down a tad so that it's closer to the label.
            .offset(x:0, y:5)
            //Text(top).font(.headline)
            Text(bottom).font(.subheadline).foregroundColor(.secondary)
        }
    }
}

struct VStackTextView_Previews: PreviewProvider {
    static var previews: some View {
        VStackTextView(top: .constant("Abc"), bottom: "Bottom text")
    }
}
