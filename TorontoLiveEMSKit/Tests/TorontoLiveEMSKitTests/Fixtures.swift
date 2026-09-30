import Foundation

/// Frozen payloads for parser tests. Tests never touch the network.
///
/// `liveSnapshot` is a byte-exact capture of the City's live feed, taken
/// 2026-09-29 20:00 — including the trailing newline the feed's response ends with.
/// It is reproduced verbatim rather than reformatted, so the tests exercise the real
/// wire shape, such as the XML-escaped space the feed publishes for a blank Prime
/// Street.
enum Fixtures {

    static let liveSnapshot = "<tfs_active_incidents><update_from_db_time>2026-09-29 20:00:01</update_from_db_time><event><prime_street>M6K</prime_street><cross_streets/><dispatch_time>2026-09-29T18:24:39</dispatch_time><event_num>F26154815</event_num><event_type>MEDICAL</event_type><alarm_lev>0</alarm_lev><beat>426</beat><units_disp>R346</units_disp></event><event><prime_street>&#x20;</prime_street><cross_streets>WOODBINE AVE / KINGSTON RD</cross_streets><dispatch_time>2026-09-29T18:58:30</dispatch_time><event_num>F26154841</event_num><event_type>Vehicle - Personal Injury</event_type><alarm_lev>0</alarm_lev><beat>227</beat><units_disp>P324</units_disp></event><event><prime_street>M4M</prime_street><cross_streets/><dispatch_time>2026-09-29T19:18:53</dispatch_time><event_num>F26154860</event_num><event_type>MEDICAL</event_type><alarm_lev>0</alarm_lev><beat>325</beat><units_disp>T333</units_disp></event><event><prime_street>M9R</prime_street><cross_streets/><dispatch_time>2026-09-29T19:24:52</dispatch_time><event_num>F26154864</event_num><event_type>MEDICAL</event_type><alarm_lev>0</alarm_lev><beat>443</beat><units_disp>P443</units_disp></event><event><prime_street>M6K</prime_street><cross_streets/><dispatch_time>2026-09-29T19:31:54</dispatch_time><event_num>F26154866</event_num><event_type>MEDICAL</event_type><alarm_lev>0</alarm_lev><beat>346</beat><units_disp>P426</units_disp></event><event><prime_street>LAWRENCE AVE, SC</prime_street><cross_streets>3950 LAWRENCE AVE E / 3967 LAWRENCE AVE E</cross_streets><dispatch_time>2026-09-29T19:38:57</dispatch_time><event_num>F26154871</event_num><event_type>Alarm Single Source</event_type><alarm_lev>0</alarm_lev><beat>234</beat><units_disp>P231, P234</units_disp></event><event><prime_street>M5B</prime_street><cross_streets/><dispatch_time>2026-09-29T19:40:42</dispatch_time><event_num>F26154873</event_num><event_type>MEDICAL</event_type><alarm_lev>0</alarm_lev><beat>333</beat><units_disp>P333</units_disp></event><event><prime_street>M1G</prime_street><cross_streets/><dispatch_time>2026-09-29T19:44:55</dispatch_time><event_num>F26154874</event_num><event_type>MEDICAL</event_type><alarm_lev>0</alarm_lev><beat>231</beat><units_disp>A231</units_disp></event><event><prime_street>M5T</prime_street><cross_streets/><dispatch_time>2026-09-29T19:48:20</dispatch_time><event_num>F26154875</event_num><event_type>MEDICAL</event_type><alarm_lev>0</alarm_lev><beat>332</beat><units_disp>P315</units_disp></event><event><prime_street>M4Y</prime_street><cross_streets/><dispatch_time>2026-09-29T19:49:19</dispatch_time><event_num>F26154876</event_num><event_type>MEDICAL</event_type><alarm_lev>0</alarm_lev><beat>312</beat><units_disp>P314</units_disp></event><event><prime_street>M5T</prime_street><cross_streets/><dispatch_time>2026-09-29T19:50:00</dispatch_time><event_num>F26154877</event_num><event_type>MEDICAL</event_type><alarm_lev>0</alarm_lev><beat>315</beat><units_disp>P331</units_disp></event><event><prime_street>SHEPPARD AVE, NY</prime_street><cross_streets>LN E WILSON HEIGHTS S SHEPPARD / WILSON HEIGHTS BLVD</cross_streets><dispatch_time>2026-09-29T19:50:41</dispatch_time><event_num>F26154878</event_num><event_type>Fire - Grass/Rubbish</event_type><alarm_lev>0</alarm_lev><beat>143</beat><units_disp>P143</units_disp></event><event><prime_street>&#x20;</prime_street><cross_streets>ARDAGH ST / JANE ST</cross_streets><dispatch_time>2026-09-29T19:54:42</dispatch_time><event_num>F26154880</event_num><event_type>Vehicle - Personal Injury</event_type><alarm_lev>0</alarm_lev><beat>422</beat><units_disp>P422</units_disp></event></tfs_active_incidents>\n"

    static var liveSnapshotData: Data { Data(liveSnapshot.utf8) }

    /// Synthetic. The feed omits `units_disp` entirely for roughly one incident in
    /// five; the captured snapshot above happens not to contain that shape, so it is
    /// pinned here.
    static let unitsElementAbsent = "<tfs_active_incidents><update_from_db_time>2026-01-01 00:00:00</update_from_db_time><event><prime_street>M1A</prime_street><cross_streets/><dispatch_time>2026-01-01T00:00:01</dispatch_time><event_num>F1</event_num><event_type>MEDICAL</event_type><alarm_lev>0</alarm_lev><beat>111</beat></event></tfs_active_incidents>"

    static var unitsElementAbsentData: Data { Data(unitsElementAbsent.utf8) }

    /// The shape a live capture showed on 2026-09-30: Prime Street is the XML-escaped space
    /// and Cross Street is a lone slash, so both are placeholders and this incident has no
    /// published location at all.
    ///
    /// It was not in the snapshot above, which is why it went unnoticed: the captured feed had
    /// the escaped space paired with a *real* intersection, so the one row where the fallback
    /// had nothing to fall back to was the one row missing.
    static let bothStreetsPlaceholders = "<tfs_active_incidents><update_from_db_time>2026-09-30 13:15:02</update_from_db_time><event><prime_street>&#x20;</prime_street><cross_streets> / </cross_streets><dispatch_time>2026-09-30T13:10:00</dispatch_time><event_num>F26154900</event_num><event_type>MEDICAL</event_type><alarm_lev>0</alarm_lev><beat>111</beat><units_disp>P111</units_disp></event></tfs_active_incidents>"

    static var bothStreetsPlaceholdersData: Data { Data(bothStreetsPlaceholders.utf8) }

    /// Synthetic. Truncated mid-element, so the parser rejects it.
    static let malformed = "<tfs_active_incidents><event><prime_street>M1A"

    static var malformedData: Data { Data(malformed.utf8) }
}
