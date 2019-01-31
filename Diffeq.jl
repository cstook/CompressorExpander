using DifferentialEquations
f(u,p,t) = 1.01*u
u0=1/2
tspan = (0.0,1.0)
prob = ODEProblem(f,u0,tspan)
sol = solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
using Plots;gr()
plot(sol,linewidth=5,title="Solution to the linear ODE with a thick line",
     xaxis="Time (t)",yaxis="u(t) (in μm)",label="My Thick Line!") # legend=false
plot!(sol.t, t->0.5*exp(1.01t),lw=3,ls=:dash,label="True Solution!")

#
# u[1] = position
# u[2] = velocity
# u[3] = pressure
#
# p[1] = pistonarea / pistonmass
# p[2] = γ


x = let
    const air = (cp=1.008e3, cv=0.721e3, d=1.29)
    const water = (c=4.1813e3, d=997.0)
end



using DifferentialEquations
using Plots;gr()
p1(;pistonarea, pistonmass) = pistonarea / pistonmass
γmix(;gascp,gascv,liquidc,massratio) = (gascp + massratio*liquidc) / (gascv + massratio*liquidc)
pistonarea(;pistonradius) = π*pistonradius^2

function f!(du,u,p,t)
    du[1] = u[2]
    du[2] = p[1]*u[3]
    du[3] = -u[3]*p[2]*u[2]/u[1]
end


plotly()
gr()
inspectdr()
let
    p = (p1(pistonarea=π*1.0^2, pistonmass = 1.0), γmix(gascp=1.008e3, gascv=0.721e3, liquidc=4.1813e3, massratio=.1000))
    initialpressure = 100000.0 # n/m^2
    initialvelocity = 0.0 # m/s
    initialposition = 1.0 # m
    initialtemperature = 500.0 #K
    constant1 = initialtemperature/(initialpressure*p[1]*initialposition)
    u0 = [initialposition,initialvelocity,initialpressure]
    tspan = (0.0,0.05)
    prob = ODEProblem(f!,u0,tspan,p)
    sol = solve(prob)
    positionplot = plot(sol,vars=1,ylabel="position",leg=false)
    velocityplot = plot(sol,vars=2,ylabel="velocity",leg=false)
    pressureplot = plot(sol,vars=3,ylabel="pressure",leg=false)
    temperatureplot = plot(sol.t,constant1.*p[1].*sol[1,:].*sol[3,:],ylabel="temperature",leg=false)
    allplots = plot(positionplot, velocityplot, pressureplot, temperatureplot, layout=(4,1))
    gui(allplots)
end
