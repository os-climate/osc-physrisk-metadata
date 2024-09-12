<!--
SPDX-License-Identifier: Apache-2.0
SPDX-FileCopyrightText: Copyright 2024 The Linux Foundation <https://linuxfoundation.org>
-->
<!-- markdownlint-disable -->
<!-- prettier-ignore-start -->
> [!IMPORTANT]
> On June 26 2024, Linux Foundation announced the merger of its financial services umbrella, the Fintech Open Source Foundation ([FINOS](https://finos.org)), with OS-Climate, an open source community dedicated to building data technologies, modeling, and analytic tools that will drive global capital flows into climate change mitigation and resilience; OS-Climate projects are in the process of transitioning to the [FINOS governance framework](https://community.finos.org/docs/governance); read more on [finos.org/press/finos-join-forces-os-open-source-climate-sustainability-esg](https://finos.org/press/finos-join-forces-os-open-source-climate-sustainability-esg)
<!-- prettier-ignore-end -->
<!-- markdownlint-enable -->

# Python Template Repository

This repository hosts the setup scripts and metadata for new OS-Climate Python projects

## Quick Start Guide

To create a new Python project, visit:

[https://github.com/organizations/os-climate/repositories/new](https://github.com/organizations/os-climate/repositories/new)

Choose repository template:

 os-climate/python-template-repository

Owner:

 os-climate

Repository name:

 [osc-your-new-repository]

Grant the following GitHub App access to the new repository:

 pre-commit ci

Afterwards, you will need to ask an OS-Climate DevOps engineer (or GitHub organisation
administrator) to add the repository to a credential permitting Github Actions workflows
to modify action files:

[https://github.com/organizations/os-climate/settings/secrets/actions/ACTIONS_WORKFLOW](https://github.com/organizations/os-climate/settings/secrets/actions/ACTIONS_WORKFLOW)

## Bootstrap Scripts, Templating and Skeleton Files

Raise GitHub issues here if/when you need a new OS-Climate GitHub repository creating

## Description

Repository and CLI tool naming should reflect and match installable package names.
Repository names are prefixed with "osc-" to help avoid wider name-space conflicts.
Repository names use dashes, while module names and some folders may use underscores.

Package names should be generic

**Note:** _this ensures consistency if/when packages are made available through PyPI_

- We use the following tool to bootstrap new projects: [Pyscaffold](https://pyscaffold.org/en/stable/)
- Initial linting and GitHub workflows are imported from: [devops-toolkit](https://github.com/os-climate/devops-toolkit/)

The setup script does the following:

- Invokes pyscaffold to create a folder hierarchy (based on modern PEP standards)
- Creates default linting, TOX and project metadata files
- Performs some post-installation customisation to Pyscaffold (specific to OS-Climate)
- Imports an enhance linting setup from a central OS-Climate reposiutory
- Imports a bunch of shared GitHub actions workflow for common Python project needs

## Modern PEP Standards Compliance

We aim to ensure our projects start with the latest PEP standards compliance in mind

To this end, we do NOT use the following:

- Setuptools (for builds)
- requirements.txt (for describing module dependencies)

Instead we are using the following:

- PDM project (build/dependency management tool)
- pyproject.toml (project metadata description)

### PDM Project

For further details on using PDM for managing dependencies and builds, see:

- [PDM Project](https://pdm-project.org/en/latest/)
- [PDM Project on GitHub](https://github.com/pdm-project/pdm)
- [PDM/Setup Github Action](https://github.com/pdm-project/setup-pdm)

### Information on pyproject.toml

- [Guide to writing pyproject.toml](https://packaging.python.org/en/latest/guides/writing-pyproject-toml/)
- [File Specification](https://packaging.python.org/en/latest/specifications/pyproject-toml/)
- [Syntax/Cheat Sheet](https://betterprogramming.pub/a-pyproject-toml-developers-cheat-sheet-5782801fb3ed)

##  New Repositories

We can/should create new Python repositories using this template. Afterwards, the
upstream DevOps tooling and GitHub workflows can be imported using the appropriate
workflow. This can be run from the GitHub portal user interface, or from a shell
using the provided thin wrapper script.

**Note:** _Before running the workflow, a member of the OS-Climate organisation
with GitHub administrator privileges must extend the ACTIONS_WORKFLOW credential
to the relevant repository/repositories. The automation needs the ability to
raise a PR, which the standard token/credential does not allow/permit._

Go here to update the repository settings to apply the relevant credential:

[ACTIONS_WORKFLOW](https://github.com/organizations/os-climate/settings/secrets/actions/ACTIONS_WORKFLOW)
