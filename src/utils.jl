existingfile(path) = isfile(path) ? path : nothing

function pkgat(path::AbstractString) :: PkgId
    prj = TOML.parsefile(something(
        existingfile.(joinpath.(path, ("JuliaProject.toml", "Project.toml")))...
    ))
    return PkgId(UUID(prj["uuid"]), prj["name"])
end

function tempbak(name::AbstractString)
    newname, io = mktemp(dirname(name))
    close(io)
    rename(name, newname)
    return newname
end

git_is_clean(path::AbstractString) =
    isempty(read(setenv(`git --no-pager status --short --untracked-files=no`; dir=path)))
