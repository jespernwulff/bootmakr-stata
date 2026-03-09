# CLAUDE.md — Project Rules and Session Log

Read this file in full before doing anything in this project.

## Rules

1. **Never delete data.** Under no circumstances are you ever to delete data.
2. **Never delete a program.** Under no circumstances are you ever to delete a program.
3. **Use `./legacy/` for archiving.** When reorganizing, move existing data and programs into `./legacy/`. When placing files into new organized directories, COPY them (do not move) from `./legacy/`.
4. **Stay in this folder.** Under no circumstances are you ever to go up out of this one folder called `bootmakr`. All work happens within `bootmakr/` and its subdirectories.
5. **Update the session log.** At the end of every session, update the session log below with what was changed and what to do next.

## Session Log

### 2026-03-09 (session 1)
**What was done:**
- Created `README.md` documenting the full directory structure, file inventory, and package overview.
- Created `CLAUDE.md` (this file) with project rules and session log.
- No programs or data were modified.

### 2026-03-09 (session 2)
**What was done:**
- Copied `bootmakr.do` to `legacy/bootmakr.do` (archived original).
- Created `bootmakr.ado` from `bootmakr.do`: removed `capture program drop bootmakr` (not needed in `.ado` files), added version header comment. All program logic unchanged.
- Created `bootmakr.sthlp` — full SMCL help file with syntax, description, all options, stored results, and examples.
- Created `stata.toc` and `bootmakr.pkg` — package infrastructure for `net install`.
- Updated `README.md` with installation instructions, quick start examples, and updated directory structure.
- Author: Jesper N. Wulff. Repo: `jespernwulff/bootmakr` (not yet created on GitHub).

**What to do next:**
- Create the GitHub repo and push.
- Test `net install` from the raw GitHub URL.
- Consider adding a dedicated examples `.do` file.
- Consider adding a version number scheme and changelog.

### 2026-03-09 (session 3)
**What was done:**
- Repo name changed to `jespernwulff/bootmakr-stata` (separate from R package). Updated all URLs in README, `.pkg`, and `.sthlp`.
- Initialized git, committed, and pushed to GitHub.
- Fixed display formatting bug: long variable names (e.g., `directlyharmed`) broke the table layout. Column widths are now dynamic, computed from the longest row label with a minimum of 13 characters.
- Replaced all examples (help file + README) with working Darfur data examples: standard bootstrap, clustered bootstrap, multiple kd with plot, group benchmark, convergence diagnostics, and saving/inspecting bootstrap draws.
- Added References section to both `bootmakr.sthlp` and `README.md` citing Cinelli & Hazlett (2020), Cinelli, Ferwerda & Hazlett (2024), and Lonati & Wulff (2026).
- Archived `bootmakr_examples_help_file.do` to `legacy/`.

**What to do next:**
- Commit and push session 3 changes.
- Test `net install` end-to-end from the GitHub URL.
- Test all help file examples run without error in Stata.
- Consider adding a version number scheme and changelog.
