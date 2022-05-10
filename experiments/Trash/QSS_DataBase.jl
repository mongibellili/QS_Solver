# database file contains three structs data , time , model
#=
mutable struct QSSdata    
    #declare
    quantum :: Vector{Float64}   
    x :: Vector{Float64}
   # q ::  Vector{Float64} 
   q :: Vector{Float64}
    states :: Int 
    order :: Int
    function QSSdata(states :: Int,order :: Int )
        d = new()
        const d.states=states
        const d.order=order
        #create Vectors
        d.quantum = Vector{Float64}(undef, states)
        d.x =  Vector{Float64}(undef, (order+1)*states)#case1 for x case2 for DERx...
       # d.q =  Vector{Float64}(undef, (order+1)*states)
       d.q = Vector{Float64}(undef, (order+1)*states)
        #create arrays inside Vectors
       # for i = 1:(order+1)*states 
            #d.x[i]=Array{Float64}[]
           # d.q[i]=Array{Float64}[]
       # end
     
        d
    end
end
#given an initialTime and number of states
# it initializes t for all x and all q
mutable struct QSStime  
    time :: Float64
    nextStateTime :: Vector{Float64}   
    tx ::  Vector{Float64} 
    #tq ::  Vector{Float64} 
    tq :: Vector{Float64} 
    states :: Int 
    minValue :: Float64   
    minIndex :: Int 
    function QSStime(states :: Int ,initTime :: Float64)
        t = new()
        const t.states=states
        t.time= initTime
        t.nextStateTime=Vector{Float64}(undef, states)
        t.tx =  Vector{Float64}(undef, states)
       # t.tq =  Vector{Float64}(undef, states) # i think this is needed for qss2 and higher
        t.tq=Vector{Float64}(undef, states)
        t
    end
end
mutable struct QSSmodel 
    
    jacobian :: Array{Float64, 2}   
    dep ::  Vector{Array{Int}}  
    #counter::  Array{Float64} 
   
    function QSSmodel(jac :: Array{Float64, 2}  )
        m = new()
        const m.jacobian= jac
        #m.counter=Array{Float64}[]
        const m.dep=createDependencyMatrix(jac)
        
        m
    end
    function createDependencyMatrix(jac :: Array{Float64, 2}  )
       # extract dependency matrix from jac
        epselon=1e-6
       nRows=size(jac,1)
       nColumns=size(jac,2)
       dep=Vector{Array{Int}}(undef, nColumns)

       for j=1:nColumns
            dep[j]=Array{Float64}[]
            for i=1:nRows
                if jac[i,j] < -epselon ||  jac[i,j] > epselon # different than zero
                    push!(dep[j],i)
                end
            end
        end
        

        return dep

        
    end

end
=#
# database file contains with saving x and t
struct QSSdata    
    #declare
    quantum :: Vector{Float64}   
    x :: Vector{Array{Float64}}
    q :: Vector{Float64}  
end
#given an initialTime and number of states
# it initializes t for all x and all q
mutable struct QSStime  
    time :: Float64
    nextStateTime :: Vector{Float64}   
    tx ::  Vector{Array{Float64}}  
    tq :: Vector{Float64} 
    states :: Int 
    minValue :: Float64   
    minIndex :: Int 
    function QSStime(states :: Int ,initTime :: Float64)
        t = new()
        const t.states=states
        t.time= initTime
        t.nextStateTime=Vector{Float64}(undef, states)
        t.tx =  Vector{Array{Float64}}(undef, states)
       # t.tq =  Vector{Float64}(undef, states) # i think this is needed for qss2 and higher
        t.tq=Vector{Float64}(undef, states)
        t
    end
end
mutable struct QSSmodel 
    
    jacobian :: Array{Float64, 2}   
    dep ::  Vector{Array{Int}}  
    states::Int
   
    function QSSmodel(jac :: Array{Float64, 2}  )
        m = new()
        const m.jacobian= jac
        m.states= computeStates(jacobian)
        const m.dep=createDependencyMatrix(jac)
        
        m
    end
    function createDependencyMatrix(jac :: Array{Float64, 2}  )
       # extract dependency matrix from jac
        epselon=1e-6
       nRows=size(jac,1)
       nColumns=size(jac,2)
       dep=Vector{Array{Int}}(undef, nColumns)

       for j=1:nColumns
            dep[j]=Array{Float64}[]
            for i=1:nRows
                if jac[i,j] < -epselon ||  jac[i,j] > epselon # different than zero
                    push!(dep[j],i)
                end
            end
        end
        

        return dep

        
    end
    function computeStates(jacobian :: Array{Float64, 2})
        # return number of rows
        return size(jacobian,1)
    end

end