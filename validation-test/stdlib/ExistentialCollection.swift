//===--- ExistentialCollection.swift --------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
// RUN: %target-run-simple-swift
// REQUIRES: executable_test

import StdlibUnittest
import StdlibCollectionUnittest

// Check that the generic parameter is called 'Element'.
protocol TestProtocol1 {}

extension AnyIterator where Element : TestProtocol1 {
  var _elementIsTestProtocol1: Bool {
    fatalError("not implemented")
  }
}

extension AnySequence where Element : TestProtocol1 {
  var _elementIsTestProtocol1: Bool {
    fatalError("not implemented")
  }
}

extension AnyCollection where Element : TestProtocol1 {
  var _elementIsTestProtocol1: Bool {
    fatalError("not implemented")
  }
}

extension AnyBidirectionalCollection where Element : TestProtocol1 {
  var _elementIsTestProtocol1: Bool {
    fatalError("not implemented")
  }
}

extension AnyRandomAccessCollection where Element : TestProtocol1 {
  var _elementIsTestProtocol1: Bool {
    fatalError("not implemented")
  }
}

var tests = TestSuite("ExistentialCollection")

tests.test("AnyIterator") {
  func digits() -> AnyIterator<OpaqueValue<Int>> {
    let integers: CountableRange = 0..<5
    let lazyIntegers = integers.lazy
    let lazyStrings = lazyIntegers.map { OpaqueValue($0) }

    // This is a really complicated type of no interest to our
    // clients.
    let iterator: LazyMapIterator<
        IndexingIterator<CountableRange<Int>>, OpaqueValue<Int>
      > = lazyStrings.makeIterator()
    return AnyIterator(iterator)
  }
  expectEqual([0, 1, 2, 3, 4], Array(digits()).map { $0.value })

  var x = 7
  let iterator = AnyIterator<Int> {
    if x >= 15 { return nil }
    x += 1
    return x-1
  }
  expectEqual([ 7, 8, 9, 10, 11, 12, 13, 14 ], Array(iterator))
}

tests.test("AnySequence.init(Sequence)") {
  do {
    let base = MinimalSequence<OpaqueValue<Int>>(elements: [])
    var s = AnySequence(base)
    expectType(AnySequence<OpaqueValue<Int>>.self, &s)
    checkSequence([], s, resiliencyChecks: .none) { $0.value == $1.value }
  }
  do {
    let intData = [ 1, 2, 3, 5, 8, 13, 21 ]
    let data = intData.map(OpaqueValue.init)
    let base = MinimalSequence(elements: data)
    var s = AnySequence(base)
    expectType(AnySequence<OpaqueValue<Int>>.self, &s)
    checkSequence(data, s, resiliencyChecks: .none) { $0.value == $1.value }
  }
}

tests.test("AnySequence.init(() -> Generator)") {
  do {
    var s = AnySequence {
      return MinimalIterator<OpaqueValue<Int>>([])
    }
    expectType(AnySequence<OpaqueValue<Int>>.self, &s)
    checkSequence([], s, resiliencyChecks: .none) { $0.value == $1.value }
  }
  do {
    let intData = [ 1, 2, 3, 5, 8, 13, 21 ]
    let data = intData.map(OpaqueValue.init)
    var s = AnySequence {
      return MinimalIterator(data)
    }
    expectType(AnySequence<OpaqueValue<Int>>.self, &s)
    checkSequence(data, s, resiliencyChecks: .none) { $0.value == $1.value }
  }
}

tests.test("AnyCollection successor/predecessor") {
  typealias Base = LoggingCollection<MinimalCollection<OpaqueValue<Int>>>
  typealias Log = CollectionLog
  let base = Base(wrapping:
    MinimalCollection(elements: (0..<10).map(OpaqueValue.init)))
  let c = AnyCollection(base)
  var i = c.startIndex

  Log.successor.expectIncrement(Base.self) {
    Log.formSuccessor.expectUnchanged(Base.self) {
      i = c.successor(of: i)
    }
  }

  Log.successor.expectUnchanged(Base.self) {
    Log.formSuccessor.expectIncrement(Base.self) {
      c.formSuccessor(&i)
    }
  }

  var x = i
  Log.successor.expectIncrement(Base.self) {
    Log.formSuccessor.expectUnchanged(Base.self) {
      i = c.successor(of: i)
    }
  }
  _blackHole(x)
}

tests.test("AnyBidirectionalCollection successor/predecessor") {
  typealias Base = LoggingBidirectionalCollection<MinimalBidirectionalCollection<OpaqueValue<Int>>>
  typealias Log = BidirectionalCollectionLog
  let base = Base(wrapping:
    MinimalBidirectionalCollection(elements: (0..<10).map(OpaqueValue.init)))
  let c = AnyBidirectionalCollection(base)
  var i = c.endIndex

  Log.predecessor.expectIncrement(Base.self) {
    Log.formPredecessor.expectUnchanged(Base.self) {
      i = c.predecessor(of: i)
    }
  }

  Log.predecessor.expectUnchanged(Base.self) {
    Log.formPredecessor.expectIncrement(Base.self) {
      c.formPredecessor(&i)
    }
  }

  var x = i
  Log.predecessor.expectIncrement(Base.self) {
    Log.formPredecessor.expectUnchanged(Base.self) {
      i = c.predecessor(of: i)
    }
  }
  _blackHole(x)
}

tests.test("ForwardCollection") {
  let a0: ContiguousArray = [1, 2, 3, 5, 8, 13, 21]
  let fc0 = AnyCollection(a0)
  let a1 = ContiguousArray(fc0)
  expectEqual(a0, a1)
  for e in a0 {
    let i = fc0.index(of: e)
    expectNotEmpty(i)
    expectEqual(e, fc0[i!])
  }
  for i in fc0.indices {
    expectNotEqual(fc0.endIndex, i)
    expectEqual(1, fc0.indices.filter { $0 == i }.count)
  }
}

tests.test("BidirectionalCollection") {
  let a0: ContiguousArray = [1, 2, 3, 5, 8, 13, 21]
  let fc0 = AnyCollection(a0.lazy.reversed())
  
  let bc0_ = AnyBidirectionalCollection(fc0)  // upgrade!
  expectNotEmpty(bc0_)
  let bc0 = bc0_!
  expectTrue(fc0 === bc0)

  let fc1 = AnyCollection(a0.lazy.reversed()) // new collection
  expectFalse(fc1 === fc0)

  let fc2 = AnyCollection(bc0)                // downgrade
  expectTrue(fc2 === bc0)
  
  let a1 = ContiguousArray(bc0.lazy.reversed())
  expectEqual(a0, a1)
  for e in a0 {
    let i = bc0.index(of: e)
    expectNotEmpty(i)
    expectEqual(e, bc0[i!])
  }
  for i in bc0.indices {
    expectNotEqual(bc0.endIndex, i)
    expectEqual(1, bc0.indices.filter { $0 == i }.count)
  }
  
  // Can't upgrade a non-random-access collection to random access
  let s0 = "Hello, Woyld".characters
  let bc1 = AnyBidirectionalCollection(s0)
  let fc3 = AnyCollection(bc1)
  expectTrue(fc3 === bc1)
  expectEmpty(AnyRandomAccessCollection(bc1))
  expectEmpty(AnyRandomAccessCollection(fc3))
}

tests.test("RandomAccessCollection") {
  let a0: ContiguousArray = [1, 2, 3, 5, 8, 13, 21]
  let fc0 = AnyCollection(a0.lazy.reversed())
  let rc0_ = AnyRandomAccessCollection(fc0)         // upgrade!
  expectNotEmpty(rc0_)
  let rc0 = rc0_!
  expectTrue(rc0 === fc0)

  let bc1 = AnyBidirectionalCollection(rc0)         // downgrade
  expectTrue(bc1 === rc0)

  let fc1 = AnyBidirectionalCollection(rc0)         // downgrade
  expectTrue(fc1 === rc0)
  
  let a1 = ContiguousArray(rc0.lazy.reversed())
  expectEqual(a0, a1)
  for e in a0 {
    let i = rc0.index(of: e)
    expectNotEmpty(i)
    expectEqual(e, rc0[i!])
  }
  for i in rc0.indices {
    expectNotEqual(rc0.endIndex, i)
    expectEqual(1, rc0.indices.filter { $0 == i }.count)
  }
}

runAllTests()
