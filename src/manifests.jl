project_chunks() = ScanEmit((name="", lines=String[]), identity) do chunk, current
    m = match(r"^\[\[(.*)\]\]", current)
    if m !== nothing
        return chunk, (name=m.captures[1], lines=String[current])
    else
        push!(chunk.lines, current)
        return nothing, chunk
    end
end |> NotA(Nothing)

function aspkg(chunk)
    for line in chunk.lines
        m = match(r"^uuid *= *\"(.*?)\"", line)
        m === nothing && continue
        return PkgId(UUID(m.captures[1]), chunk.name)
    end
    return PkgId(nothing, chunk.name)
end

samepkg(chunk, pkg::PkgId) =
    chunk.name == pkg.name && aspkg(chunk) === pkg

updating_git_tree_sha1(pkg, treesha1) = Map() do chunk
    if samepkg(chunk, pkg)
        i = findfirst(chunk.lines) do line
            match(r"^git-tree-sha1 *=", line) !== nothing
        end
        @assert i !== nothing
        chunk.lines[i] = "git-tree-sha1 = $(repr(String(treesha1)))"
        return chunk
    end
    return chunk
end

updating_manifest(pkg, treesha1) =
    project_chunks() |>
    updating_git_tree_sha1(pkg, treesha1) |>
    Map(chunk -> chunk.lines) |>
    Cat()

haspkg(manifest, pkg::PkgId) =
    foldl(project_chunks(), aslines(manifest), init=false) do s, chunk

        # This is required for using `onlast` in `ScanEmit`.  Should
        # it be considered a bug in Transducers.jl?
        s && return true

        samepkg(chunk, pkg) && return reduced(true)
        return false
    end

aslines(path::AbstractString) = readlines(path)
aslines(lines::AbstractArray{<:AbstractString}) = lines

function withbackup(f, orig::AbstractString)
    backup = tempbak(orig)
    ok = false
    try
        f(backup)
        ok = true
    finally
        if ok
            rm(backup)
        else
            mv(backup, orig; force=true)
        end
    end
end

function temporaryactivating(f, project)
    try
        Pkg.activate(project)
        f()
    finally
        Pkg.activate()
    end
end

function update_manifest(manifest::AbstractString, pkg, treesha1)
    withbackup(manifest) do backup
        open(manifest, "w") do io
            foreach(updating_manifest(pkg, treesha1), aslines(backup)) do line
                println(io, line)
            end
        end
        temporaryactivating(dirname(manifest)) do
            Pkg.resolve()
        end
    end
end

private_projects() = Filter() do chunk
    for line in chunk.lines
        match(r"^repo-url *=", line) !== nothing && return true
    end
    return false
end

function parse_deps(lines::Vector{String})
    sections = (
        pre_deps = String[],
        deps = String[],
        post_deps = String[],
    )

    dest = sections.pre_deps
    for line in lines
        if dest === sections.deps && isempty(line)
            dest = sections.post_deps
        end
        push!(dest, line)
        if line == "[deps]"
            dest = sections.deps
        end
    end

    return sections
end

function manifest_entry_to_pkgspec(name, entry)
    spec = Pkg.PackageSpec(
        name = name,
        url = get(entry, "repo-url", nothing),
        rev = get(entry, "repo-rev", nothing),
    )
    @set! spec.repo.tree_sha = Base.SHA1(entry["git-tree-sha1"])
    return spec
end

"""
    _add_private_projects(private_projects)

Call `Pkg.add` for private projects.  Most upstream first.
"""
function _add_private_projects(private_projects::Dict)
    added = Set{String}()
    for name in keys(private_projects)
        _add_private_project!(added, private_projects, name)
    end
end

function _add_private_project!(added::Set, private_projects::Dict, name::String)
    name in added && return
    entry = private_projects[name]
    spec = manifest_entry_to_pkgspec(name, entry)
    @info "Adding $spec"
    for dep in entry["deps"]
        haskey(private_projects, dep) || continue
        _add_private_project!(added, private_projects, dep)
    end
    Pkg.add(spec)
    @info "Added $name"
    return
end

function add_private_projects_from(manifestfile::AbstractString)
    manifest = TOML.parsefile(manifestfile)

    # Extract all private projects:
    private_projects = Dict(eduction(
        MapCat() do (name, entries)
            tuple.(name, entries)
        end |> Filter() do (name, entry)
            haskey(entry, "repo-url")
        end,
        manifest,
    ))
    # TODO: make sure that there is no duplicated names (but is it possible?)
    _add_private_projects(private_projects)

    return private_projects
end
