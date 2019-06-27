# Rogue.jl: Utilities for dealing with unregistered packages

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://tkf.github.io/Rogue.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://tkf.github.io/Rogue.jl/dev)
[![Build Status](https://travis-ci.com/tkf/Rogue.jl.svg?branch=master)](https://travis-ci.com/tkf/Rogue.jl)
[![Codecov](https://codecov.io/gh/tkf/Rogue.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/tkf/Rogue.jl)
[![Coveralls](https://coveralls.io/repos/github/tkf/Rogue.jl/badge.svg?branch=master)](https://coveralls.io/github/tkf/Rogue.jl?branch=master)

Summary

* `Rogue.usein(downpath; ...)`

  Update `(Julia)Manifest.toml` file(s) in a downstream project at
  `downpath` to use the current version of the upstream project.

* `Rogue.add(name; project)`

  Install an unregistered package checked out at `~/.julia/dev/$name`
  to the current environment or to `project` if given.

See more details in the [documentation](https://tkf.github.io/Rogue.jl/dev).
