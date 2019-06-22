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

ensuredir(path) = isdir(path) ? path : dirname(path)

git_cmd(args::Cmd=``, dir::AbstractString=".") =
    setenv(`git --no-pager $args`; dir=ensuredir(dir))

git_is_clean(path::AbstractString) =
    isempty(read(git_cmd(`status --short --untracked-files=no`, path)))

vcslinktocommit(args...; kwargs...) =
    pyimport("vcslinks").commit(args...; kwargs...)

function commitmessage(fullrev, uppkgid::PkgId, from)
    link = vcslinktocommit(fullrev, path=from)
    subject = strip(read(git_cmd(`show --format=format:%s --no-patch`, from), String))
    return """
    $(uppkgid.name): $subject

    $link
    """
end
