"""
    Rogue.usein(downpath; dryrun, from, rev, commit, push)

Update `(Julia)Manifest.toml` file(s) in a downstream project at
`downpath` to use the current version of the upstream project.

* Make sure that the downstream project has no un-committed changes.

* If `manifests` is `nothing` (default), find all `JuliaManifest.toml` and
  `Manifest.toml` file(s) that are tracked by git and have the
  upstream project as a dependency.

* Update the downstream manifest files (update `git-tree-sha1`).

* Resolve dependencies.

    * Note that this makes sure that the current version of the
      upstream project is available in the repository referenced by
      the downstream manifest files (i.e., `git push`ed).

* Commit the changed manifest files with a git commit message
  generated from the upstream commit.  In particular, it contains a
  URL to the commit page of the VCS hosting service used by the
  upstream project.


# Arguments
- `downpath :: AbstractString`: Path to the downstream project.


# Keyword Arguments
- `dryrun :: Bool = false`: If `true`, only print the operations that
  would be performed.

- `from :: AbstractString = "."`: Specify the location of the upstream
  project.

- `rev :: AbstractString = "HEAD"`: Revision of the upstream project.

- `commit :: Union{Bool, Cmd} = true`: If it is a `Bool`, it
  determines if the change should be committed.  If it is a `Cmd`, the
  change is committed and this is passed as options to the `git
  commit` command.

- `push :: Union{Bool, Cmd} = false`: Similar to `commit` but for `git
  push`.
"""
function usein(
    downpath::AbstractString;
    dryrun::Bool = false,
    from::AbstractString = ".",
    rev::AbstractString = "HEAD",
    commit::Union{Bool, Cmd} = true,
    push::Union{Bool, Cmd} = false,
)

    uppkgid = pkgat(from)
    fullrev = strip(read(git_cmd(`rev-parse $rev`, from), String))
    treesha1 = strip(read(git_cmd(`rev-parse "$fullrev^{tree}"`, from), String))
    manifests = find_downstream_manifests(downpath, uppkgid)
    if isempty(manifests)
        @error "No manifest files found in $downpath"
        return
    end
    if !git_is_clean(downpath)
        error("Git repository at `$downpath` has un-committed files.")
    end

    # Preparing commit message now so that it works nicely with
    # `dryrun=true`:
    downroot = strip(read(git_cmd(`rev-parse --show-toplevel`, downpath), String))
    commitfiles = relpath.(manifests, downroot)
    msg = commitmessage(fullrev, uppkgid, from)
    commitargs = `commit --message $msg`
    if commit isa Cmd
        commitargs = `$commitargs $commit`
    end
    pushargs = `push`
    if push isa Cmd
        pushargs = `$pushargs $push`
    end

    if dryrun
        for path in manifests
            @info "(dry-run) $path would be updated."
        end
        # TODO: somehow do this inside `update_manifest`.

        commit == false && return
        # TODO: parse `commitargs` to extract the correct msg
        @info """
        (dry-run) Commit manifest files with message:

        $msg
        """

        push === false && return
        @info """
        (dry-run) Pushing changes to remote...
        Execute: $(`git $pushargs`)
        """
        return
    end

    for path in manifests
        @info "Updating $path"
        update_manifest(path, uppkgid, treesha1)
    end
    if git_is_clean(downpath)
        @info "No updates were required in `$downpath`."
        return
    end
    if commit === false
        @info "`commit=false` is specified. Skipping commit."
        return
    end

    run(git_cmd(`add -- $commitfiles`, downroot))
    run(git_cmd(`$commitargs -- $commitfiles`, downroot))

    @info "Successfully update manifest files:\n$(join(manifests, "\n"))"

    push === false && return
    @info "Pushing changes to remote..."
    run(git_cmd(pushargs, downroot))
    @info "Pushing changes to remote... DONE"
end


"""
    Rogue.updateto(upstream; kwargs...)

A shortcut for `Rogue.usein(".", from=upstream)`.
"""
function updateto(upstream; downpath=".", from=nothing, kwargs...)
    if from !== nothing
        throw(ArgumentError("Use `usein` to specify `from` as a keyword argument."))
    end
    usein(downpath; from=upstream, kwargs...)
end

"""
    Rogue.add(name; project)

Install an unregistered package checked out at `~/.julia/dev/\$name`.
Its unregistered dependencies are installed using information stored
in `Manifest.toml` file checked in its repository (e.g.,
`~/.julia/dev/\$name/test/Manifest.toml`).

# Arguments
- `name::AbstractString`: Name of the package to be installed.

# Keyword Arguments
- `project::Union{Nothing, AbstractString} = nothing`: Project
  in which the package is installed.  `nothing` (default) means
  the current activated project.
"""
function add(
    name::AbstractString;
    project::Union{Nothing, AbstractString} = nothing,
)
    path = joinpath(expanduser("~/.julia/dev"), name)  # TODO: don't
    @assert isdir(path)

    function sortkey(p)
        r = relpath(p, path)
        rank = get(Dict(
            "" => 0,
            "test" => 1,
            "docs" => 2,
        ), dirname(r), typemax(Int))
        return (rank, r)
    end
    manifestfile, = sort(find_manifests(path), by=sortkey)
    spec = pkgspecof(path)
    deps = keys(get(
        TOML.parsefile(projecttomlpath(path)),
        "deps",
        Dict{String,String}(),
    ))

    @info "Installing private package from: $(spec.repo.url)"
    @info "Installing private dependencies from: $manifestfile"
    local private
    temporaryactivating(project) do
        private = add_private_projects_from(deps, manifestfile)
        Pkg.add(spec)
    end

    if isempty(private.deps)
        private_deps = ""
    else
        private_deps = """
        with private dependencies:
            $(join(private.deps, "\n    "))
        """
    end
    @info """
    Added:
        $name
    $private_deps
    """

    return
end
