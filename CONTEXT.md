# TorontoLiveEMS

A native iPhone and Mac viewer for Toronto Fire Services active-incident dispatch
data, presenting the same information as the City of Toronto's "Toronto Fire
Active Incidents" page.

## Language

**Incident**:
A single response event dispatched by Toronto Fire Services CAD, and the unit the
app presents as one row.
_Avoid_: Event, call, job, run

**Active Incident**:
An incident that CAD has dispatched and that has not yet cleared. The published
set is always a snapshot of active incidents; there is no clear or close signal,
so an incident leaves the set only by disappearing.
_Avoid_: Open incident, live incident, current incident

**Incident Number**:
The stable identifier CAD assigns to an incident, unique to it and unchanging
across its life. Its number rises with dispatch order, so it orders incidents by
recency; it carries no severity information.
_Avoid_: Event number, event ID, call number, ticket

**Prime Street**:
The primary location value published for an incident. It is a street name for
addressable incidents and an FSA for medical incidents.
_Avoid_: Main street, address, location, street

**Cross Street**:
The two intersecting streets that bound an addressable incident's location.
Empty, or a placeholder slash, for medical incidents.
_Avoid_: Intersection, crossroad, cross

**Dispatch Time**:
The moment CAD dispatched units to an incident.
_Avoid_: Alarm time, created at, start time, reported time

**As-of**:
The publisher's time belonging to the data on screen — for Fire, the snapshot's
`update_from_db_time`; for police calls, the Service's last-write stamp that was
current when those calls were read. It is not the publisher's latest stamp, which
may describe a write the screen has never fetched.
_Avoid_: Last updated, published at, latest stamp

**Incident Type**:
The category CAD assigned to an incident when it was dispatched. The live feed's
vocabulary differs from the open data's, and its full set of values is not
published.
_Avoid_: Event type, call type, category, nature

**Incident Category**:
A coarse label derived from an Incident's CAD code prefix, shown in place of the
full Incident Type on the compact view. An Incident Category is ours; an Incident
Type is the City's.
_Avoid_: Incident type, call type, category, nature

**Alarm Level**:
Toronto Fire Services' response-escalation ordinal, from 0 (initial response) to
6 (29–32 emergency vehicles). It is an incident's measure of severity; the number
of Dispatched Units is the other published indicator of response size.
_Avoid_: Priority, alarm, alarm code

**Dispatched Units**:
The apparatus sent to an incident, each written as a type letter followed by the
number of its fire station.
_Avoid_: Trucks, vehicles, resources, apparatus list

**Dispatched Unit**:
One piece of apparatus sent to an incident, named by its type letter and its fire
station number.
_Avoid_: Truck, vehicle, resource

**Area**:
The run area the City files an incident under, published as a bare station
number. The number is a fire station's, but the area is not necessarily the
station that responded.
_Avoid_: Beat, district, zone, station area

**Station**:
A numbered Toronto fire facility the City publishes: address, municipality,
year built, ward, offices, and a point. It is the entity an Area number names
and the station number a unit's code places it at.
_Avoid_: Firehouse, hall, fire division

**Division**:
A Toronto Police Service patrol area, published as 19 boundary features and
written by the feed as `D14`. It is the entity a police call's Division field
names.
_Avoid_: Fire division, district, zone

**Fire division** is not a term. Toronto Fire publishes no such thing, and the
word Division belongs to the Police Service alone.

**Medical Incident**:
An incident whose Prime Street is an FSA rather than a street, because
patient-related locations are withheld under MFIPPA. The large majority of active
incidents.
_Avoid_: Medical call, ambulance call, EMS incident, patient incident

**FSA**:
A forward sortation area — the first three characters of a postal code, such as
`M6G`. The finest location precision published for a medical incident.
_Avoid_: Postal code, postal area, postcode
