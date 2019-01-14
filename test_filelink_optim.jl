import FEMMfilelink
using Optim

const NSN0548_hole_diameter = 2.54
const NSN0548_outer_diameter = 6.45
const NSN0548_length = 6.35
const tube_outer_diameter = (3/8)*25.4

function measure_force(magnet_hole_diameter, magnet_outer_diameter, magnet_length,
                       cap_length,
                       tube_outer_diameter,
                       coil_outer_diameter, coil_length,
                       magnetics_outer_diameter, magnetics_length)
    FEMMfilelink.filelink("flput(measure_force($magnet_hole_diameter,$magnet_outer_diameter,$magnet_length,$cap_length,$tube_outer_diameter,$coil_outer_diameter,$coil_length,$magnetics_outer_diameter,$magnetics_length))")
end


#=

x[1] = cap_length
x[2] = coil_outer_diameter
x[3] = coil_length
x[4] = magnetics_outer_diameter
x[5] = magnetics_length
=#
vcylinder(r,h) = π*h*r^2

# material volume is bad, force is good
cost(x) = 1.0*(π*x[1]*NSN0548_outer_diameter^2)+  # cap cost
          1.0*(π*x[3]*(x[2]^2-tube_outer_diameter^2))+ # coil cost
          1.0*(π*x[5]*(x[4]^2-x[2]^2))+ # magnetics cost
          -10.0*measure_force(NSN0548_hole_diameter,NSN0548_outer_diameter,NSN0548_length,
            x[1],tube_outer_diameter,x[2],x[3],x[4],x[5])

x0 = [0.5*NSN0548_outer_diameter, tube_outer_diameter+20,
      0.5*NSN0548_hole_diameter+5, tube_outer_diameter + 30, 30*NSN0548_length]


# need constraints!


femmprocess = FEMMfilelink.startfemm()
FEMMfilelink.testfilelink() || throw(ErrorException("filelink broken"))
FEMMfilelink.writeifile("dofile(\"one_magnet.lua\")")
result = optimize(cost,x0)
kill(femmprocess)
