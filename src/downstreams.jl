function find_manifests(repo::AbstractString)
    repo = ensuredir(repo)
    paths = filter(readlines(setenv(`git --no-pager ls-files`; dir=repo))) do path
        basename(path) ∈ ("JuliaManifest.toml", "Manifest.toml")
    end
    return joinpath.(repo, paths)
end

_manifests_with(manifestpaths::Vector{String}, dep::PkgId) =
    filter(path -> haspkg(path, dep), manifestpaths)

find_downstream_manifests(repo::AbstractString, upstream::PkgId) =
    _manifests_with(find_manifests(repo), upstream)
