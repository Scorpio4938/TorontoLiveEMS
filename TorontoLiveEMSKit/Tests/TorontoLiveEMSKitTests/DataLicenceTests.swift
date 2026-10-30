import Foundation
import Testing

import TorontoLiveEMSKit

@Suite("Open government licences")
struct DataLicenceTests {

    @Test("every licence names its provider, version, source and attribution")
    func identity() throws {
        for licence in DataLicence.allCases {
            #expect(licence.title.hasPrefix("Open Government Licence"))
            #expect(!licence.provider.isEmpty)
            #expect(!licence.version.isEmpty)
            #expect(!licence.updated.isEmpty)
            #expect(licence.attributionStatement
                == "Contains information licensed under the \(licence.title).")

            let url = try #require(licence.url)
            #expect(url.scheme == "https")
        }
    }

    @Test("every licence reproduces the clauses that make it a licence")
    func everyLicenceCarriesTheOperativeText() {
        for licence in DataLicence.allCases {
            let text = licence.fullText

            // A link is not a copy: the text itself has to be here.
            #expect(text.contains("You are encouraged to use the Information"))
            #expect(text.contains("You are free to"))
            #expect(text.contains("Acknowledge the source"))
            #expect(text.contains("Exemptions"))
            #expect(text.contains("Non-endorsement"))
            #expect(text.contains("No Warranty") || text.contains("No warranty"))
            #expect(text.contains("Governing Law"))
            #expect(text.contains("Definitions"))
            #expect(text.contains("Versioning"))
            #expect(text.contains("Personal Information"))
        }
    }

    @Test("the Toronto licence is version 1.0, as the City publishes it")
    func torontoIsComplete() {
        let text = DataLicence.toronto.fullText

        #expect(text.contains("This is version 1.0 of the Open Government Licence – Toronto."))
        #expect(text.contains("Updated: Aug 19, 2013"))
        #expect(text.contains("“Information Provider” means the City of Toronto."))
        #expect(text.contains("Ontario Personal Health Information Protection Act, 2004"))
    }

    @Test("the Canada licence is version 2.0, as the Government publishes it")
    func canadaIsComplete() {
        let text = DataLicence.canada.fullText

        #expect(text.contains("This is version 2.0 of the Open Government Licence – Canada."))
        #expect(text.contains("Date modified: 2022-12-02"))
        #expect(text.contains("“Information Provider” means His Majesty the King in right of Canada."))
        #expect(text.contains("section 3 of the Privacy Act, R.S.C. 1985, c. P-21"))
    }

    @Test("the Ontario licence is version 1.0, as the Government publishes it")
    func ontarioIsComplete() {
        let text = DataLicence.ontario.fullText

        #expect(text.contains("This is version 1.0 of the Open Government Licence – Ontario."))
        #expect(text.contains("Updated: March 27, 2025"))
        #expect(text.contains("\"Information Provider\" means His Majesty the King in right of Ontario."))
        #expect(text.contains("Freedom of Information and Protection of Privacy Act (Ontario)"))
    }

    @Test("the full text keeps its paragraph order")
    func sectionsAreOrdered() {
        for licence in DataLicence.allCases {
            let headings = licence.sections.compactMap(\.heading)
            #expect(headings == [
                "Using Information under this licence",
                "Exemptions",
                "Non-endorsement",
                licence == .ontario ? "No warranty" : "No Warranty",
                "Governing Law",
                "Definitions",
                "Versioning",
            ])
        }
    }
}
