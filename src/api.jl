"""
    Rogue.usein(downpath; from)

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
- `from :: AbstractString = "."`: Specify the location of the upstream
  project.
"""
function usein(
    downpath::AbstractString;
    from::AbstractString = ".",
)

    uppkgid = pkgat(from)
    fullrev = strip(read(git_cmd(`rev-parse HEAD`, from), String))
    treesha1 = strip(read(git_cmd(`rev-parse $fullrev^{tree}`, from), String))
    manifests = find_downstream_manifests(downpath, uppkgid)
    if isempty(manifests)
        @error "No manifest files found in $downpath"
        return
    end
    if !git_is_clean(downpath)
        error("Git repository at `$downpath` has un-committed files.")
    end
    for path in manifests
        @info "Updating $path"
        update_manifest(path, uppkgid, treesha1)
    end
    if git_is_clean(downpath)
        @info "No updates were required in `$downpath`."
        return
    end

    downroot = strip(read(git_cmd(`rev-parse --show-toplevel`, downpath), String))
    commitfiles = relpath.(manifests, downroot)
    msg = commitmessage(fullrev, uppkgid, from)
    commitargs = `commit --message $msg`
    run(git_cmd(`add -- $commitfiles`, downroot))
    run(git_cmd(`$commitargs -- $commitfiles`, downroot))

    @info "Successfully update manifest files:\n$(join(manifests, "\n"))"
end
