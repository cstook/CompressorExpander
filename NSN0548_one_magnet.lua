dofile("one_magnet.lua")
magnet_hole_diameter = 0   -- 2.54 for NSN0548
magnet_outer_diameter = 6.45
magnet_length = 6.35
tube_outer_diameter = (3/8)*25.4
coil_outer_diameter = 30
coil_length = 0.49*magnet_length
magnetics_outer_diameter = 50
magnetics_length = 20*magnet_length

one_magnet(magnet_hole_diameter, magnet_outer_diameter, magnet_length,
            tube_outer_diameter,
            coil_outer_diameter, coil_length,
            magnetics_outer_diameter, magnetics_length)


increment = 0.1*magnet_length
steps = 30
mincurrent = 0
maxcurrent = 10
stepcurrent = 5
savefilename = "NSN0548_sweep.csv"
slide_current(increment, steps, mincurrent, maxcurrent, stepcurrent, savefilename)
