module Rogue

@doc read(joinpath(dirname(@__DIR__), "README.md"), String) Rogue

using Base.Filesystem: rename
using Base: PkgId
using Pkg: Pkg, TOML
using PyCall: pyimport
using Setfield
using Transducers
using UUIDs

include("utils.jl")
include("manifests.jl")
include("downstreams.jl")
include("api.jl")

end # module
