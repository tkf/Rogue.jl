project_chunks() = ScanEmit((name="", lines=String[]), identity) do chunk, current
    m = match(r"^\[\[(.*)\]\]", current)
    if m !== nothing
        return chunk, (name=m.captures[1], lines=String[current])
    else
        push!(chunk.lines, current)
        return nothing, chunk
    end
end |> NotA(Nothing)

function samepkg(chunk, pkg::PkgId)
    if chunk.name == pkg.name
        for line in chunk.lines
            m = match(r"^uuid *= *\"(.*?)\"", line)
            m === nothing && continue
            return UUID(m.captures[1]) === pkg.uuid
        end
    end
    return false
end

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

function update_manifest(manifest::AbstractString, pkg, treesha1)
    backup = tempbak(manifest)
    ok = false
    try
        open(manifest, "w") do io
            foreach(updating_manifest(pkg, treesha1), aslines(backup)) do line
                println(io, line)
            end
        end
        try
            Pkg.activate(dirname(manifest))
            Pkg.resolve()
        finally
            Pkg.activate()
        end
        ok = true
    finally
        if ok
            rm(backup)
        else
            mv(backup, manifest; force=true)
        end
    end
end
