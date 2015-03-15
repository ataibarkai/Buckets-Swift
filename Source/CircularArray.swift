//
//  CircularArray.swift
//  Buckets
//
//  Created by Mauricio Santos on 2/21/15.
//  Copyright (c) 2015 Mauricio Santos. All rights reserved.
//

import Foundation

private struct Constants {
    // Must be power of 2
    private static let DefaultCapacity = 8
}

/// A circular array provides most of the feaures of a standard array
/// such as constant-time random access in addition to amortized constant-time
/// insertion/removal at both ends, instead of just one end.
public struct CircularArray<T> {
    
    // MARK: Properties
    
    /// Number of elements stored in the circular array.
    public var count : Int {
        return (tail - head) & (items.count - 1)
    }
    
    /// `true` if and only if the circular array is empty.
    public var isEmpty: Bool {
        return count == 0
    }
    
    /// The first element, or `nil` if the circular array is empty.
    public var first: T? {
        return items[head]
    }
    
    /// The last element, or `nil` if the circular array is empty.
    public var last: T? {
        return items[decreaseIndex(tail)]
    }
    
    private var items = [T?](count: Constants.DefaultCapacity, repeatedValue: nil)
    private var head: Int = 0
    private var tail: Int = 0
    
    // MARK: Creating a Circular Array
    
    /// Constructs an empty array of type `T`.
    public init() {}
    
    /// Constructs a circular array with a given number of elements, each 
    /// initialized to the same value.
    public init(count: Int, repeatedValue: T) {
        if count < 0 {
            fatalError("Can't construct CircularArray with count < 0")
        }
        for _ in 0..<count {
            append(repeatedValue)
        }
    }
    
    /// Constructs a circular array from a standard array.
    public init(elements: [T]) {
        for e in elements {
            append(e)
        }
    }
    
    // MARK: Adding and Removing Elements
    
    /// Adds a new item as the first element in an existing circular array.
    public mutating func prepend(element: T) {
        head = decreaseIndex(head)
        items[head] = element
        checkCapacity()
    }
    
    /// Adds a new item as the last element in an existing circular array.
    public mutating func append(element: T) {
        items[tail] = element
        tail = increaseIndex(tail)
        checkCapacity()
    }
    
    /// Removes the first element from the circular array and returns it.
    ///
    /// :returns: The first element, or `nil` if the circular array is empty.
    public mutating func removeFirst() -> T? {
        if let value = first {
            items[head] = nil
            head = increaseIndex(head)
            return value
        }
        return nil
    }
    
    /// Inserts an element into the collection at a given index.
    /// Use this method to insert a new element anywhere within the range
    /// of existing items, or as the last item. The index must be less
    /// than or equal to the number of items in the circular array. If you
    /// attempt to remove an item at a greater index, you’ll trigger an error.
    public mutating func insert(element: T, atIndex index: Int) {
        checkIndex(index, lessThan: count + 1)
        append(element)
        for var i = count - 2; i >= index; i-- {
            let rIndex = realIndex(i)
            let nextIndex = realIndex(i+1)
            items[nextIndex] = items[rIndex]
            
        }
        items[index] = element
    }
    
    /// Removes the last element from the circular array and returns it.
    ///
    /// :returns: The last element, or nil if the circular array is empty.
    public mutating func removeLast() -> T? {
        if let value = last {
            tail = decreaseIndex(tail)
            items[tail] = nil
            return value
        }
        return nil
    }
    
    /// Removes the element at the given index and returns it. 
    ///
    /// The index must be less than the number of items in the 
    /// circular array. If you attempt to remove an item at a 
    /// greater index, you’ll trigger an error.
    public mutating func removeAtIndex(index: Int) -> T {
        checkIndex(index)
        let element = items[realIndex(index)]
        
        for i in (index + 1)..<count {
            let rIndex = realIndex(i)
            let prevIndex = realIndex(i-1)
            items[prevIndex] = items[rIndex]
        }
        
        removeLast()
        return element!
    }
    
    /// Removes all the elements from the collection, and by default
    /// clears the underlying storage buffer.
    public mutating func removeAll(keepCapacity keep: Bool = true)  {
        if !keep {
            items.removeAll(keepCapacity: false)
        } else {
            items[0 ..< items.count] = [nil]
        }
        tail = 0
        head = 0
    }
    
    // MARK: Private Helper Methods
    
    private func increaseIndex(index: Int) -> Int {
        return (index + 1) & (items.count - 1)
    }
    
    private func decreaseIndex(index: Int) -> Int {
        return (index - 1) & (items.count - 1)
    }
    
    private func realIndex(logicalIndex: Int) -> Int {
        return (head + logicalIndex) & (items.count - 1)
    }
    
    private mutating func checkCapacity() {
        if head != tail {
            return
        }
        
        // Array full. Create a bigger one
        
        var newArray = [T?](count: items.count * 2, repeatedValue: nil)
        let nFront = items.count - head
        newArray[0 ..< nFront] = items[head ..< items.count]
        newArray[nFront ..< nFront + head] = items[0 ..< head]

        head = 0
        tail = items.count
        items = newArray
    }
    
    private func checkIndex(index: Int, var lessThan: Int? = nil) {
        lessThan = lessThan == nil ? count : lessThan
        if index < 0 || index >= lessThan!  {
            fatalError("Index out of range (\(index))")
        }
    }
}

// MARK:- SequenceType

extension CircularArray: SequenceType {
    
    // MARK: SequenceType Protocol Conformance
    
    /// Provides for-in loop functionality.
    ///
    /// :returns: A generator over the elements.
    public func generate() -> GeneratorOf<T> {
        var current = head
        return GeneratorOf<T> {
            if let value = self.items[current] {
                current = self.increaseIndex(current)
                return value
            }
            return nil
        }
    }
}

// MARK: - MutableCollectionType

extension CircularArray: MutableCollectionType {
    
    // MARK: MutableCollectionType Protocol Conformance
    
    /// Always zero, which is the index of the first element when non-empty.
    public var startIndex : Int {
        return 0
    }
    
    /// Always `count`, which is  the successor of the last valid subscript argument.
    public var endIndex : Int {
        return count
    }
    
    /// Provides random access to elements using square bracket noation.
    /// The index must be less than the number of items in the circular array.
    /// If you attempt to get or set an item at a greater 
    /// index, you’ll trigger an error.
    public subscript(index: Int) -> T {
        get {
            checkIndex(index)
            let rIndex = realIndex(index)
            return items[rIndex]!
        }
        set {
            checkIndex(index)
            let rIndex = realIndex(index)
            items[rIndex] = newValue
        }
    }
}

// MARK: - ArrayLiteralConvertible

extension CircularArray: ArrayLiteralConvertible {
    
    // MARK: ArrayLiteralConvertible Protocol Conformance
    
    /// Constructs a circular array using an array literal.
    /// `let example: CircularArray<Int> = [1,2,3]`
    public init(arrayLiteral elements: T...) {
        for e in elements {
            append(e)
        }
    }
}

// MARK: - Printable

extension CircularArray: Printable, DebugPrintable {
    
    // MARK: Printable Protocol Conformance
    
    /// A string containing a suitable textual 
    /// representation of the circular array.
    public var description: String {
        return "[" + join(", ", map(self) {"\($0)"}) + "]"
    }
    
    // MARK: DebugPrintable Protocol Conformance
    
    /// A string containing a suitable textual representation 
    /// of the circular array when debugging.
    public var debugDescription: String {
        return description
    }
}

// MARK: - Operators

// MARK: CircularArray Operators

/// Returns `true` if and only if the circular arrays contain the same elements 
/// in the same logical order.
/// The underlying elements must conform to the `Equatable` protocol.
public func ==<T: Equatable>(lhs: CircularArray<T>, rhs: CircularArray<T>) -> Bool {
    if lhs.count != rhs.count {
        return false
    }
    return equal(lhs, rhs)
}

public func !=<T: Equatable>(lhs: CircularArray<T>, rhs: CircularArray<T>) -> Bool {
    return !(lhs==rhs)
}