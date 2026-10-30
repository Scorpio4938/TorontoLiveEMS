import Foundation

/// One heading-and-paragraph block of a licence's text.
public struct LicenceSection: Sendable, Equatable {

    public let heading: String?
    public let paragraphs: [String]

    public init(heading: String? = nil, paragraphs: [String]) {
        self.heading = heading
        self.paragraphs = paragraphs
    }
}

/// The three open-government licences the app is obliged to reproduce.
///
/// **The full text is here, not only a link.** A link is not a copy: it can move, it needs the
/// network, and it leaves a reader unable to check the terms the app says it follows. Each licence
/// is reproduced from its publisher's official page, section by section, with its version and the
/// date the publisher last changed it. The page keeps a link to the source as the authoritative
/// copy, but the text below is readable without one.
///
/// **The metadata is here too**, so the attribution statement, the title and the source address
/// cannot drift from the text beside them. The app composes its short notices from these values.
public enum DataLicence: String, CaseIterable, Equatable, Sendable {

    case toronto
    case canada
    case ontario

    /// The licence's own title, as its publisher writes it.
    public var title: String {
        switch self {
        case .toronto: return "Open Government Licence – Toronto"
        case .canada: return "Open Government Licence – Canada"
        case .ontario: return "Open Government Licence – Ontario"
        }
    }

    /// The body that licenses the information.
    public var provider: String {
        switch self {
        case .toronto: return "City of Toronto"
        case .canada: return "Government of Canada"
        case .ontario: return "Government of Ontario"
        }
    }

    /// The licence version the text below reproduces.
    public var version: String {
        switch self {
        case .toronto: return "1.0"
        case .canada: return "2.0"
        case .ontario: return "1.0"
        }
    }

    /// The publisher's last-updated date, as written on the licence page.
    public var updated: String {
        switch self {
        case .toronto: return "August 19, 2013"
        case .canada: return "December 2, 2022"
        case .ontario: return "March 27, 2025"
        }
    }

    /// The address of the publisher's authoritative copy.
    public var urlString: String {
        switch self {
        case .toronto:
            return "https://www.toronto.ca/city-government/data-research-maps/open-data/open-data-licence/"
        case .canada:
            return "https://open.canada.ca/en/open-government-licence-canada"
        case .ontario:
            return "https://www.ontario.ca/page/open-government-licence-ontario"
        }
    }

    public var url: URL? {
        URL(string: urlString)
    }

    /// The statement each licence says to use when the publisher gives no other one.
    public var attributionStatement: String {
        switch self {
        case .toronto:
            return "Contains information licensed under the Open Government Licence – Toronto."
        case .canada:
            return "Contains information licensed under the Open Government Licence – Canada."
        case .ontario:
            return "Contains information licensed under the Open Government Licence – Ontario."
        }
    }

    /// The licence's full text, in the order the publisher lays it out.
    public var sections: [LicenceSection] {
        switch self {
        case .toronto: return Self.torontoSections
        case .canada: return Self.canadaSections
        case .ontario: return Self.ontarioSections
        }
    }

    /// The whole reproduced text, for the checks that pin the clauses.
    public var fullText: String {
        sections
            .map { section in
                var parts: [String] = []
                if let heading = section.heading { parts.append(heading) }
                parts.append(contentsOf: section.paragraphs)
                return parts.joined(separator: "\n\n")
            }
            .joined(separator: "\n\n")
    }

    // MARK: - Open Government Licence – Toronto

    private static let torontoSections: [LicenceSection] = [
        LicenceSection(paragraphs: [
            "This licence is based on version 1.0 of the Open Government Licence – Ontario, which was developed through public consultation and a collaborative effort by the provincial and federal government. The only substantive changes in this licence are to replace direct references to the Province of Ontario with the City of Toronto and the inclusion of a provision for the Ontario Personal Health Information Protection Act, 2004.",
            "You are encouraged to use the Information that is available under this licence with only a few conditions.",
        ]),
        LicenceSection(heading: "Using Information under this licence", paragraphs: [
            "Use of any Information indicates your acceptance of the terms below.",
            "The Information Provider grants you a worldwide, royalty-free, perpetual, non-exclusive licence to use the Information, including for commercial purposes, subject to the terms below.",
            "You are free to:",
            "Copy, modify, publish, translate, adapt, distribute or otherwise use the Information in any medium, mode or format for any lawful purpose.",
            "You must, where you do any of the above:",
            "Acknowledge the source of the Information by including any attribution statement specified by the Information Provider and, where possible, provide a link to this licence. If the Information Provider does not provide a specific attribution statement, or if you are using Information from several information providers and multiple attributions are not practical for your product or application, you must use the following attribution statement: Contains information licensed under the Open Government Licence – Toronto.",
            "The terms of this licence are important, and if you fail to comply with any of them, the rights granted to you under this licence, or any similar licence granted by the Information Provider, will end automatically.",
        ]),
        LicenceSection(heading: "Exemptions", paragraphs: [
            "This licence does not grant you any right to use:",
            "Personal Information;",
            "Information not accessible under the Ontario Municipal Freedom of Information and Protection of Privacy Act or the Ontario Personal Health Information Protection Act, 2004;",
            "Third party rights the Information Provider is not authorized to licence;",
            "The names, crests, logos, or other official symbols of the Information Provider; and",
            "Information subject to other intellectual property rights, including patents, trade-marks and official marks.",
        ]),
        LicenceSection(heading: "Non-endorsement", paragraphs: [
            "This licence does not grant you any right to use the Information in a way that suggests any official status or that the Information Provider endorses you or your use of the Information.",
        ]),
        LicenceSection(heading: "No Warranty", paragraphs: [
            "The Information is licensed “as is”, and the Information Provider excludes all representations, warranties, obligations, and liabilities, whether express or implied, to the maximum extent permitted by law.",
            "The Information Provider is not liable for any errors or omissions in the Information, and will not under any circumstances be liable for any direct, indirect, special, incidental, consequential, or other loss, injury or damage caused by its use or otherwise arising in connection with this licence or the Information, even if specifically advised of the possibility of such loss, injury or damage.",
        ]),
        LicenceSection(heading: "Governing Law", paragraphs: [
            "This licence is governed by the laws of the province of Ontario and the applicable laws of Canada.",
            "Legal proceedings related to this licence may only be brought against the Information Provider in the courts of the Province of Ontario.",
        ]),
        LicenceSection(heading: "Definitions", paragraphs: [
            "In this licence, the terms below have the following meanings:",
            "“Information” means information resources or Records protected by copyright or other information resources or Records that are offered for use under the terms of this licence.",
            "“Information Provider” means the City of Toronto.",
            "“Personal Information” means “personal information” as defined in subsection 2(1) of the Ontario Municipal Freedom of Information and Protection of Privacy Act.",
            "“Records” means “Records” as defined in subsection 2(1) of the Ontario Municipal Freedom of Information and Protection of Privacy Act.",
            "“You” means the natural or legal person or body of persons corporate or incorporate, acquiring rights under this licence.",
        ]),
        LicenceSection(heading: "Versioning", paragraphs: [
            "This is version 1.0 of the Open Government Licence – Toronto. The Information Provider may make changes to the terms of this licence from time to time and issue a new version of the licence. Your use of the Information will be governed by the terms of the licence in force as of the date you accessed the information.",
            "Updated: Aug 19, 2013",
        ]),
    ]

    // MARK: - Open Government Licence – Canada

    private static let canadaSections: [LicenceSection] = [
        LicenceSection(paragraphs: [
            "You are encouraged to use the Information that is available under this licence with only a few conditions.",
        ]),
        LicenceSection(heading: "Using Information under this licence", paragraphs: [
            "Use of any Information indicates your acceptance of the terms below.",
            "The Information Provider grants you a worldwide, royalty-free, perpetual, non-exclusive licence to use the Information, including for commercial purposes, subject to the terms below.",
            "You are free to:",
            "Copy, modify, publish, translate, adapt, distribute or otherwise use the Information in any medium, mode or format for any lawful purpose.",
            "You must, where you do any of the above:",
            "Acknowledge the source of the Information by including any attribution statement specified by the Information Provider(s) and, where possible, provide a link to this licence.",
            "If the Information Provider does not provide a specific attribution statement, or if you are using Information from several information providers and multiple attributions are not practical for your product or application, you must use the following attribution statement:",
            "Contains information licensed under the Open Government Licence – Canada.",
            "The terms of this licence are important, and if you fail to comply with any of them, the rights granted to you under this licence, or any similar licence granted by the Information Provider, will end automatically.",
        ]),
        LicenceSection(heading: "Exemptions", paragraphs: [
            "This licence does not grant you any right to use:",
            "Personal Information;",
            "Third party rights the Information Provider is not authorized to license;",
            "The names, crests, logos, or other official symbols of the Information Provider; and",
            "Information subject to other intellectual property rights, including patents, trade-marks and official marks.",
        ]),
        LicenceSection(heading: "Non-endorsement", paragraphs: [
            "This licence does not grant you any right to use the Information in a way that suggests any official status or that the Information Provider endorses you or your use of the Information.",
        ]),
        LicenceSection(heading: "No Warranty", paragraphs: [
            "The Information is licensed “as is”, and the Information Provider excludes all representations, warranties, obligations, and liabilities, whether express or implied, to the maximum extent permitted by law.",
            "The Information Provider is not liable for any errors or omissions in the Information, and will not under any circumstances be liable for any direct, indirect, special, incidental, consequential, or other loss, injury or damage caused by its use or otherwise arising in connection with this licence or the Information, even if specifically advised of the possibility of such loss, injury or damage.",
        ]),
        LicenceSection(heading: "Governing Law", paragraphs: [
            "This licence is governed by the laws of the province of Ontario and the applicable laws of Canada.",
            "Legal proceedings related to this licence may only be brought in the courts of Ontario or the Federal Court of Canada.",
        ]),
        LicenceSection(heading: "Definitions", paragraphs: [
            "In this licence, the terms below have the following meanings:",
            "“Information” means information resources protected by copyright or other information that is offered for use under the terms of this licence.",
            "“Information Provider” means His Majesty the King in right of Canada.",
            "“Personal Information” means “personal information” as defined in section 3 of the Privacy Act, R.S.C. 1985, c. P-21.",
            "“You” means the natural or legal person, or body of persons corporate or incorporate, acquiring rights under this licence.",
        ]),
        LicenceSection(heading: "Versioning", paragraphs: [
            "This is version 2.0 of the Open Government Licence – Canada. The Information Provider may make changes to the terms of this licence from time to time and issue a new version of the licence. Your use of the Information will be governed by the terms of the licence in force as of the date you accessed the information.",
            "Date modified: 2022-12-02",
        ]),
    ]

    // MARK: - Open Government Licence – Ontario

    private static let ontarioSections: [LicenceSection] = [
        LicenceSection(paragraphs: [
            "You are encouraged to use the Information that is available under this licence with only a few conditions. All materials licensed under the Open Government Licence – Ontario have been clearly labelled on the page.",
        ]),
        LicenceSection(heading: "Using Information under this licence", paragraphs: [
            "Use of any Information indicates your acceptance of the terms below.",
            "The Information Provider grants you a worldwide, royalty-free, perpetual, non-exclusive licence to use the Information, including for commercial purposes, subject to the terms below.",
            "You are free to:",
            "Copy, modify, publish, translate, adapt, distribute or otherwise use the Information in any medium, mode or format for any lawful purpose.",
            "You must, where you do any of the above:",
            "Acknowledge the source of the Information by including any attribution statement specified by the Information Provider(s) and, where possible, provide a link to this licence.",
            "If the Information Provider does not provide a specific attribution statement, or if you are using Information from several Information Providers and multiple attributions are not practical for your product or application, you must use the following attribution statement:",
            "Contains information licensed under the Open Government Licence – Ontario.",
            "The terms of this licence are important, and if you fail to comply with any of them, the rights granted to you under this licence, or any similar licence granted by the Information Provider, will end automatically.",
        ]),
        LicenceSection(heading: "Exemptions", paragraphs: [
            "This licence does not grant you any right to use:",
            "Personal Information;",
            "Information or Records not accessible under the Freedom of Information and Protection of Privacy Act (Ontario);",
            "Third party rights the Information Provider is not authorized to license;",
            "The names, crests, logos, or other official symbols of the Information Provider; and",
            "Information subject to other intellectual property rights, including patents, trade-marks and official marks.",
        ]),
        LicenceSection(heading: "Non-endorsement", paragraphs: [
            "This licence does not grant you any right to use the Information in a way that suggests any official status or that the Information Provider endorses you or your use of the Information.",
        ]),
        LicenceSection(heading: "No warranty", paragraphs: [
            "The Information is licensed \"as is\", and the Information Provider excludes all representations, warranties, obligations, and liabilities, whether express or implied, to the maximum extent permitted by law.",
            "The Information Provider is not liable for any errors or omissions in the Information, and will not under any circumstances be liable for any direct, indirect, special, incidental, consequential, or other loss, injury or damage caused by its use or otherwise arising in connection with this licence or the Information, even if specifically advised of the possibility of such loss, injury or damage.",
        ]),
        LicenceSection(heading: "Governing Law", paragraphs: [
            "This licence is governed by the laws of the Province of Ontario and the applicable laws of Canada.",
            "Legal proceedings related to this licence may only be brought in the courts of Ontario.",
        ]),
        LicenceSection(heading: "Definitions", paragraphs: [
            "In this licence, the terms below have the following meanings:",
            "\"Information\" means information resources or Records protected by copyright or other information or Records that are offered for use under the terms of this licence.",
            "\"Information Provider\" means His Majesty the King in right of Ontario.",
            "\"Personal Information\" has the meaning set out in section 2(1) of Freedom of Information and Protection of Privacy Act (Ontario).",
            "\"Records\" has the meaning of \"record\" as set out in the Freedom of Information and Protection of Privacy Act (Ontario).",
            "\"You\" means the natural or legal person, or body of persons corporate or incorporate, acquiring rights under this licence.",
        ]),
        LicenceSection(heading: "Versioning", paragraphs: [
            "This is version 1.0 of the Open Government Licence – Ontario. The Information Provider may make changes to the terms of this licence from time to time and issue a new version of the licence. Your use of the Information will be governed by the terms of the licence in force as of the date you accessed the information.",
            "Updated: March 27, 2025",
            "Published: June 18, 2013",
        ]),
    ]
}
