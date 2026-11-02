import Testing

import TorontoLiveEMSKit

@Suite("Appearance")
struct AppearanceTests {

    @Test("offers the device's setting, light and dark — three choices, not a switch")
    func threeChoices() {
        // A two-way toggle cannot express "follow the device", and a reader who once flipped it
        // could never get back to it. The count is the point, not the order.
        #expect(Appearance.allCases.count == 3)
        #expect(Appearance.allCases.contains(.system))
        #expect(Appearance.allCases.contains(.light))
        #expect(Appearance.allCases.contains(.dark))
    }

    @Test("nothing changes until the setting is opened")
    func standardIsSystem() {
        // The whole reason the default is a value rather than a toggle: an install that never opens
        // Settings follows the device, exactly as it did before the setting existed.
        #expect(Appearance.standard == .system)
    }

    @Test("names itself for the setting that picks it")
    func everyCaseHasALabel() {
        #expect(Appearance.system.label == "System")
        #expect(Appearance.light.label == "Light")
        #expect(Appearance.dark.label == "Dark")
        for appearance in Appearance.allCases {
            #expect(!appearance.label.isEmpty, "\(appearance) has no name")
        }
    }

    @Test("gives each appearance a name of its own")
    func labelsAreDistinct() {
        // They are the three rows of one picker, drawn from here. Two cases sharing a name would show
        // the reader the same choice twice, with nothing but the stored value to tell them apart.
        let labels = Appearance.allCases.map(\.label)
        #expect(Set(labels).count == labels.count)
    }

    @Test("keeps a stable stored value for each")
    func storedValuesAreStable() {
        // These strings live in the reader's preferences. Renaming one silently resets the setting
        // for everyone who has already chosen, with no error and no way to notice.
        #expect(Appearance.system.rawValue == "system")
        #expect(Appearance.light.rawValue == "light")
        #expect(Appearance.dark.rawValue == "dark")
    }

    @Test("survives a round trip through the stored value")
    func roundTripsThroughStorage() {
        // What @AppStorage does with it on every launch.
        for appearance in Appearance.allCases {
            #expect(Appearance(rawValue: appearance.rawValue) == appearance)
        }
    }
}
