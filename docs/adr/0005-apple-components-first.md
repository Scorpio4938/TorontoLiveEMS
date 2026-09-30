# Apple's components first, with the compact table as a deliberate exception

Where the platform offers a component for a job, we use it and let it look like itself. A
plain `ToolbarItem` and `Button` for refresh, so the system draws the button. The system's
navigation title rather than a hand-styled one. `LabeledContent` for label-and-value rows.
`ContentUnavailableView` for empty and error states. The app should read as an Apple app on
the platform it happens to be running on — which is also the least design work, and the
most behaviour for free: Dynamic Type, VoiceOver, and whatever the system's current look is
at the time.

The exception is the compact table, which is hand-built from an `HStack` of `Text`s with
equal-width frames.

That exception has one specific cause. Apple ships a `Table`, and its own documentation says
what it does on a phone:

> On iPhone or in a compact horizontal size class environment… the table has limited space
> to display its columns.
>
> On iOS… **tables don't show headers and collapse all columns after the first.**

Apple's component for this job declines it on the device this app is built for. A
five-column incident table on a phone is therefore not something Apple's design language
offers, and using their component would mean not having the table — not having a tidier
one.

Consequences we accept:

- **The table is ours, and so are its costs.** An invisible `chevron.right` in the column
  header reserves the width the disclosure chevron takes from every row, so the labels sit
  over the values. There is no platform component that does this for us.
- **The title moves while the column header stays.** The system's large title collapses on
  scroll; the column header is a pinned section header, because a table whose column labels
  scroll away is a grid of unlabelled numbers. Somebody will find this inconsistent and want
  to pin the title too. That was tried and rejected: it means hand-styling the title, which
  is a larger departure than the one it fixes.
- **This is an exception, not an oversight.** Replacing the table with `Table` on a phone
  would not make it better. It would delete it.
