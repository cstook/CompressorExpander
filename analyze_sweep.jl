using Plots; plotly()
using DataFrames
using CSV
using StatPlots

df = CSV.read("sweep2.csv",header=1)
df.coil_volume = π.*df.coil_length.*(df.coil_outer_diameter.-df.tube_outer_diameter)


sort!(df, (:coil_volume,:force))



coil_vs_force = by(df, [:coil_volume,:cap_length,:coil_outer_diameter,:coil_length], :force=>maximum)
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

@df df scatter(:coil_volume,:force,xlabel="coil_volume",ylabel="force")
@df coil_vs_force plot!(:coil_volume,:force_maximum)

@df coil_vs_force scatter(:cap_length,:coil_length ./ :cap_length, xlabel="cap_length",ylabel="coil_length/cap_length")
@df coil_vs_force scatter(:coil_outer_diameter,:coil_length ./ :cap_length, xlabel="coil_outer_diameter",ylabel="coil_length/cap_length")
@df coil_vs_force scatter(:coil_volume,:coil_length ./ :cap_length, xlabel="coil_volume",ylabel="coil_length/cap_length")
