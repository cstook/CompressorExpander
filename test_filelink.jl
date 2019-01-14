import FEMMfilelink
FEMMfilelink.clearfiles()
femmprocess = FEMMfilelink.startfemm()
FEMMfilelink.testfilelink()
FEMMfilelink.writeifile("dofile(\"one_magnet.lua\")")
FEMMfilelink.filelink("flput(measure_force(1,2,3,4,5,6,7,8,9))")
function measure_force(magnet_hole_diameter, magnet_outer_diameter, magnet_length,
                       cap_length,
                       tube_outer_diameter,
                       coil_outer_diameter, coil_length,
                       magnetics_outer_diameter, magnetics_length)
    FEMMfilelink.filelink("flput(measure_force($magnet_hole_diameter,$magnet_outer_diameter,$magnet_length,$cap_length,$tube_outer_diameter,$coil_outer_diameter,$coil_length,$magnetics_outer_diameter,$magnetics_length))")
end

measure_force(1,2,3,4,5,6,7,8,9)

kill(femmprocess)

# use writeifile when no output is expected
FEMMfilelink.writeifile("newdocument(1)");
FEMMfilelink.readofile()
