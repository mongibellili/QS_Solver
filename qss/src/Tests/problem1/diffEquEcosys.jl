using DifferentialEquations
using Plots
function odeDiffEquPackage()
    function funcName(du,u,p,t)# api requires four args
        du[1] = u[2] #+t+1
        du[2] = -u[1] - u[2]  #+1#+10-t*t+t +cos(t)
    
    end
    tspan = (0.0,5)
    u0 = [1.0,0.0]
    prob = ODEProblem(funcName,u0,tspan)
    sol = solve(prob,abstol = 1e-6, reltol = 1e-3)
   # display(sol)
    display(plot!(sol,line=(:dot, 4)))
    println("press enter to exit")
    readline()
end





 odeDiffEquPackage()
