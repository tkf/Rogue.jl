"""
    Rogue.usein(downpath; dryrun, from, rev, commit)

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
  would be done.

- `from :: AbstractString = "."`: Specify the location of the upstream
  project.

- `rev :: AbstractString = "HEAD"`: Revision of the upstream project.

- `commit :: Union{Bool, Cmd} = true`: If it is a `Bool`, it
  determines if the change should be committed.  If it is a `Cmd`, the
  change is committed and this is passed as options to the `git
  commit` command.
"""
function usein(
    downpath::AbstractString;
    dryrun::Bool = false,
    from::AbstractString = ".",
    rev::AbstractString = "HEAD",
    commit::Union{Bool, Cmd} = true,
)

    uppkgid = pkgat(from)
    fullrev = strip(read(git_cmd(`rev-parse $rev`, from), String))
    treesha1 = strip(read(git_cmd(`rev-parse $fullrev^{tree}`, from), String))
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
end
