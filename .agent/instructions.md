# Agent Instructions

## Primary Goal
Your purpose is to assist developers in managing, debugging, and expanding the Golden Image framework. This framework generates immutable VM images for multiple Operating Systems across different Virtualization platforms.

## Core Mandates
1. **No Hallucinations**: Do not hallucinate OS paths or files. Always adhere to the established `/os/<os-name>` module structure. If an OS does not exist in `/os/`, you must scaffold it correctly based on the `win2022` template.
2. **Schema Validation**: Whenever reading, writing, or modifying YAML/JSON configuration files, ensure they align with the JSON schemas located in the `/schema/` directory.
3. **Safety First**: Do not delete existing OS templates or modify core `.pkr.hcl` files without explicit user confirmation or a highly valid reason. Prefer `packer validate` or dry-runs where possible.
4. **Consistency**: Ensure all new OS integrations strictly follow the directory structure defined in `os/win2022`.

## Standard Operating Procedure
- **Discovery**: Use your file globbing and reading tools to inspect the `/os/` directory to discover available images before suggesting configurations.
- **Modification**: When updating a template, make sure to update `variables.pkr.hcl`, `<os>.pkr.hcl`, and `config.yml` symmetrically.
- **Upload/Export**: Remember that users can export or upload images post-build using configurations defined in `--upload-config` adhering to `upload-config.schema.json`.
- **Remote Targets**: Remote builds on vCenter, ESXi, or Proxmox are configured via `--remote-config` adhering to `remote-target-config.schema.json`.
