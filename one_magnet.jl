using PyCall
@pyimport femm
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
  rcoil = magnet.router+ygap
  ycoil = 0.5*ygap
  Δycoil = 2.0*magnet.halflength+Δycap-ycoil
  rk2 = coil(rcoil, ycoil, Δrcoil, Δycoil, currentcoil)
  rtube = rcoil + Δrcoil
  rk3 = tube(rtube, Δrtube, Δytube, propertytube)
  blockprop((rtube+Δrtube)*1.1,0.0,airproperty)
  kelvinboundry(max(rk1,rk2,rk3)*1.2)
end


function testonemagnet()
  propertycap = ("416 Stainless Steel", 1, 0, "<None>", 0, 1, 1)
  propertymagnet = ("NdFeB 40 MGOe", 1, 0, "<None>", 90, 1, 1)
  propertytube = ("416 Stainless Steel", 1, 0, "<None>", 0, 3, 1)
  femm.openfemm(1)
  femm.newdocument(0)
  femm.mi_probdef(0,"millimeters","axi",1e-10)

  NSN0548 = Magnet(0.5*2.54, 0.5*6.45, 0.5*6.35, propertymagnet)
  onemagnet(NSN0548,5,propertycap,2,2,5,10,5,40,propertytube)
  femm.mi_saveas("onemagnet.FEM")
end

testonemagnet()



femm.mi_close()

femm.mi_getmaterial("Air")
rectangle(1,1,2,2,air)


kelvinboundry(0,10,air)
y = 0
r = 10
outerproperty=air

magnet = Magnet(1.0,2.0,3.0,propertymagnet)
piston(magnet,3.0,propertycap)
coil(4, 3, 2, 2, 10)
tube(10,1,20,propertytube)

femm.mi_close()
onemagnet(magnet,5,propertycap,2,2,5,10,5,15,propertytube)
