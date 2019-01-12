using Plots; plotly()
using DataFrames
using CSV
using StatPlots

df = CSV.read("sweep2.csv",header=1)
df.coil_area = df.coil_outer_diameter .* df.coil_length

sort!(df, (:coil_area,:force))



coil_vs_force = by(df, [:coil_area,:cap_length,:coil_outer_diameter,:coil_length], :force=>maximum)
a = Array{Int,1}()
let max_force = 0.0, i = 1
    for row in eachrow(coil_vs_force)
        if row.force_maximum<=max_force
            push!(a,i)
        else
            max_force = row.force_maximum
        end
        i=i+1
    end
end
deleterows!(coil_vs_force,a)

@df df scatter(:coil_area,:force,xlabel="coil_area",ylabel="force")
@df coil_vs_force plot!(:coil_area,:force_maximum)

@df coil_vs_force scatter(:cap_length,:coil_length ./ :cap_length, xlabel="cap_length",ylabel="coil_length/cap_length")
@df coil_vs_force scatter(:coil_outer_diameter,:coil_length ./ :cap_length, xlabel="coil_outer_diameter",ylabel="coil_length/cap_length")
@df coil_vs_force scatter(:coil_area,:coil_length ./ :cap_length, xlabel="coil_area",ylabel="coil_length/cap_length")
