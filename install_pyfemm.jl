# https://discourse.julialang.org/t/pycall-pre-installing-a-python-package-required-by-a-julia-package/3316/11

using PyCall

const PACKAGES = ["pyfemm"]

@pyimport pip
args = String[]
if haskey(ENV, "http_proxy")
    push!(args, "--proxy")
    push!(args, ENV["http_proxy"])
end

# Use eventual proxy info
proxy_arg=String[]
if haskey(ENV, "http_proxy")
    push!(proxy_arg, "--proxy")
    push!(proxy_arg, ENV["http_proxy"])
end

println("Installing required python packages using pip")
run(`$(PyCall.python) $(proxy_arg) -m pip install --user --upgrade pip setuptools`)
run(`$(PyCall.python) $(proxy_arg) -m pip install --user $(PACKAGES)`)
