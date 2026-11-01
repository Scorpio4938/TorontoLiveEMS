import Foundation
import Testing

import TorontoLiveEMSKit

@Suite("Map detail stack")
struct MapDetailStackTests {

    @Test("the map is on top until something is presented")
    func startsEmpty() {
        let stack = MapDetailStack()
        #expect(stack.top == nil)
        #expect(stack.isEmpty)
        #expect(stack.presentations.isEmpty)
    }

    @Test("the last page presented is the one the capsule reads")
    func topFollowsPresentationOrder() {
        let stack = MapDetailStack()
        let fire = UUID()
        let police = UUID()

        stack.present(id: fire, source: .fire)
        #expect(stack.top == .fire)
        #expect(!stack.isEmpty)

        stack.present(id: police, source: .police)
        #expect(stack.top == .police)
        #expect(stack.presentations.map(\.source) == [.fire, .police])
    }

    @Test("dismissing the top reveals its parent, not the map")
    func dismissingRevealsParent() {
        let stack = MapDetailStack()
        let parent = UUID()
        let child = UUID()

        stack.present(id: parent, source: .fire)
        stack.present(id: child, source: .fire)
        stack.dismiss(id: child)

        #expect(stack.top == .fire)
        #expect(stack.presentations.map(\.id) == [parent])
        #expect(!stack.isEmpty)
    }

    @Test("a parent that disappears while its child is pushed does not clear the child")
    func childSurvivesParentDisappearance() {
        let stack = MapDetailStack()
        let parent = UUID()
        let child = UUID()

        stack.present(id: parent, source: .police)
        stack.present(id: child, source: .police)
        stack.dismiss(id: parent)

        #expect(stack.top == .police)
        #expect(stack.presentations.map(\.id) == [child])
    }

    @Test("presenting the same identity again moves it to the top")
    func presentingAnIdentityAgainMovesIt() {
        let stack = MapDetailStack()
        let first = UUID()
        let second = UUID()

        stack.present(id: first, source: .fire)
        stack.present(id: second, source: .police)
        stack.present(id: first, source: .fire)

        #expect(stack.presentations.map(\.id) == [second, first])
        #expect(stack.top == .fire)
    }

    @Test("dismissing an identity that is not there changes nothing")
    func dismissingUnknownIdentityDoesNothing() {
        let stack = MapDetailStack()
        let present = UUID()

        stack.present(id: present, source: .fire)
        stack.dismiss(id: UUID())

        #expect(stack.presentations.map(\.id) == [present])
        #expect(stack.top == .fire)
    }
}
