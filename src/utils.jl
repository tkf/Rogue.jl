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
