# Security Policy

This repository is a documentation and tooling archive (PDF manuals,
datasheets, and PowerShell OCR scripts). It does not run as a service and
does not process untrusted network input, but the scripts in [`ocr/`](ocr/)
do execute on your machine, so we still take security reports seriously.

## Supported Versions

Only the latest state of the `main` branch is supported.

## Reporting a Vulnerability

If you discover a security issue (for example, unsafe handling of files in
the OCR scripts, or a supply-chain concern in `setup-ocr-dependencies.ps1`),
please report it privately rather than opening a public issue:

- Use GitHub's [private vulnerability reporting](../../security/advisories/new)
  for this repository, or
- Contact the maintainer directly through their GitHub profile
  ([@xplorer2716](https://github.com/xplorer2716)).

Please include:

- A description of the issue and its potential impact
- Steps to reproduce, if applicable
- The affected file(s) or script(s)

We will acknowledge reports as soon as possible and work with you on a fix
and disclosure timeline appropriate to the issue's severity.
