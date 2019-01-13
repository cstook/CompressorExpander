const femm_directory = "C:/femm42/bin"

const femm_files = (exe = joinpath(femm_directory,"femm.exe"),
                    ifile = joinpath(femm_directory,"ifile.txt"),
                    ofile = joinpath(femm_directory,"ofile.txt"))

function setup_filelink(femm_directory::AbstractString=femm_directory)
    clearfiles(femm_directory)
    femm = joinpath(femm_directory,"femm.exe")
    run(`$femm -filelink -windowhide`, wait=false)
end


function clearfiles(femm_directory::AbstractString=femm_directory)
    ifile = joinpath(femm_directory,"ifile.txt")
    ofile = joinpath(femm_directory,"ofile.txt")
    rm(ifile,force=true)
    rm(ofile,force=true)
    (ifile,ofile)
end

function readofile(ofile::AbstractString)
    for i=1:20
        wait(Timer(.1))
        isfile(ofile) && break
    end
    x = ""
    if isfile(ofile)
        open(ofile, read=true) do io
            x = read(io,String)
        end
    end
    x
end

function test_filelink(luacommand::AbstractString, femm_directory::AbstractString=femm_directory)
    (ifile,ofile)=clearfiles(femm_directory)
    open(ifile, create=true, write=true) do io
        write(io,luacommand)
    end
    readofile(ofile)
end





function filelinksend(luastatment::AbstractString, femm_files=femm_files)
    open(femm_files.ifile, create=true, write=true) do io
        write(io,luastatment)
    end
    readofile(femm_files.ofile)
end
function measure_force(magnet_hole_diameter, magnet_outer_diameter, magnet_length,
                       cap_length,
                       tube_outer_diameter,
                       coil_outer_diameter, coil_length,
                       magnetics_outer_diameter, magnetics_length,
                       femm_files = femm_files)
   open(femm_files.ifile, create=true, write=true) do io
       write(io,"flput(measure_force($magnet_hole_diameter, $magnet_outer_diameter, $magnet_length,$cap_length,$tube_outer_diameter,$coil_outer_diameter, $coil_length,$magnetics_outer_diameter, $magnetics_length))")
   end
   x = readofile(femm_files.ofile)
  parse(Float64,match(r"\[(.*)\]",x).captures[1])
end




setup_filelink()
test_filelink("dofile(\"one_magnet.lua\")")
test_filelink("flput(measure_force(1,2,3,4,5,6,7,8,9))")
test_filelink("flput(2+2)")



setup_filelink()
filelinksend("dofile(\"one_magnet.lua\")")
x = measure_force(1,2,3,4,5,6,7,8,9)
