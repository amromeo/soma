# Send-Out Tracking Workstation: User Tipsheet

This app is meant to support your daily send-out work, not force you into a new workflow.

## What You Use Each Tab For

### Recently Received

Use this as your main inbound PDF worklist.

You can:

- see newly received PDFs
- sort by newest first
- view the stored full file path
- open the PDF if the file exists
- mark the PDF as reviewed
- mark the PDF as worked
- mark the PDF as worked outside the system
- assign the PDF to a staff member
- add or update notes

### Pending

Use this to see send-out orders that are still not verified in the LIS.

Focus on:

- aging orders
- expected turnaround
- whether an order is nearing or past due

### Overdue

Use this to focus on the highest-risk backlog first.

You can:

- filter by reference lab
- sort by longest overdue
- review quick summary counts

### Metrics

Use this for a quick operational snapshot.

It shows:

- pending send-out count
- recent PDF receipt count
- overdue order count
- worked PDF count
- turnaround summaries
- simple volume trends

### Matching

This tab is a placeholder for future OCR-assisted candidate matching.

## Suggested Daily Workflow

1. Open `Recently Received`.
2. Review the newest PDFs first.
3. Open the file if needed.
4. Mark it as:
   - `Reviewed`
   - `Worked`
   - `Worked outside system`
5. Assign or add notes when helpful.
6. Check `Pending` and `Overdue` for unresolved send-outs.

## Status Meanings

### PDF worked status

- `new`: newly received and not yet worked
- `reviewed`: looked at, but not fully worked
- `worked`: work completed in relation to the PDF
- `worked_outside_system`: work happened outside the app
- `archived`: no longer active in the queue

### Order status concepts

- `pending`: no LIS verified result yet
- `verified`: LIS result verification is present
- `overdue`: pending and beyond expected turnaround

## Important Notes

- The LIS remains the source of truth for final turnaround time.
- A received PDF does not automatically mean the order is finalized in LIS.
- You do not need to manually link PDFs to orders in this MVP.
- Notes are helpful for team visibility, especially if work happened outside the app.

## If the Open Button Does Not Work

Check these things:

- the PDF path shown in the table is correct
- the file still exists in that location
- the machine running the app has access to that folder

If the file cannot be opened automatically, use the visible path to locate it directly.

## If Data Looks Wrong

- reload the app data
- confirm the latest LIS export has been loaded
- confirm the latest inbound PDF feed has been loaded
- ask support if the pins data needs to be refreshed

