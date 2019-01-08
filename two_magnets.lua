

function two_magnets(magnet_hole_diameter, magnet_outer_diameter, magnet_length,
         tube_outer_diameter,
         coil_outer_diameter,
         magnetics_outer_diameter)
    newdocument(0)
    mi_probdef(0,"millimeters","axi",1e-8)
    r0 = 0.5*magnet_hole_diameter
    r1 = 0.5*magnet_outer_diameter
    r3 = 0.5*tube_outer_diameter
    r4 = 0.5*coil_outer_diameter
    r5 = 0.5*magnetics_outer_diameter
    --
    -- start piston
    --
    piston_length = 5*magnet_length -- 2 magnets, 3 soft magnetic slugs
    -- piston is symmectric around y=0
    half_piston = 0.5*piston_length
    half_magnet = 0.5*magnet_length
    for y = -half_piston, half_piston, magnet_length do
        mi_addnode(r0,y)
        mi_addnode(r1,y)
        mi_addsegment(r0,y,r1,y)
    end
    rc1 = (r0+r1)/2
    for i = 0,4 do
        y = (i-2.5)*magnet_length
        mi_addsegment(r0,y,r0,y+magnet_length)
        mi_addsegment(r1,y,r1,y+magnet_length)
        y = (i-2)*magnet_length
        mi_addblocklabel(rc1,y)
    end
    mi_getmaterial("NdFeB 40 MGOe")
    for i = 0,1 do
        y = (i*2-1)*magnet_length
        mi_selectrectangle(rc1, y, rc1, y, 2)
        dir = 90*(mod(i,2)*2-1)
        mi_setblockprop("NdFeB 40 MGOe", 1, 0, "<None>", dir, 1, 1)
        mi_clearselected()
    end
    mi_getmaterial("416 Stainless Steel")
    for i = 0,3 do
        y = (i*2-2)*magnet_length
        mi_selectrectangle(rc1, y, rc1, y, 2)
        mi_setblockprop("416 Stainless Steel", 1, 0, "<None>", 0, 1, 1)
        mi_clearselected()
    end
    mi_selectrectangle(r0,-0.5*piston_length,r1,0.5*piston_length,4)
    mi_setgroup(1)
    mi_clearselected()


    --
    -- end piston
    --
    --
    -- start coil
    --
    y = magnet_length
    mi_addnode(r3,y)
    mi_addnode(r3,-y)
    mi_addsegment(r3,y,r3,-y)
    mi_addnode(r4,-y)
    mi_addsegment(r3,-y,r4,-y)
    mi_addnode(r4,y)
    mi_addsegment(r4,-y,r4,y)
    mi_addsegment(r4,y,r3,y)
    rc2 = 0.5*(r3+r4)
    mi_addblocklabel(rc2,0)
    mi_selectrectangle(rc2,0,rc2,0,2)
    mi_addmaterial("COIL",1,1,0,10)
    mi_setblockprop("COIL", 1, 0, "<None>", 0, 2, 1)
    mi_clearselected()
    mi_addnode(r3,3*y)
    mi_addsegment(r3,y,r3,3*y)
    mi_addnode(r5,3*y)
    mi_addsegment(r3,3*y,r5,3*y)
    mi_addnode(r5,-3*y)
    mi_addsegment(r5,3*y,r5,-3*y)
    mi_addnode(r3,-3*y)
    mi_addsegment(r5,-3*y,r3,-3*y)
    mi_addsegment(r3,-3*y,r3,y)
    rc3 = 0.5*(r4+r5)
    mi_addblocklabel(rc3,0)
    mi_selectrectangle(rc3,0,rc3,0,2)
    mi_setblockprop("416 Stainless Steel", 1, 0, "<None>", 0, 2, 1)
    mi_clearselected()
    mi_selectrectangle(r3,-3*y,r5,3*y)
    mi_setgroup(2)
    mi_clearselected()
    mi_addblocklabel(r5+magnet_length,0)
    mi_selectrectangle(r5+magnet_length,0,r5+magnet_length,0,2)
    ---
    --- end coil
    ---
    mi_getmaterial("Air")
    mi_setblockprop("Air", 1, 0, "<None>", 0, 0, 1)
    mi_clearselected()
    mi_makeABC(10,3*(piston_length+r5),0,0,0)
    mi_saveas("two_magnets.FEM")
end

function slide(increment, steps)
    -- measure force on group 1 at steps increments along y axis
    io = openfile("slide.csv","w")
    for i = 0,steps do
        -- do analysis
        mi_analyze(1) -- set to 1 to minimize window
        mi_loadsolution()
    --    mo_seteditmode("area")
        mo_groupselectblock(1)
        force = mo_blockintegral(19) -- y part of steady-state weighted stress tensor force
        write(io,i*increment," , ",force,"\n")
        -- move group 1
        if i<steps then
            mi_selectgroup(1)
            mi_movetranslate(0,increment,4)
        end
    end
    closefile(io)
end

function slide_current(increment, steps)
    -- measure force on group 1 at steps increments along y axis
    -- current 0 to 10 A/mm^2 at each step
    io = openfile("slide.csv","w")
    maxcurrent = 10
    for i = 0,steps do
        write(io,i*increment,",")
        for current = 0,maxcurrent do
            -- do analysis
            mi_modifymaterial("COIL",4,current)
            mi_analyze(1) -- set to 1 to minimize window
            mi_loadsolution()
            mo_groupselectblock(1)
            force = mo_blockintegral(19) -- y part of steady-state weighted stress tensor force
            write(io,force)
            if current<maxcurrent then
                write(io,",")
            else
                write(io,"\n")
            end
        end
        -- move group 1
        if i<steps then
            mi_selectgroup(1)
            mi_movetranslate(0,increment,4)
        end
        flush(io)
    end
    closefile(io)
end
