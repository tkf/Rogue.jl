module Rogue

using Base.Filesystem: rename
using Base: PkgId
using Pkg: Pkg, TOML
using Transducers
using UUIDs

include("utils.jl")
include("manifests.jl")
include("downstreams.jl")
include("api.jl")

end # module
