function rectangle(x1,y1,x2,y2)
  -- four nodes with segments
  mi_addnode(x1,y1)
  mi_addnode(x1,y2)
  mi_addsegment(x1,y1,x1,y2)
  mi_addnode(x2,y2)
  mi_addsegment(x1,y2,x2,y2)
  mi_addnode(x2,y1)
  mi_addsegment(x2,y2,x2,y1)
  mi_addsegment(x2,y1,x1,y1)
end

function one_magnet(magnet_hole_diameter, magnet_outer_diameter, magnet_length,
         cap_length,
         tube_outer_diameter,
         coil_outer_diameter, coil_length,
         magnetics_outer_diameter, magnetics_length)
  -- coil length must be < magnet length
  newdocument(0)
  mi_probdef(0,"millimeters","axi",1e-10)
  r0 = 0.5*magnet_hole_diameter
  r1 = 0.5*magnet_outer_diameter
  r0r5 = 0.5*(r0+r1)
  r2 = 0.5*tube_outer_diameter
  r1r5 = 0.5*(r1+r2)
  r3 = 0.5*coil_outer_diameter
  r2r5 = 0.5*(r2+r3)
  r4 = 0.5*magnetics_outer_diameter
  r3r5 = 0.5*(r3+r4)
  --
  -- start piston
  --
  hm = 0.5*magnet_length
  rectangle(r0,-hm,r1,hm)
  mi_addblocklabel(r0r5,0)
  mi_getmaterial("NdFeB 40 MGOe")
  mi_selectrectangle(r0r5,0,r0r5,0,2)
  mi_setblockprop("NdFeB 40 MGOe", 1, 0, "<None>", 90, 1, 1)
  mi_clearselected()
  if cap_length~=0 then
    -- add steel caps to piston
    mi_getmaterial("416 Stainless Steel")
    mi_addnode(r0,hm+cap_length)
    mi_addnode(r1,hm+cap_length)
    mi_addsegment(r0,hm+cap_length,r0,hm)
    mi_addsegment(r0,hm+cap_length,r1,hm+cap_length)
    mi_addsegment(r1,hm+cap_length,r1,hm)
    mi_addblocklabel(r0r5,hm+0.5*cap_length)
    mi_selectrectangle(r0r5,hm+0.5*cap_length,r0r5,hm+0.5*cap_length,2)
    mi_setblockprop("416 Stainless Steel", 1, 0, "<None>", 0, 1, 1)
    mi_clearselected()
    mi_addnode(r0,-hm-cap_length)
    mi_addnode(r1,-hm-cap_length)
    mi_addsegment(r0,-hm-cap_length,r0,-hm)
    mi_addsegment(r0,-hm-cap_length,r1,-hm-cap_length)
    mi_addsegment(r1,-hm-cap_length,r1,-hm)
    mi_addblocklabel(r0r5,-hm-0.5*cap_length)
    mi_selectrectangle(r0r5,-hm-0.5*cap_length,r0r5,-hm-0.5*cap_length,2)
    mi_setblockprop("416 Stainless Steel", 1, 0, "<None>", 0, 1, 1)
    mi_clearselected()
  end
  mi_selectrectangle(r0,-hm-cap_length,r1,hm+cap_length,4)
  mi_setgroup(1)
  mi_clearselected()
  --
  -- end piston
  --
  --
  -- start coil
  --
  hc = 0.5*coil_length
  hcap = 0.5*cap_length
  rectangle(r2,hm+hcap-hc,r3,hm+hcap+hc)
  mi_addblocklabel(r2r5,hm+hcap)
  mi_selectrectangle(r2r5,hm+hcap,r2r5,hm+hcap,2)
  mi_addmaterial("COIL_P",1,1,0,10)
  mi_setblockprop("COIL_P", 1, 0, "<None>", 0, 2, 1)
  mi_clearselected()
  rectangle(r2,-hm-hcap-hc,r3,-hm-hcap+hc)
  mi_addblocklabel(r2r5,-hm-hcap)
  mi_selectrectangle(r2r5,-hm-hcap,r2r5,-hm-hcap,2)
  mi_addmaterial("COIL_N",1,1,0,-10)
  mi_setblockprop("COIL_N", 1, 0, "<None>", 0, 2, 1)
  mi_clearselected()
  mi_selectrectangle(r2,-hm-hcap-hc,r3,hm+hcap+hc,4)
  mi_setgroup(2)
  mi_clearselected()
  --
  -- end coil
  --
  --
  -- start magnetics
  --
  hy = 0.5*magnetics_length
  rectangle(r3,-hy,r4,hy)
  mi_addblocklabel(r3r5,0)
  mi_selectrectangle(r3r5,0,r3r5,0,2)
  mi_getmaterial("416 Stainless Steel")
  mi_setblockprop("416 Stainless Steel", 1, 0, "<None>", 0, 3, 1)
  mi_clearselected()
  mi_selectrectangle(r3,-hy,r4,hy,4)
  mi_setgroup(3)
  mi_clearselected()
  --
  -- end magnetics
  --
  --
  -- start air
  --
  mi_addblocklabel(1.1*r4,0)
  mi_selectrectangle(1.1*r4,0,1.1*r4,0,2)
  mi_getmaterial("Air")
  mi_setblockprop("Air", 1, 0, "<None>", 0, 0, 1)
  mi_clearselected()
  --
  -- stop air
  --
  --
  -- start boundry
  --
  --  mi_makeABC(10,3*(magnetics_length+r4),0,0,0)
  --
  -- Kelvin transformation
  r_in_a = sqrt((4*(hm+cap_length))^2+r1^2)
  r_in_b = sqrt(hy^2+r4^2)*1.2
  r_in = max(r_in_a, r_in_b)
  r_out = 0.1*r_in
  y_out = 1.2*r_in
  mi_addnode(0,-r_in)
  mi_addnode(0,r_in)
  mi_addarc(0,-r_in,0,r_in,180,1)
  mi_addsegment(0,-r_in,0,r_in)
  mi_addnode(0,y_out-r_out)
  mi_addnode(0,y_out+r_out)
  mi_addarc(0,y_out-r_out,0,y_out+r_out,180,1)
  mi_addsegment(0,y_out-r_out,0,y_out+r_out)
  mi_addblocklabel(0.5*r_out,y_out)
  mi_selectrectangle(0.5*r_out,y_out,0.5*r_out,y_out,2)
  mi_setblockprop("Air", 1, 0, "<None>", 0, 0, 1)
  mi_clearselected()
  mi_addboundprop("Kelvin_Boundry",0,0,0,0,0,0,0,0,4,0,0)
  mi_selectarcsegment(0,-r_in)
  mi_selectarcsegment(0,y_out-r_out)
  mi_setblockprop("Kelvin_Boundry",1,0,"<None>",0,0,1)
  mi_clearselected()
  mi_defineouterspace(y_out,r_out,r_in)
  mi_selectrectangle(0,y_out-r_out,y_out+r_out,y_out+r_out)
  mi_attachouterspace()
  mi_clearselected()
  --
  -- end boundry
  --
  mi_saveas("one_magnet.FEM")
end

function slide_current(increment, steps, mincurrent, maxcurrent, stepcurrent, savefilename)
  -- measure force on group 1
  -- increment must be positive
  -- takes steps increments in both postive and negative directions
  -- for 2*steps+1 position steps
  io = openfile(savefilename,"w")
  offset = -increment*steps
  mi_selectgroup(1)
  mi_movetranslate(0,offset,4)
  for k = 0, 2*steps do
    if k~=0 then
      mi_selectgroup(1)
      mi_movetranslate(0,increment,4)
    end
    write(io,k*increment+offset,",")
    for i = mincurrent,maxcurrent,stepcurrent do
      -- do analysis
      mi_modifymaterial("COIL_P",4,i)
      mi_modifymaterial("COIL_N",4,-i)
      mi_analyze(1) -- set to 1 to minimize window
      mi_loadsolution()
      mo_groupselectblock(1)
      force = mo_blockintegral(19) -- y part of steady-state weighted stress tensor force
      write(io,force)
      if i<maxcurrent then
          write(io,",")
      else
          write(io,"\n")
      end
    end
    flush(io)
  end
end

function sweep_parameters(savefilename)
  io = openfile(savefilename,"w")
  magnet_hole_diameter = 2.54
  magnet_outer_diameter = 6.45
  magnet_length = 6.35
  tube_outer_diameter = (3/8)*25.4

  -- write header
  write(io,"magnet_hole_diameter,magnet_outer_diameter,magnet_length,")
  write(io,"cap_length,tube_outer_diameter,coil_outer_diameter,coil_length,")
  write(io,"magnetics_outer_diameter,magnetics_length,")
  write(io,"force","\n")
  for cap_length = 0, magnet_outer_diameter+5, 1 do
    for  coil_outer_diameter = tube_outer_diameter+1,tube_outer_diameter+31,1 do
      for coil_length = cap_length+0.1, cap_length+magnet_length-.1, .1 do
        magnetics_outer_diameter = coil_outer_diameter + 10
        magnetics_length = 3*(magnet_length+2*cap_length)
        one_magnet(magnet_hole_diameter, magnet_outer_diameter, magnet_length,
                  cap_length,
                  tube_outer_diameter,
                  coil_outer_diameter, coil_length,
                  magnetics_outer_diameter, magnetics_length)
        mi_analyze(1) -- set to 1 to minimize window
        mi_loadsolution()
        mo_groupselectblock(1)
        force = mo_blockintegral(19) -- y part of steady-state weighted stress tensor force
        write(io,magnet_hole_diameter,",",magnet_outer_diameter,",",magnet_length,",")
        write(io,cap_length,",",tube_outer_diameter,",",coil_outer_diameter,",",coil_length,",")
        write(io,magnetics_outer_diameter,",",magnetics_length,",")
        write(io,force,"\n")
        flush(io)
        mi_close()
      end
    end
  end
end

function measure_force(magnet_hole_diameter, magnet_outer_diameter, magnet_length,
         cap_length,
         tube_outer_diameter,
         coil_outer_diameter, coil_length,
         magnetics_outer_diameter, magnetics_length)
  one_magnet(magnet_hole_diameter, magnet_outer_diameter, magnet_length,
           cap_length,
           tube_outer_diameter,
           coil_outer_diameter, coil_length,
           magnetics_outer_diameter, magnetics_length)
  mi_analyze(1) -- set to 1 to minimize window
  mi_loadsolution()
  mo_groupselectblock(1)
  force = mo_blockintegral(19) -- y part of steady-state weighted stress tensor force
  mi_close()
  return force
end
