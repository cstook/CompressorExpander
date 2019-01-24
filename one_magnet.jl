using PyCall
@pyimport femm
using Optim
const air = ("Air", 1, 0, "<None>", 0, 0, 1)

function blockprop(x,y,property,outerspace::Bool=false)
  femm.mi_addblocklabel(x,y)
  femm.mi_selectrectangle(x,y,x,y,2)
  femm.mi_setblockprop(property...)
  outerspace && femm.mi_attachouterspace()
  femm.mi_clearselected()
  return nothing
end

function rectangle(x1,y1,x2,y2)
  # four nodes with segments
  femm.mi_addnode(x1,y1)
  femm.mi_addnode(x1,y2)
  femm.mi_addsegment(x1,y1,x1,y2)
  femm.mi_addnode(x2,y2)
  femm.mi_addsegment(x1,y2,x2,y2)
  femm.mi_addnode(x2,y1)
  femm.mi_addsegment(x2,y2,x2,y1)
  femm.mi_addsegment(x2,y1,x1,y1)
  return nothing
end

function rectangle(x1,y1,x2,y2,property)
  rectangle(x1,y1,x2,y2)
  blockprop(0.5*(x1+x2),0.5*(y1+y2),property)
  return nothing
end

function halfcircleonaxis(y1,y2)
  femm.mi_addnode(0,y1)
  femm.mi_addnode(0,y2)
  femm.mi_addarc(0,y1,0,y2,180,1)
  femm.mi_addsegment(0,y1,0,y2)
  return nothing
end
function kelvinboundry(r::Float64,y::Float64=0.0,outerproperty=air)
  rout = 0.1*r
  yout = 1.2*r + y
  y1 = y-r
  y2 = y+r
  halfcircleonaxis(y1,y2)
  y3 = yout-rout
  y4 = yout+rout
  halfcircleonaxis(y3,y4)
  blockprop(0.5*rout,yout, outerproperty, true)
  femm.mi_addboundprop("Kelvin_Boundry",0,0,0,0,0,0,0,0,4,0,0)
  femm.mi_selectarcsegment(0,y1)
  femm.mi_selectarcsegment(0,y3)
  femm.mi_setarcsegmentprop(1,"Kelvin_Boundry",0,5)
  femm.mi_clearselected()
  femm.mi_defineouterspace(yout,rout,r)
  return nothing
end


function group(x1,y1,x2,y2,group)
  femm.mi_selectrectangle(x1,y1,x2,y2,group)
  femm.mi_setgroup(group)
  femm.mi_clearselected()
  return nothing
end

struct Magnet{T}
  rhole :: Float64
  router :: Float64
  halflength :: Float64
  material :: T
end


function piston(magnet::Magnet, lengthcap, materialcap)
  femm.mi_getmaterial(magnet.material[1])
  if lengthcap>0
    femm.mi_getmaterial(materialcap[1])
    x1 = magnet.rhole
    y1 = magnet.halflength
    x2 = magnet.router
    y2 = magnet.halflength+lengthcap
    rectangle(x1,y1,x2,y2, materialcap)
    rectangle(x1,-y1,x2,-y2, materialcap)
    femm.mi_addsegment(x1,y1,x1,-y1)
    femm.mi_addsegment(x2,y2,x2,-y2)
    blockprop(0.5*(x1+x2),0,magnet.material)
    group(x1,-y1,x2,y2,1)
    rp = sqrt(x2^2 + y2^2)
  else
    rp = piston(magnet)
  end
  return rp #  radius, centered on origin, which will enclose piston
end

function piston(magnet::Magnet)
  x1 = magnet.rhole
  y1 = magnet.halflength
  x2 = magnet.router
  rectangle(x1,-y1,x2,y1,magnet.material)
  group(x1,-y1,x2,y1,1)
  rp = sqrt(x2^2 + y1^2)
  return rp
end

function coil(r, y, Δr, Δy, current)
  femm.mi_addmaterial("COIL_P",1,1,0,current)
  rectangle(r, y, r+Δr, y+Δy, ("COIL_P", 1, 0, "<None>", 0, 2, 1))
  femm.mi_addmaterial("COIL_N",1,1,0,-current)
  rectangle(r, -y, r+Δr, -y-Δy, ("COIL_N", 1, 0, "<None>", 0, 2, 1))
  group(r,-y,  r+Δr, y+Δy, 2)
  return sqrt((r+Δr)^2+ (y+Δy)^2)
end

function tube(r, Δr, Δy, propertytube)
  femm.mi_getmaterial(propertytube[1])
  halfΔy = 0.5*Δy
  rectangle(r,-halfΔy,r+Δr,+halfΔy,propertytube)
  group(r,-halfΔy,r+Δr,+halfΔy,3)
  return sqrt((r+Δr)^2+halfΔy^2)
end

function onemagnet(magnet::Magnet,
                   Δycap, propertycap,
                   rgap, ygap, Δrcoil, currentcoil,
                   Δrtube, Δytube, propertytube,
                   airproperty = air)
  femm.newdocument(0)
  femm.mi_probdef(0,"millimeters","axi",1e-10)
  femm.mi_getmaterial(airproperty[1])
  rk1 = piston(magnet,Δycap,propertycap)
  rcoil = magnet.router+rgap
  ycoil = 0.5*ygap
  Δycoil = 2.0*(magnet.halflength+0.5*Δycap-0.5*ygap)
  rk2 = coil(rcoil, ycoil, Δrcoil, Δycoil, currentcoil)
  rtube = rcoil + Δrcoil
  rk3 = tube(rtube, Δrtube, Δytube, propertytube)
  blockprop((rtube+Δrtube)*1.1,0.0,airproperty)
  kelvinboundry(max(rk1,rk2,rk3)*1.2)
end

function measuregroup1force()
  femm.mi_analyze(1)
  femm.mi_loadsolution()
  femm.mo_groupselectblock(1)
  force = femm.mo_blockintegral(19) # y part of steady-state weighted stress tensor force
  femm.mo_close()
  return force
end

function setcurrent(i)
  femm.mi_modifymaterial("COIL_P",4,i)
  femm.mi_modifymaterial("COIL_N",4,-i)
end



function testonemagnetoptim(;keepfemmopen::Bool=false)
  function force(x,magnet,pressure_tube_outer_radius,propertycap,propertytube,filename)
    onemagnet(magnet, x[1], propertycap,
              pressure_tube_outer_radius-magnet.router, x[3], x[2], 10,
              x[4], x[5], propertytube)
    femm.mi_saveas("onemagnet.FEM")
    f = measuregroup1force()
    femm.mi_close()
    f
  end
  volumecap(x,magnet) = π*x[1]*(magnet.router^2-magnet.rhole^2)
  function volumecoil(x,magnet,pressure_tube_outer_radius)
    rin = pressure_tube_outer_radius
    rout = rin + x[2]
    Δy = 2.0*(magnet.halflength+0.5*x[1]-0.5*x[3])
    volume_per_coil = π*Δy*(rout^2 - rin^2)
    both_coils = 2.0*volume_per_coil
  end
  function volumetube(x,pressure_tube_outer_radius)
    rin = pressure_tube_outer_radius+x[2]
    rout = rin + x[4]
    π*x[5]*(rout^2 - rin^2)
  end
  cost(x,magnet,pressure_tube_outer_radius,propertycap,propertytube,filename) =
    0.1*volumecap(x,magnet) +
    1.0*volumecoil(x, magnet, pressure_tube_outer_radius) +
    0.1*volumetube(x, pressure_tube_outer_radius) +
    -5000.0*force(x,magnet,pressure_tube_outer_radius,propertycap,propertytube,filename)

  femm.openfemm(1)
  propertycap = ("416 Stainless Steel", 1, 0, "<None>", 0, 1, 1)
  propertymagnet = ("NdFeB 40 MGOe", 1, 0, "<None>", 90, 1, 1)
  propertytube = ("416 Stainless Steel", 1, 0, "<None>", 0, 3, 1)
  NSN0548 = Magnet(0.5*2.54, 0.5*6.45, 0.5*6.35, propertymagnet)
  magnet = NSN0548
  pressure_tube_outer_radius = 0.5*(3/8)*25.4
  #=
  x[1] = cap_length
  x[2] = Δrcoil
  x[3] = coil_gap
  x[4] = magnetics_wallthichness
  x[5] = magnetics_length
  =#

  # x = [5.96367, 4.87066, 1.82978, 0.520373, 57.0447]; f = 1.92  # Fminbox, NelderMead
  # x = [6.34989, 4.89634, 1.71620, 0.42899, 61.97704] # SAMIN -5001.98381
  # x = [6.35, 4.8625, 1.55555, 0.442986, 44.3412] # ParticleSwarm n_particles = 10 -4.873306e+03 f=1.98 50 iterations
  # x= [5.92222, 5.35275, 1.75723, 0.435882, 44.1791] # SAMIN -4738.04453 f=2.03 500 iterations

  filename = tempname()
  lower = [0.1, pressure_tube_outer_radius+0.1,0.1,0.1,2*magnet.halflength]
  upper = [2*magnet.halflength, pressure_tube_outer_radius+20,2*magnet.halflength,20.0,100.0]
  x0 = ((x,y)->(x+y)/2).(lower,upper)
  volumecap(x0,magnet)
  volumecoil(x0,magnet,pressure_tube_outer_radius)
  volumetube(x0, pressure_tube_outer_radius)
  force(x0,magnet,pressure_tube_outer_radius,propertycap,propertytube,filename)
  #=
  inner_optimizer = NelderMead()
  options = Optim.Options(outer_iterations = 10, iterations=100, store_trace=true,show_trace=true,show_every=1,time_limit=5000,f_calls_limit=1000)
  optimizer = Fminbox(inner_optimizer)
  =#

  options = Optim.Options(iterations=500)
  optimizer = SAMIN(;
        nt = 5,     # reduce temperature every nt*ns*dim(x_init) evaluations
        ns = 5,     # adjust bounds every ns*dim(x_init) evaluations
        rt = 0.9,     # geometric temperature reduction factor: when temp changes, new temp is t=rt*t
        neps = 5,   # number of previous best values the final result is compared to
        f_tol = 1e-4, # the required tolerance level for function value comparisons
        x_tol = 1e-2, # the required tolerance level for x
        coverage_ok = false, # if false, increase temperature until initial parameter space is covered
        verbosity = 3) # scalar: 0, 1, 2 or 3 (default = 0

#=
  options = Optim.Options(f_tol = 10,x_tol = 1e-1,store_trace=true,show_trace=true,show_every=1,iterations=50)
  optimizer = Optim.ParticleSwarm(;
    lower = lower,
    upper = upper,
    n_particles = 10)

=#
  result = optimize(
    x->cost(x,magnet,pressure_tube_outer_radius,propertycap,propertytube,filename),
    lower,upper,x0,optimizer,options
    )
  x = Optim.minimizer(result)
  r = (x, force(x,magnet,pressure_tube_outer_radius,propertycap,propertytube,filename))
  if keepfemmopen
    onemagnet(magnet, x[1], propertycap,
              pressure_tube_outer_radius-magnet.router, x[3], x[2], 10,
              x[4], x[5], propertytube)
  else
    femm.closefemm()
  end
  return r
end

function testonemagnet()
  propertycap = ("416 Stainless Steel", 1, 0, "<None>", 0, 1, 1)
  propertymagnet = ("NdFeB 40 MGOe", 1, 0, "<None>", 90, 1, 1)
  propertytube = ("416 Stainless Steel", 1, 0, "<None>", 0, 3, 1)
  femm.openfemm(1)
  NSN0548 = Magnet(0.5*2.54, 0.5*6.45, 0.5*6.35, propertymagnet)
  onemagnet(NSN0548,5,propertycap,2,2,5,10,5,40,propertytube)
  femm.mi_saveas("onemagnet.FEM")
  setcurrent(5)
  f5 = measuregroup1force()
  setcurrent(0)
  f0 = measuregroup1force()
  setcurrent(10)
  f10 = measuregroup1force()
  # femm.closefemm()
  (f10,f5,f0)
end
