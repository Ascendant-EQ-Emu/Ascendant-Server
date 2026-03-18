# Ascendant Server

Ascendant Server is a community-maintained server project based on [EQEmu](https://github.com/EQEmu/EQEmu), preserving custom code, server-side content, tooling, and a clean baseline for compatible community-run instances.

## Purpose

This repository exists to preserve and evolve the Ascendant server project in an open way, regardless of the particular operator hosting the Ascendant Server. The Ascendant server utilizes this code and writes back; however, this is an open and community-owned repository.

While the goal is to make the codebase, server-side content, and project structure maintainable by a trusted and open community, live player data and sensitive operational materials for running a live Ascendant server instance remain private. Backups of the Ascendant server database may be part of this open community with privacy controls in place. The server is viewed as an open project.

## What This Repository Contains

This repository is organized around three primary directories:

- `/code` — the server codebase and source-level customizations
- `/server` — server-side scripts, quests, content, configuration templates, and related project files
- `/database` — compressed Ascendant database content intended to be imported on top of a compatible base PEQ database

This repository may include:

- custom code changes and source modifications
- server-side quests, plugins, and scripts
- clean baseline server files
- project tooling and sync/update scripts
- documentation for maintainers and contributors
- compressed database content packages for Ascendant-specific server data

## What This Repository Does Not Contain

This repository is not intended to expose the live production environment for any specific Ascendant server.

The public/community repository excludes sensitive and operator-private materials, including:

- live player accounts and character data
- private production backups
- authentication secrets and private config values
- operator-only runtime files
- private moderation or administrative records
- other sensitive live-environment artifacts

Some files are intentionally excluded from sync and version control for this reason.

## Project Model

This project separates the **community-maintained repository** from any **live operated server**.

That means:

- the repository is the shared community codebase and baseline project snapshot
- a live server is an operator-run deployment of that codebase
- live player data remains private, however periodic database backups may become part of the community property with controls in place
- continuity of the project does not depend on one person continuing to host the live server

## Upstream Base

Ascendant Server is based on EQEmu and includes Ascendant-specific modifications and project structure layered on top of that upstream work.

Upstream project:

- EQEmu: https://github.com/EQEmu/EQEmu

Please see the upstream project for original source history, documentation, and additional context.

## Installation / Deployment

A compatible Ascendant instance is intended to be built on top of a normal Akk-Stack / PEQ installation, with this repository layered over that base.

In general, the process is:

1. install Akk-Stack and complete a normal PEQ database setup
2. replace the default `/code` and `/server` folders with the versions from this repository
3. import the Ascendant database content package from `/database`
4. complete any normal build, compile, or service startup steps required by your environment

The database package included in this repository is intended to be imported **on top of** an existing compatible PEQ database. It contains Ascendant-specific content for selected tables, along with schema-only creation for required custom tables such as `login_server_account_links`.

It is **not** intended to replace a full PEQ install, and it does not include local environment-specific data such as accounts, login server configuration, launcher settings, Spire data, or other runtime/server-specific records.

### Database Import

The compressed database package is located at:

`database/ascendant_content.sql.gz`

Import it into your existing PEQ database with:

```bash
gunzip -c database/ascendant_content.sql.gz | mysql -u root -p peq
```

You should perform this step only after you have already installed Akk-Stack, completed the base PEQ setup, and replaced the repository `code` and `server` folders with the Ascendant versions.

## Repository Workflow

This repository is maintained using a staged sync workflow.

In general:

1. source files are maintained in live working directories
2. safe project files are synced into this repository
3. excluded private/runtime files are left out
4. changes are reviewed, committed, and pushed here

The `sync_from_live.sh` script exists to help maintain that process in a repeatable way.

## Contributing

Contributions are welcome from trusted maintainers and community contributors.

Before contributing, please review:

- `GOVERNANCE.md`
- `CONTRIBUTING.md`
- `SECURITY.md`

Contributors should not submit:

- secrets or credentials
- live player data
- private backups
- sensitive operator-only materials
- content they do not have the right to contribute

## Stewardship

This project is overseen by a small group of **Community Stewards** who share responsibility for continuity, repository administration, and long-term project preservation.

For GitHub permission purposes, some Community Stewards may hold organization owner permissions, but stewardship is exercised on behalf of the project and community rather than any one individual.

## Security

If sensitive material is accidentally included in the repository, or if you discover a security issue, do not post it publicly in an issue.

Please follow the process described in `SECURITY.md`.

## License

This project is distributed under the terms of the **GNU General Public License v3.0 (GPL-3.0)**.

See the `LICENSE` file for details.

## Status

This repository is in active organization and cleanup as the project transitions into a longer-term community-maintained structure.

Documentation, contribution practices, and project organization will continue to improve over time.
