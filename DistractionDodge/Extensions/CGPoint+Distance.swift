//
//  CGPoint+Distance.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/10/25.
//
import Foundation
import CoreGraphics

extension CGPoint {
    /// Calculates the distance between this point and another point.
    /// - Parameter point: The other point.
    /// - Returns: The distance between the two points.
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(point.x - x, 2) + pow(point.y - y, 2))
    }
}
