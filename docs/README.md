# Project knowledge base

This directory is the project's source of truth. It is designed to let the student, advisor, and future readers understand what is known, what remains uncertain, and why each analytical choice was made.

## Navigation

- `replication-feasibility.md`: availability of the original article, code, data vintages, and specification details
- `data-availability.md`: feasibility of candidate human-capital outcomes
- `feasibility-report.md`: professor-facing verdict, evidence, work plan, and go/no-go criteria
- `source-register.md`: dated source and access ledger
- `../process-log/`: dated work completed, problems, feedback, and next actions
- `../references/`: paper-by-paper reading notes
- `../environment/`: software and reproduction instructions

## Documentation standard

Every material claim should include a source link and an access date. Every analytical decision should state:

1. the decision;
2. the evidence used;
3. alternatives considered;
4. the reason for the choice;
5. its effect on interpretation; and
6. the date and person responsible.

Use one of four labels so uncertainty is visible:

- **Confirmed** — verified directly from a primary source or the data.
- **Provisional** — plausible but awaiting a specified check or advisor approval.
- **Blocked** — cannot proceed without a missing input or external response.
- **Rejected** — evaluated and not suitable, with the reason retained.

## Public-repository rule

Do not commit restricted datasets, credentials, private advisor correspondence, personal information, or unpublished feedback. Summarize decisions from private conversations without quoting sensitive content. Record dataset licenses before redistributing any data.

## Updating the repository

- Update an audit when evidence changes.
- Add a dated process-log entry at least weekly.
- Link code, tables, or figures from the decision they support.
- Prefer precise statements such as “not located as of 2026-09-09” over unsupported claims that something does not exist.
- Keep the main README concise and use this directory for detail.
