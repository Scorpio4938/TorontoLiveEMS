import Foundation
import Testing

import TorontoLiveEMSKit

/// The generated boundary file, checked against facts that do not come from the file.
///
/// These are not tests of code so much as tests of data: that the resource is actually in the
/// bundle, that its coordinates are degrees in Toronto rather than metres in a projection, and
/// that its areas are the size of areas. A boundary file can be wrong in ways that still draw a
/// plausible map, and every one of them is caught here instead of on a screen.
@Suite("Postal areas")
struct PostalAreasTests {

    private var areas: PostalAreas { PostalAreas.bundled }

    /// Toronto's own corner of the world, generously bounded: the City spans roughly latitude
    /// 43.58 … 43.86 and longitude −79.64 … −79.12.
    private let toronto = (latitudes: 43.5 ... 43.9, longitudes: -79.7 ... -79.1)

    /// The area of a ring, by spherical excess.
    ///
    /// The same figure a GIS reports for the same ring, and independent of the projection the
    /// source file was written in — which is the point: it is how a wrong unprojection is caught.
    /// Degrees have to be turned into radians, and the sphere is the conventional mean radius.
    private func squareKilometres(of ring: [PostalAreas.Point]) -> Double {
        let radius = 6371.0088
        let radians = Double.pi / 180
        var total = 0.0
        for index in ring.indices {
            let first = ring[index]
            let second = ring[(index + 1) % ring.count]
            total += (second.longitude - first.longitude) * radians
                * (2 + sin(first.latitude * radians) + sin(second.latitude * radians))
        }
        return abs(total * radius * radius / 2)
    }

    private func area(of fsa: String) -> Double {
        guard let pieces = areas.areas(for: fsa) else { return 0 }
        return pieces.reduce(0) { running, piece in
            running
                + squareKilometres(of: piece.outer)
                - piece.holes.reduce(0) { $0 + squareKilometres(of: $1) }
        }
    }

    // MARK: - the file is there

    @Test("the bundled file loads")
    func theFileLoads() {
        #expect(areas.count == 96, "Toronto has 96 FSAs in the 2021 boundary file")
        #expect(areas.simplificationMetres == 10)
        #expect(!areas.attribution.isEmpty)
    }

    @Test("every code is a Toronto FSA, in order")
    func codesAreToronto() {
        #expect(areas.codes.count == 96)
        #expect(areas.codes == areas.codes.sorted())
        for code in areas.codes {
            #expect(code.count == 3, "\(code) is not three characters")
            #expect(code.hasPrefix("M"), "\(code) is not Toronto's postal district")
            #expect(code.dropFirst().first?.isNumber == true, "\(code) has no district digit")
            #expect(code.last?.isLetter == true, "\(code) does not end in a letter")
        }
    }

    @Test("the licence it ships under is stated")
    func attributionNamesTheLicence() {
        #expect(areas.attribution.contains("Open Government Licence"))
        #expect(areas.attribution.contains("Statistics Canada"))
    }

    // MARK: - the coordinates are degrees, in Toronto

    @Test("every point is inside Toronto")
    func pointsLandInToronto() {
        for code in areas.codes {
            for piece in areas.areas(for: code) ?? [] {
                for point in piece.outer + piece.holes.flatMap { $0 } {
                    #expect(
                        toronto.latitudes.contains(point.latitude),
                        "\(code) has latitude \(point.latitude)"
                    )
                    #expect(
                        toronto.longitudes.contains(point.longitude),
                        "\(code) has longitude \(point.longitude)"
                    )
                }
            }
        }
    }

    // MARK: - the areas are the size of areas

    @Test("the FSAs add up to the city")
    func areasAddUpToTheCity() {
        let total = areas.codes.reduce(0.0) { $0 + area(of: $1) }
        #expect(
            total > 600 && total < 670,
            "the 96 FSAs cover \(total) km², and the City of Toronto is about 630 km²"
        )
    }

    @Test("a known FSA is the size it actually is")
    func knownAreas() {
        #expect(abs(area(of: "M6K") - 2.76) < 0.3, "M6K measured \(area(of: "M6K")) km²")
        #expect(abs(area(of: "M5T") - 1.47) < 0.3, "M5T measured \(area(of: "M5T")) km²")
        #expect(area(of: "M1B") > area(of: "M5C"), "Scarborough is larger than the core")
    }

    // MARK: - the shapes themselves

    @Test("M6K is one ring, and it is in Parkdale")
    func m6kIsParkdale() throws {
        let pieces = try #require(areas.areas(for: "M6K"))
        #expect(pieces.count == 1)
        let outer = try #require(pieces.first?.outer)
        // 37 in the file, which closes the ring by repeating its first point; the package drops
        // that repeat, so the ring that reaches a map has 36 corners.
        #expect(outer.count == 36)
        #expect(pieces.first?.holes.isEmpty == true)

        let latitudes = outer.map(\.latitude)
        let longitudes = outer.map(\.longitude)
        let middleLatitude =
            (try #require(latitudes.min()) + (try #require(latitudes.max()))) / 2
        let middleLongitude =
            (try #require(longitudes.min()) + (try #require(longitudes.max()))) / 2
        #expect(abs(middleLatitude - 43.64) < 0.02)
        #expect(abs(middleLongitude - -79.43) < 0.03)
    }

    @Test("twelve FSAs are in more than one piece")
    func someAreasAreSplit() {
        let split = areas.codes.filter { (areas.areas(for: $0)?.count ?? 0) > 1 }
        #expect(split.count == 12, "the islands and split neighbourhoods: \(split)")

        let pieces = areas.codes.reduce(0) { $0 + (areas.areas(for: $1)?.count ?? 0) }
        #expect(pieces == 156, "156 rings went into the generator and 156 must come out")
    }

    @Test("one FSA has a hole, and it is kept")
    func oneHoleIsKept() throws {
        let withHoles = areas.codes.filter { code in
            (areas.areas(for: code) ?? []).contains { !$0.holes.isEmpty }
        }
        #expect(withHoles == ["M6P"])

        let piece = try #require(areas.areas(for: "M6P")?.first)
        let hole = try #require(piece.holes.first)
        #expect(hole.count == 6)
    }

    // MARK: - the box, which both maps use

    @Test("M6K's box is its own, to five decimals")
    func m6kBounds() throws {
        let bounds = try #require(areas.bounds(for: "M6K"))
        #expect(abs(bounds.south - 43.63331) < 0.00001)
        #expect(abs(bounds.north - 43.65273) < 0.00001)
        #expect(abs(bounds.west - -79.44841) < 0.00001)
        #expect(abs(bounds.east - -79.41044) < 0.00001)

        // The callout hangs above the middle of the box, never from its centre.
        #expect(bounds.northCentre.latitude == bounds.north)
        #expect(bounds.northCentre.longitude == bounds.centre.longitude)
        #expect(bounds.northCentre.latitude > bounds.centre.latitude)
    }

    @Test("the box of a split FSA contains every piece")
    func splitAreaBounds() throws {
        // M5J is the Harbourfront and the Islands: twenty separate rings.
        let pieces = try #require(areas.areas(for: "M5J"))
        #expect(pieces.count == 20)

        let bounds = try #require(areas.bounds(for: "M5J"))
        for piece in pieces {
            for point in piece.outer {
                #expect(point.latitude >= bounds.south && point.latitude <= bounds.north)
                #expect(point.longitude >= bounds.west && point.longitude <= bounds.east)
            }
        }
        // Wider than any single island, which is the point of a union.
        #expect(bounds.latitudeSpan > 0.03)
        #expect(bounds.longitudeSpan > 0.05)
    }

    @Test("a box for an FSA the file does not know is nil")
    func boundsForUnknownFSA() {
        #expect(areas.bounds(for: "K1A") == nil)
        #expect(areas.bounds(for: "") == nil)
    }

    // MARK: - looking one up

    @Test("a lookup is case-blind, and an unknown FSA is nil rather than empty")
    func lookup() {
        #expect(areas.areas(for: "M6K")?.count == 1)
        #expect(areas.areas(for: "m6k")?.count == 1)
        #expect(areas.areas(for: "K1A") == nil, "Ottawa is not in this file")
        #expect(areas.areas(for: "M0M") == nil)
        #expect(areas.areas(for: "") == nil)
    }

    // MARK: - a broken file is refused

    @Test("something that is not the file is refused")
    func refusesRubbish() {
        #expect(throws: (any Error).self) {
            try PostalAreas(data: Data("not json".utf8))
        }
    }

    @Test("a geometry this file does not use is refused")
    func refusesOtherGeometry() {
        let document = """
        {"attribution":"","simplifiedToMetres":10,"features":[
          {"properties":{"fsa":"M6K"},"geometry":{"type":"Point","coordinates":[1,2]}}
        ]}
        """
        #expect(throws: PostalAreasError.unsupportedGeometry("Point")) {
            try PostalAreas(data: Data(document.utf8))
        }
    }

    @Test("a ring with two corners is refused")
    func refusesADegenerateRing() {
        let document = """
        {"attribution":"","simplifiedToMetres":10,"features":[
          {"properties":{"fsa":"M6K"},"geometry":{"type":"Polygon",
            "coordinates":[[[-79.4,43.6],[-79.5,43.7]]]}}
        ]}
        """
        #expect(throws: PostalAreasError.malformedRing(fsa: "M6K")) {
            try PostalAreas(data: Data(document.utf8))
        }
    }

    // MARK: - the format, on a document small enough to reason about

    @Test("coordinates arrive as latitude and longitude, and the closing repeat is dropped")
    func readsAGeoJSONPolygon() throws {
        let document = """
        {"attribution":"test","simplifiedToMetres":5,"features":[
          {"properties":{"fsa":"m9z"},"geometry":{"type":"Polygon","coordinates":[
            [[-79.5,43.6],[-79.4,43.6],[-79.4,43.7],[-79.5,43.6]]
          ]}}
        ]}
        """
        let parsed = try PostalAreas(data: Data(document.utf8))
        let piece = try #require(parsed.areas(for: "M9Z")?.first)

        #expect(piece.outer.count == 3, "GeoJSON repeats the first point; drawing does not")
        #expect(piece.outer.first == PostalAreas.Point(latitude: 43.6, longitude: -79.5))
        #expect(piece.outer.first?.longitude == -79.5, "longitude is written first in GeoJSON")
        #expect(parsed.simplificationMetres == 5)
        #expect(parsed.attribution == "test")
    }

    @Test("a hole travels with the ring that contains it")
    func readsAHole() throws {
        let document = """
        {"attribution":"test","simplifiedToMetres":5,"features":[
          {"properties":{"fsa":"M9Z"},"geometry":{"type":"MultiPolygon","coordinates":[
            [[[-79.5,43.6],[-79.4,43.6],[-79.4,43.7],[-79.5,43.6]]],
            [[[-79.3,43.6],[-79.2,43.6],[-79.2,43.7],[-79.3,43.6]],
             [[-79.28,43.62],[-79.22,43.62],[-79.22,43.66],[-79.28,43.62]]]
          ]}}
        ]}
        """
        let parsed = try PostalAreas(data: Data(document.utf8))
        let pieces = try #require(parsed.areas(for: "M9Z"))

        #expect(pieces.count == 2)
        #expect(pieces[0].holes.isEmpty)
        #expect(pieces[1].holes.count == 1)
        #expect(pieces[1].holes[0].count == 3)
    }
}
