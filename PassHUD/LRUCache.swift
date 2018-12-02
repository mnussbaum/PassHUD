//
//  LRUCache.swift
//  PassHUD
//
//  Created by Nussbaum, Michael on 10/26/18.
//  Written with help from https://dzone.com/articles/how-to-implement-cache-lru-with-swift
//

import Cocoa

class LinkedListNode {
    var previous: LinkedListNode?
    var next: LinkedListNode?
    var value: AnyHashable

    init(_ value: AnyHashable) {
        self.value = value
    }
}

class DoublyLinkedList {
    var head: LinkedListNode?
    var tail: LinkedListNode?

    func addHead(_ value: AnyHashable) -> LinkedListNode {
        let newNode = LinkedListNode(value)
        if let head = self.head {
            head.previous = newNode
            newNode.next = head
        } else {
            self.tail = newNode
        }
        self.head = newNode

        return newNode
    }

    func moveToHead(_ node: LinkedListNode) {
        guard node !== self.head else { return }

        let previous = node.previous
        let next = node.next
        previous?.next = next
        next?.previous = previous

        node.next = self.head
        if node === tail {
            self.tail = previous
        }
        self.head = node
    }

    func removeLast() -> LinkedListNode? {
        guard let _ = self.tail else { return nil }

        if self.tail === self.head {
            self.head = nil
        }

        let previous = self.tail?.previous
        previous?.next = nil
        let oldTail = self.tail
        self.tail = previous

        return oldTail
    }
}

class LRUCache: Sequence {
    let capacity: Int
    var members = Dictionary<AnyHashable, LinkedListNode>()
    var memberList = DoublyLinkedList()

    init(capacity: Int) {
        self.capacity = capacity
    }

    func addValue(_ value: AnyHashable) {
        if let node = self.members[value] {
            self.memberList.moveToHead(node)
        } else {
            let node = self.memberList.addHead(value)
            self.members[value] = node
        }

        if self.members.count > self.capacity {
            if let removedNode = self.memberList.removeLast() {
                self.members.removeValue(forKey: removedNode.value)
            }
        }
    }

    func makeIterator() -> LRUCacheIterator {
        return LRUCacheIterator(self)
    }

    func isEmpty() -> Bool {
        return self.members.isEmpty
    }
}

struct LRUCacheIterator: IteratorProtocol {
    var nextCacheNode: LinkedListNode?

    init(_ lruCache: LRUCache) {
        self.nextCacheNode = lruCache.memberList.head
    }

    mutating func next() -> AnyHashable? {
        if let cacheNode = self.nextCacheNode {
            self.nextCacheNode = cacheNode.next
            return cacheNode.value
        }

        return nil
    }
}
