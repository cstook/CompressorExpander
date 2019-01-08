dofile("two_magnets.lua")
magnet_hole_diameter = 2.54
magnet_outer_diameter = 6.45
magnet_length = 6.35
tube_outer_diameter = (3/8)*25.4
coil_outer_diameter = 20
magnetics_outer_diameter = 30

two_magnets(magnet_hole_diameter, magnet_outer_diameter, magnet_length,
            tube_outer_diameter,
            coil_outer_diameter,
            magnetics_outer_diameter)

slide_current(-0.1*magnet_length, 20)
