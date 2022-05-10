struct QSS_simulator{T,O,R,Z}
    quantum :: MVector{T,Float64} 
    x :: MVector{O,Float64}
    q :: MVector{R,Float64} 
    tx ::  MVector{T,Float64} 
    tq :: MVector{T,Float64} 
    nextStateTime :: MVector{T,Float64}    
    nextEventTime :: MVector{Z,Float64}  
end

function QSS_Solve(settings :: ProblemSetting,prob::qssProblem)
    order=getOrderfromSolverMethod(settings.solver)
    states = computeStates(prob.initConditions)
    inputs = computeInputs(prob.inputVars)
    events = computeEvents(prob.eventHandlerFunctions)
    solver=settings.solver
    quantum = @MVector zeros(states)
    x = @MVector zeros(states*(order+1))#4=2states*(order1+1)
    q = @MVector zeros(states*(order))
    nextStateTime = @MVector zeros(states)
    tx = @MVector zeros(states)
    tq = @MVector zeros(states)
    nextEventTime=@MVector zeros(events)
    qssSimulator= QSS_simulator(quantum,x,q,tx,tq,nextStateTime,nextEventTime)
    QSS_integrate(solver,qssSimulator,settings,prob)   
end



#-----------------------------------------------------easy qss--------------------------------------
struct EasyQSS_simulator{T,O,R}
    quantum :: MVector{T,Float64} 
    x :: MVector{O,Float64}
    q :: MVector{R,Float64} 
    tx ::  MVector{T,Float64} 
    tq :: MVector{T,Float64} 
    nextStateTime :: MVector{T,Float64}    
end
function QSS_Solve(settings :: ProblemSetting,prob::easyqssProblem)
    order=getOrderfromSolverMethod(settings.solver)
    states = computeStates(prob.initConditions)
    solver=settings.solver
    quantum = @MVector zeros(states)
    x = @MVector zeros(states*(order+1))#4=2states*(order1+1)
    q = @MVector zeros(states*(order))
    nextStateTime = @MVector zeros(states)
    tx = @MVector zeros(states)
    tq = @MVector zeros(states)
    qssSimulator= EasyQSS_simulator(quantum,x,q,tx,tq,nextStateTime)
    QSS_integrate(solver,qssSimulator,settings,prob)   
end