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
    FEMMfilelink.filelink("flput(measure_force($magnet_hole_diameter,$magnet_outer_diameter,$magnet_length,$cap_length,$tube_outer_diameter,$coil_outer_diameter,$coil_length,$magnetics_outer_diameter,$magnetics_length))",timeout_s=2)
end

function one_magnet(magnet_hole_diameter, magnet_outer_diameter, magnet_length,
                       cap_length,
                       tube_outer_diameter,
                       coil_outer_diameter, coil_length,
                       magnetics_outer_diameter, magnetics_length)
    FEMMfilelink.writeifile("one_magnet($magnet_hole_diameter,$magnet_outer_diameter,$magnet_length,$cap_length,$tube_outer_diameter,$coil_outer_diameter,$coil_length,$magnetics_outer_diameter,$magnetics_length)")
end

coillength(coil_gap, cap_lenght) = NSN0548_length+cap_lenght-coil_gap
magneticsouterdiameter(coil_outer_diameter,magnetics_wallthichness) = coil_outer_diameter+magnetics_wallthichness
#=
x[1] = cap_length
x[2] = coil_outer_diameter
x[3] = coil_gap
x[4] = magnetics_wallthichness
x[5] = magnetics_length
=#

vcylinder(r,h) = π*h*r^2


measure_force(x) = measure_force(NSN0548_hole_diameter,NSN0548_outer_diameter,NSN0548_length,
 x[1],tube_outer_diameter,x[2],coillength(x[3],x[1]),magneticsouterdiameter(x[2],x[4]),x[5])
one_magnet(x) = one_magnet(NSN0548_hole_diameter,NSN0548_outer_diameter,NSN0548_length,
  x[1],tube_outer_diameter,x[2],coillength(x[3],x[1]),magneticsouterdiameter(x[2],x[4]),x[5])

# material volume is bad, force is good
cost(x) = 0.1*(x[1]*NSN0548_outer_diameter^2)+  # cap cost
          1.0*(coillength(x[3],x[1])*(x[2]^2-tube_outer_diameter^2))+ # coil cost
          0.1*(x[5]*(magneticsouterdiameter(x[2],x[4])^2-x[2]^2))+ # magnetics cost
          -5000.0*measure_force(x)

x0 = [0.5*NSN0548_outer_diameter, tube_outer_diameter+20,
      NSN0548_length, tube_outer_diameter + 30, 30*NSN0548_length]

lower = [0.1, tube_outer_diameter+0.1,0.1,0.1,NSN0548_length]
upper = [NSN0548_length, tube_outer_diameter+20,NSN0548_length,20.0,100.0]

x0 = ((x,y)->(x+y)/2).(lower,upper)



femmprocess = FEMMfilelink.startfemm()
FEMMfilelink.testfilelink(timeout_s=1) || throw(ErrorException("filelink broken"))
FEMMfilelink.writeifile("dofile(\"one_magnet.lua\")")

inner_optimizer = NelderMead()
options = Optim.Options(x_tol=0.01, f_tol=0.001, outer_iterations = 4, iterations=4, store_trace=true,show_trace=true,show_every=1,time_limit=500,f_calls_limit=100)
result = optimize(cost,lower,upper,x0,Fminbox(inner_optimizer),options)
x = Optim.minimizer(result)
force = measure_force(x)
one_magnet(x)

kill(femmprocess)
