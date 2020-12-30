//
//  OptionalLessThan.swift
//  Prayer
//
//  Created by Ben on 4/10/20.
//  Copyright © 2020 Ben. All rights reserved.
//

import Foundation

/// Make Optional<T> adhere to the Comparable protocol; that is, add an operator< to it.
/// The "where Wrapped: Comparable" is required because otherwise, the return left! < right!
/// would recursively call this.
extension Optional: Comparable where Wrapped: Comparable
{
    public static func < (left: Optional<Wrapped>, right: Optional<Wrapped>) -> Bool
    {
        // SORT NIL < NON-NIL.
        if (nil == left) && (nil != right) {return true}
        if (nil != left) && (nil == right) {return false}
        if (nil == left) && (nil == right) {return false}
        
        // SORT BY THE WRAPPED VALUE.
        // This will recursively call unless 'where Wrapped: Comparable' is present!
        return left! < right!
    }
}
