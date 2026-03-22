# HashiCorp Packer CLI

## Description
Packer is the core engine for this project. As an AI agent, you will use Packer tools to validate code before executing a run.

## Commands to Use
- `packer fmt .`: Format HCL configuration files properly.
- `packer validate .`: ALWAYS run this command after modifying a `.pkr.hcl` file or `variables.pkr.hcl` file to ensure syntax validity.
- `packer build -only=*.<builder>.* .`: Used internally by the wrapper scripts, but you can use it manually for debugging.

## Important Note
Avoid starting a full `packer build` autonomously as an AI agent unless the user specifically instructs you to. Builds can take 15 to 45 minutes and use massive I/O. Rely on `packer validate`.
