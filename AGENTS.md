# Artificial Intelligence Interaction Protocol

Welcome, AI Agent. This repository utilizes the **Open Agent Standard** to define how autonomous bots should interact, code, and troubleshoot the Golden Image Builder framework.

## Architecture

To prevent hallucinated file structures and maintain safety, your execution boundaries are governed by the `.agents/` directory:

- `/.agents/contexts/`: Contains high-level blueprints and architectural overviews. You must read these to understand the repository's intent before executing commands.
- `/.agents/rules/`: Strict operational laws. For example, `windows_setup.md` dictates precisely how QEMU and Windows PE must be configured to prevent automated installation loops. You **MUST** adhere to these rules when generating HCL or XML logic.
- `/.agents/skills/`: Executable YAML definitions that teach you how to perform complex operations (like scaffolding a new OS template) identically to human developers.
- `/.agents/workflows/`: Standard Operating Procedures (SOPs) detailing how to respond to specific events, such as a Packer build timing out.

## Instructions
1. Before modifying a template, check if a relevant Rule exists.
2. If asked to perform an action that conflicts with a Rule, decline and explain the constraint.
3. Validate all YAML creations against `/schema/`.
4. Always execute `packer validate .` before concluding your changes.