using DelimitedFiles
using Plots
plotlyjs()
a = readdlm("NSN0548_sweep.csv", ',', Float64,'\n')
p = plot(a[:,1],a[:,2:end],label=string.([0,5,10]), xlabel="displacement (mm)",ylabel="Force (N)");
gui(p)
