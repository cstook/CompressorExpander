using DifferentialEquations
using Plots;gr()
using Parameters

struct CompressorExpander{T}
    m :: T
    γc :: T
    γe :: T
    c1 :: T
    c2 :: T
    function CompresorExpnader(r,d1,d2,m,γc,γe) where {T}
        c1 = π*r^2
        c2 = d2-d1
        new{T}(m,γc,γe,c1,c2)
    end
end

γmix(;gascp,gascv,liquidc,massratio) = (gascp + massratio*liquidc) / (gascv + massratio*liquidc)
let
    const air = (cp=1.008e3, cv=0.721e3, d=1.29)
    const water = (c=4.1813e3, d=997.0)
end
#
# u[1] = position
# u[2] = velocity
# u[3] = pressure, compressor
# u[4] = pressure, expander
#
#
function fclosed!(du,u,p,t)
    @unpack c1,c2,γc,γe,m = p
    fmagnetic = 0.0
    du[1] = u[2]
    du[2] = (c1*(u[3]-u[4])+fmagnetic)/m
    du[3] = -γc*u[3]*u[2]/(c2+u[1])
    du[4] = γe*u[4]*u[2]/(c2-u[1])
end
function fcompressorfixedpressure!(du,u,p,t)
    @unpack c1,c2,γc,γe,m = p
    fmagnetic = 0.0
    du[1] = u[2]
    du[2] = (c1*(u[3]-u[4])+fmagnetic)/m
    du[3] = 0.0
    du[4] = γe*u[4]*u[2]/(c2-u[1])
end
function fexpanderfixedpressure!(du,u,p,t)
    @unpack c1,c2,γc,γe,m = p
    fmagnetic = 0.0
    du[1] = u[2]
    du[2] = (c1*(u[3]-u[4])+fmagnetic)/m
    du[3] = -γc*u[3]*u[2]/(c2+u[1])
    du[4] = 0.0
end
