var documenterSearchIndex = {"docs":
[{"location":"#Rogue.jl-1","page":"Home","title":"Rogue.jl","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Pages = [\"index.md\"]","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Modules = [Rogue]\nFilter = Rogue._is_api","category":"page"},{"location":"#Rogue.add-Tuple{AbstractString}","page":"Home","title":"Rogue.add","text":"Rogue.add(name; project)\n\nInstall an unregistered package checked out at ~/.julia/dev/$name. Its unregistered dependencies are installed using information stored in Manifest.toml file checked in its repository (e.g., ~/.julia/dev/$name/test/Manifest.toml).\n\nArguments\n\nname::AbstractString: Name of the package to be installed.\n\nKeyword Arguments\n\nproject::Union{Nothing, AbstractString} = nothing: Project in which the package is installed.  nothing (default) means the current activated project.\nprefer_https::Bool = false: Prefer HTTPS repository URL rather than the one used in Git repository.\n\n\n\n\n\n","category":"method"},{"location":"#Rogue.updateto-Tuple{Any}","page":"Home","title":"Rogue.updateto","text":"Rogue.updateto(upstream; kwargs...)\n\nA shortcut for Rogue.usein(\".\", from=upstream).\n\n\n\n\n\n","category":"method"},{"location":"#Rogue.usein-Tuple{AbstractString}","page":"Home","title":"Rogue.usein","text":"Rogue.usein(downpath; dryrun, from, rev, commit, push)\n\nUpdate (Julia)Manifest.toml file(s) in a downstream project at downpath to use the current version of the upstream project.\n\nMake sure that the downstream project has no un-committed changes.\nIf manifests is nothing (default), find all JuliaManifest.toml and Manifest.toml file(s) that are tracked by git and have the upstream project as a dependency.\nUpdate the downstream manifest files (update git-tree-sha1).\nResolve dependencies.\nNote that this makes sure that the current version of the upstream project is available in the repository referenced by the downstream manifest files (i.e., git pushed).\nCommit the changed manifest files with a git commit message generated from the upstream commit.  In particular, it contains a URL to the commit page of the VCS hosting service used by the upstream project.\n\nArguments\n\ndownpath :: AbstractString: Path to the downstream project.\n\nKeyword Arguments\n\ndryrun :: Bool = false: If true, only print the operations that would be performed.\nfrom :: AbstractString = \".\": Specify the location of the upstream project.\nrev :: AbstractString = \"HEAD\": Revision of the upstream project.\ncommit :: Union{Bool, Cmd} = true: If it is a Bool, it determines if the change should be committed.  If it is a Cmd, the change is committed and this is passed as options to the git commit command.\npush :: Union{Bool, Cmd} = false: Similar to commit but for git push.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Internals-1","page":"Internals","title":"Internals","text":"","category":"section"},{"location":"internals/#","page":"Internals","title":"Internals","text":"Pages = [\"internals.md\"]","category":"page"},{"location":"internals/#","page":"Internals","title":"Internals","text":"Modules = [Rogue]\nFilter = !Rogue._is_api","category":"page"},{"location":"internals/#Rogue.Rogue","page":"Internals","title":"Rogue.Rogue","text":"Rogue.jl: Utilities for dealing with unregistered packages\n\n(Image: Stable) (Image: Dev) (Image: Build Status) (Image: Codecov) (Image: Coveralls)\n\nSummary\n\nRogue.usein(downpath; ...)\nUpdate (Julia)Manifest.toml file(s) in a downstream project at downpath to use the current version of the upstream project.\nRogue.add(name; project)\nInstall an unregistered package checked out at ~/.julia/dev/$name to the current environment or to project if given.\n\nSee more details in the documentation.\n\n\n\n\n\n","category":"module"},{"location":"internals/#Rogue._add_private_projects-Tuple{Any,Dict}","page":"Internals","title":"Rogue._add_private_projects","text":"_add_private_projects(private_deps, private_projects)\n\nCall Pkg.add for private projects.  Most upstream first.\n\n\n\n\n\n","category":"method"}]
}
