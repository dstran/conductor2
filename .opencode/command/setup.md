---
description: Create or refresh the Conductor handshake and project context files, then pause for user review before setup is treated as complete
agent: build
---

`/setup` is the first step in the Conductor lifecycle: `setup -> new-track -> implement -> review`.

Read and maintain `conductor/index.md` as the handshake artifact for this project.

Create or refresh these project context artifacts, then pause for user review before treating setup as complete:

- `conductor/product.md`
- `conductor/product-guidelines.md`
- `conductor/tech-stack.md`
- `conductor/workflow.md`
- `conductor/code_styleguides/`
- `conductor/tracks.md`
- `conductor/index.md`

If any of those paths do not exist yet, create them as part of setup.
Verify that `conductor/index.md` links the project context, workflow, and track infrastructure that later commands depend on.
