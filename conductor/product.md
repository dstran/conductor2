# Product Definition

## Overview

conductor2 is an OpenCode port of the Conductor spec-driven development
workflow. It provides commands, a canonical skill, and project-local artifacts
for the lifecycle `setup -> new-track -> implement -> review`.

## Vision

Help developers use AI coding agents with explicit scope, approved plans,
isolated track worktrees, and evidence-based review rather than ad hoc execution.

## Target Users

Developers using AI coding agents in OpenCode to plan, implement, and review
changes in their own repositories.

## Core Value

- Approve specifications and implementation plans before coding starts.
- Keep project context and track state discoverable under `conductor/`.
- Isolate new tracks in dedicated worktrees and branches by default.
- Route design planning by platform, carry approved context into track worktrees,
  and provide optional project-matched code-style guidance.
- Verify completed work and require explicit approval before track closure.

## Supported Surface

OpenCode is the supported target. The installer also copies the shared skill
to other tools' discovery locations, but those are incidental compatibility
surfaces rather than independently supported implementations.
