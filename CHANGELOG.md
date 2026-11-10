# Changelog

## [Unreleased]

## [1.0.1] - 2026-11-10

- Strip every trailing TOC directive, not only `[AllowLoad...]`: `[ExcludeLoadGameType ...]` was checked as part of the path.

## [1.0.0] - 2026-10-18

- Check that every file listed in the TOC, and every `<Script>`/`<Include>` in the XML it loads, exists.
