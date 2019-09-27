existingfile(path) = isfile(path) ? path : nothing

_tomlpath(dir, candidates) =
    something(existingfile.(joinpath.(dir, candidates))...,
              joinpath(dir, candidates[2]))

projecttomlpath(dir) = _tomlpath(dir, ("JuliaProject.toml", "Project.toml"))
manifesttomlpath(dir) = _tomlpath(dir, ("JuliaManifest.toml", "Manifest.toml"))

function pkgat(path::AbstractString) :: PkgId
    prj = TOML.parsefile(projecttomlpath(path))
    return PkgId(UUID(prj["uuid"]), prj["name"])
end

function pkgspecof(path::AbstractString; prefer_https=false)
    prj = TOML.parsefile(projecttomlpath(path))
    if prefer_https
        url = vcslinktoroot(path=path)
    else
        url = strip(read(git_cmd(`config remote.origin.url`, path), String))
    end
    tree_sha = strip(read(git_cmd(`rev-parse "HEAD^{tree}"`, path), String))
    spec = Pkg.PackageSpec(
        name = prj["name"],
        uuid = prj["uuid"],
        url = url,
    )
    @set! tree_hash(spec) = Base.SHA1(tree_sha)
    return spec
end

tree_hash(spec) =
    isdefined(spec, :tree_hash) ? spec.tree_hash : spec.repo.tree_sha

Setfield.set(spec, ::typeof(@lens tree_hash(_)), value) =
    if isdefined(spec, :tree_hash)
        # Julia 1.2
        @set spec.tree_hash = value
    else
        # Julia 1.1
        @set spec.repo.tree_sha = value
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

vcslinktoroot(args...; kwargs...) =
    pyimport("vcslinks").root(args...; kwargs...)

vcslinktocommit(args...; kwargs...) =
    pyimport("vcslinks").commit(args...; kwargs...)

function commitmessage(fullrev, uppkgid::PkgId, from, title, comment)
    link = vcslinktocommit(fullrev, path=from)
    subject = strip(
        read(
            git_cmd(`show --format=format:%s --no-patch $fullrev`, from),
            String,
        ),
    )
    title = rstrip(something(title, "Update: $(uppkgid.name)"))
    comment = rstrip(something(comment, ""))
    footer = """
    Using commit:
    $subject
    $link
    """
    return join([title, comment, footer], "\n\n")
end

function _is_api(f)
    for m in methods(f)
        if m.file === Symbol(joinpath(@__DIR__, "api.jl"))
            return true
        end
    end
    return false
end
