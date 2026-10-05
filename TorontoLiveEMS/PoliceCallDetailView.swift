import MapKit
import SwiftUI
import TorontoLiveEMSKit

/// Everything the Service publishes about one call.
///
/// **The published values, not our renderings of them.** The table shortens a call type and turns an
/// instant into a clock time because width is scarce there; on a screen with room the published
/// value is the honest one. The same rule the fire detail view follows, for the same reason.
///
/// **The code is shown beside the words rather than instead of them.** It is what the Service
/// publishes, and this app does not decode it: the Service publishes no legend for these codes, so
/// the app gathers the ones it reads and shows the Service's own words beside each rather than
/// inventing any. The Code row opens that list. See ADR-0006.
struct PoliceCallDetailView: View {

    let call: PoliceCall

    /// The codes the app has read, for the list the Code row opens.
    ///
    /// Passed in from the page rather than looked up here, because a view of one call has no way to
    /// know what else has arrived — and the list is only worth opening if it is more than this call.
    let callTypes: [PoliceCallType]

    @AppStorage(SettingsKey.dispatchTimeFormat)
    private var dispatchTimeFormat: DispatchTimeFormat = .twelveHour

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: call.latitude, longitude: call.longitude)
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Call Type", value: call.callType)

                // Tappable, so the code is something a reader can follow rather than something they
                // are told about. The screen behind it says what the list is and is not.
                NavigationLink {
                    CallTypeCodeList(callTypes: callTypes)
                } label: {
                    LabeledContent("Code", value: call.callTypeCode)
                }

                LabeledContent("Division", value: call.division)
                // The instant, rendered in the reader's own clock. The Service publishes milliseconds
                // since 1970, which is an instant rather than a time of day, so there is no published
                // wall-clock string to show instead.
                LabeledContent(
                    "Occurrence Time",
                    value: DispatchTimestamp.clockTime(
                        call.occurrenceTime,
                        format: dispatchTimeFormat
                    )
                )
            } header: {
                Text("Call")
            } footer: {
                Text("The code is the Service's own, shown as published. There is no published legend for these codes — tapping the code lists the ones this app has read, with the Service's own words beside each.")
            }

            Section {
                // The Service publishes the nearest intersection rather than an address, so this is
                // the whole of what it said about where the call was.
                LabeledContent("Intersection", value: call.crossStreets ?? NotProvided.mark)

                // **The published point, as numbers as well as a dot.**
                //
                // On the police detail view and not on the fire one, and the difference is not a
                // preference: the Service publishes a latitude and a longitude and the City
                // publishes neither. The fire detail view's map is drawn from a coordinate the
                // *app* worked out by asking Apple where a street is, and a number this app derived
                // has no business being dressed up as a published one. Here the number is the datum,
                // and a reader who wants to check it somewhere else can read it off.
                LabeledContent("Latitude", value: coordinateText(call.latitude))
                LabeledContent("Longitude", value: coordinateText(call.longitude))

                // A row of its own rather than inside the rows above, the way the fire detail view
                // does it. The map is a place, not a field.
                LocationMap(coordinate: coordinate)
            } header: {
                Text("Location")
            } footer: {
                Text("The point is the Service's own, as published. Calls are published at the nearest intersection rather than at an address, and a call that is not here is not evidence that nothing happened.")
            }
        }
        .navigationTitle(call.callType)
    }

    /// Six decimal places — about a tenth of a metre.
    ///
    /// Finer than any map this app draws, and no finer than that: the Service publishes an
    /// intersection, so a coordinate given to fourteen places would dress a published point up as a
    /// survey. The full double is in the model for anything that needs it.
    private func coordinateText(_ value: Double) -> String {
        String(format: "%.6f", value)
    }
}

/// One call's point, on a map.
///
/// **A pin, which a postal area may never be.** The Service publishes a point, so drawing one claims
/// nothing: where the fire feed publishes a neighbourhood and ADR-0004 forbids putting a pin on it,
/// here the point is exactly what was published.
private struct LocationMap: View {

    let coordinate: CLLocationCoordinate2D

    var body: some View {
        Map(
            initialPosition: .region(
                IncidentMapScale.region(around: coordinate, isArea: false)
            ),
            interactionModes: [.pan, .zoom]
        ) {
            Annotation("", coordinate: coordinate) {
                Circle()
                    .fill(Color.primary)
                    .frame(width: 13, height: 13)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    .shadow(radius: 1)
            }
            .annotationTitles(.hidden)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .listRowInsets(EdgeInsets())
    }
}
