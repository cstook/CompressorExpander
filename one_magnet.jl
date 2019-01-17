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
function kelvinboundry(y,r,outerproperty=air)
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


femm.openfemm(1)
femm.newdocument(0)
femm.mi_probdef(0,"millimeters","axi",1e-10)
femm.mi_getmaterial("Air")
rectangle(1,1,2,2,air)


kelvinboundry(0,10,air)
y = 0
r = 10
outerproperty=air
