# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A single multi-stage Dockerfile that builds and packages [Anope](https://github.com/anope/anope) (IRC Services) on Alpine Linux. There is no application source code here — the entire "codebase" is the `Dockerfile`, `.gitlab-ci.yml`, and `renovate.json`. Anope's own source is pulled at build time from GitHub via the `ADD https://github.com/anope/anope.git#${ANOPE_VERSION}` line.

## Architecture

- **Stage `base`**: pinned `alpine` image (tag + digest, kept in sync by Renovate).
- **Stage `builder`** (from `base`): installs build toolchain (gcc/g++/ninja/cmake + dev libs for gnutls/sqlite/mariadb/pcre2), fetches Anope source at `ANOPE_VERSION`, symlinks the modules listed in `EXTRASMODULES` from `modules/extra/` into `modules/` so they get built in, then configures with CMake (`INSTDIR=/anope/`, `DEFUMASK=077`, `RELEASE`) and builds with Ninja.
- **Final stage** (from `base` again): installs only the runtime shared libs (no compilers), copies the installed `/anope/` tree from the builder stage owned by a fixed unprivileged `anope` user (uid 10000), and runs as that user. Entrypoint: `/anope/bin/anope -n` (foreground, no fork — required for containers).

To add or remove a bundled module, edit the `EXTRASMODULES` build arg — it must match filenames under `anope/modules/extra/` in the upstream repo.

## Versioning / dependency updates

Renovate manages version bumps automatically. `renovate.json` extends the org's internal presets (`oaklab/renovate-presets` and `oaklab/renovate-presets:docker`), not the public `config:recommended` — check that preset repo for the base rules/managers in effect rather than assuming defaults.
- `ARG ANOPE_VERSION=...` is tracked via the `# renovate: datasource=github-tags depName=anope/anope` comment directly above it — do not remove or reword this comment, Renovate parses it.
- The `alpine` base image tag and digest are updated automatically by Renovate's Docker manager.
- Do not manually bump versions/digests in a way that fights Renovate's MRs; let it open the update MRs.

## CI/CD

`.gitlab-ci.yml` is minimal: it includes a shared org-wide CI component (`oaklab/ci-templates/oci-publish@11`) that handles building and publishing the image to Docker Hub (`huncrys/anope`) under the GPL-2.0 license declaration. There are no custom jobs, lint steps, or tests defined in this repo — verifying a change means confirming the image builds and that Anope starts.

## Making changes

- Test a Dockerfile change locally with `docker build -t anope-test .` before committing; there's no CI test suite to catch build breakage other than the publish pipeline itself.
- Keep the `EXTRASMODULES` list space-separated and matching real `modules/extra/*.cpp` filenames (without the `.cpp` extension) in the anope source tree at the pinned version.
