# Toronto's live CAD XML as the live incident source

Live Toronto Fire Services active incidents come from
`https://www.toronto.ca/data/fire/livecad.xml`, the undocumented feed behind
toronto.ca's "Toronto Fire Active Incidents" page. It is not a published API — we
found it by reading the page's inline JavaScript
(`url: "/data/fire/livecad.xml?" + strTxt`).

The Toronto Open Data portal cannot serve this purpose. Its fire datasets
(`Fire Services Emergency Incident Basic Detail`, `fire-incidents`) carry a
`refresh_rate` of **`Annually`**, and medical calls are aggregated to FSAs for
privacy. Open Data publishes no live endpoint of any kind. A live view is
impossible without this feed.

Consequences we accept:

- **Five minutes of staleness, by design.** `update_from_db_time` advances on a
  five-minute cycle. The feed cannot be fresher than that, so the app never polls
  faster.
- **No history.** The feed is a snapshot of *currently active* incidents. There is
  no clear or close signal — an incident leaves the set only by disappearing.
- **Unofficial status.** The URL is unversioned and undocumented, and could change
  without notice. The app should degrade rather than fail if it does.
- **Politeness.** This is the City's server on an undocumented path. The app makes
  one request per launch and one per explicit refresh. There is no polling.
