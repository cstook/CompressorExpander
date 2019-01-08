using DelimitedFiles
using Plots
n = readdlm("n.csv", ',', Float64,'\n')
p = readdlm("p.csv", ',', Float64,'\n')[2:end,:]
a = vcat(n,p)
p = sortperm(a[:,1])
b = a[p,:]
plot(b[:,1],b[:,2:end],label=string.([0,1,2,3,4,5,6,7,8,9,10]), xlabel="displacement (mm)",ylabel="Force (N)")
