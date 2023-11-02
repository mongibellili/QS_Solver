
function nmLiQSS_integrate(CommonqssData::CommonQSS_data{O,0},liqssdata::LiQSS_data{O,false},specialLiqssData::SpecialLiqssQSS_data, odep::NLODEProblem{PRTYPE,T,0,0,CS},f::Function,jac::Function,SD::Function,exacteA::Function) where {PRTYPE,CS,O,T}
  cacheA=specialLiqssData.cacheA
  #direction=specialLiqssData.direction
  #qminus= specialLiqssData.qminus
  #buddySimul=specialLiqssData.buddySimul
  ft = CommonqssData.finalTime;initTime = CommonqssData.initialTime;relQ = CommonqssData.dQrel;absQ = CommonqssData.dQmin;maxErr=CommonqssData.maxErr;
  
  #savetimeincrement=CommonqssData.savetimeincrement;savetime = savetimeincrement
  quantum = CommonqssData.quantum;nextStateTime = CommonqssData.nextStateTime;nextEventTime = CommonqssData.nextEventTime;  nextInputTime = CommonqssData.nextInputTime
  tx = CommonqssData.tx;tq = CommonqssData.tq;x = CommonqssData.x;q = CommonqssData.q;t=CommonqssData.t
  savedVars=CommonqssData.savedVars;
  savedTimes=CommonqssData.savedTimes;integratorCache=CommonqssData.integratorCache;taylorOpsCache=CommonqssData.taylorOpsCache;#cacheSize=odep.cacheSize
 
  #prevStepVal = specialLiqssData.prevStepVal
  #a=deepcopy(odep.initJac);
  #a=liqssdata.a
  #u=liqssdata.u;#tu=liqssdata.tu
  #***************************************************************  
  qaux=liqssdata.qaux;dxaux=liqssdata.dxaux#= olddx=liqssdata.olddx; ; olddxSpec=liqssdata.olddxSpec =#

  
  pp=pointer(Vector{NTuple{2,Float64}}(undef, 7))
 # savedVarsQ = Vector{Vector{Float64}}(undef, T)  

                            
  respp = pointer(Vector{Float64}(undef, 2))
  trackSimul = Vector{Int}(undef, 1)
 # cacheRatio=zeros(5);cacheQ=zeros(5)
  cacherealPosi=Vector{Vector{Float64}}(undef,3);cacherealPosj=Vector{Vector{Float64}}(undef,3);
 #=  for i=1:T
    savedVarsQ[i]=Vector{Float64}()     
  end =#
for i =1:3
  cacherealPosi[i]=zeros(2)
  cacherealPosj[i]=zeros(2)
end
  exacteA(q,cacheA,1,1)  # this 'unnecessary call' 'compiles' the function and it helps remove allocations when used after !!!
  @show exacteA
  numSteps = Vector{Int}(undef, T)
 #@show f
   #######################################compute initial values##################################################
  n=1
  for k = 1:O # compute initial derivatives for x and q (similar to a recursive way )
    n=n*k
      for i = 1:T
        q[i].coeffs[k] = x[i].coeffs[k]  # q computed from x and it is going to be used in the next x
      end
      for i = 1:T
         clearCache(taylorOpsCache,Val(CS),Val(O));f(i,q,t ,taylorOpsCache)
        ndifferentiate!(integratorCache,taylorOpsCache[1] , k - 1)
        x[i].coeffs[k+1] = (integratorCache.coeffs[1]) / n # /fact cuz i will store der/fac like the convention...to extract the derivatives (at endof sim) multiply by fac  derderx=coef[3]*fac(2)
      end
  end

 
   for i = 1:T
    numSteps[i]=0
    #= @timeit "savevars" =# push!(savedVars[i],x[i][0])
    #push!(savedVarsQ[i],q[i][0])
     push!(savedTimes[i],0.0)
     quantum[i] = relQ * abs(x[i].coeffs[1]) ;quantum[i]=quantum[i] < absQ ? absQ : quantum[i];quantum[i]=quantum[i] > maxErr ? maxErr : quantum[i] 
    updateQ(Val(O),i,x,q,quantum,exacteA,cacheA,dxaux,qaux,tx,tq,initTime,ft,nextStateTime) 
  end
 # for i = 1:T
    # clearCache(taylorOpsCache,Val(CS),Val(O));f(i,q,t,taylorOpsCache);
   #  computeDerivative(Val(O), x[i], taylorOpsCache[1])#0.0 used to be elapsed...even down below not neeeded anymore
    #Liqss_reComputeNextTime(Val(O), i, initTime, nextStateTime, x, q, quantum)
  #  t[0]=0.1;clearCache(taylorOpsCache,Val(CS),Val(O));f(i,q,t,taylorOpsCache);# to detect if rhs contains time components
    #@show taylorOpsCache
    #computeNextInputTime(Val(O), i, initTime, 0.1,taylorOpsCache[1] , nextInputTime, x,  quantum)#not complete, currently elapsed=0.1 is temp until fixed
   #prevStepVal[i]=x[i][0]#assignXPrevStepVals(Val(O),prevStepVal,x,i)
 # end

  @show x

  ###################################################################################################################################################################
  ####################################################################################################################################################################
  #---------------------------------------------------------------------------------while loop-------------------------------------------------------------------------
  ###################################################################################################################################################################
  #################################################################################################################################################################### 
  simt = initTime ;simulStepCount=0;totalSteps=0;inputSteps=0

  #simul=false


  while simt > ft && totalSteps < 30000000
    sch = updateScheduler(Val(T),nextStateTime,nextEventTime, nextInputTime)
    simt = sch[2];index = sch[1]
    if simt>ft
      break # simt=120 for simulation of ft=100 terminates while it adds some steps for ft=500, because dx is really small but not zero.
    end
    numSteps[index]+=1;totalSteps+=1

   
    t[0]=simt
    ##########################################state########################################
    if sch[3] == :ST_STATE
        xitemp=x[index][0]
        elapsed = simt - tx[index];integrateState(Val(O),x[index],elapsed);tx[index] = simt 
        quantum[index] = relQ * abs(x[index].coeffs[1]) ;quantum[index]=quantum[index] < absQ ? absQ : quantum[index];quantum[index]=quantum[index] > maxErr ? maxErr : quantum[index] 
        #dirI=x[index][0]-savedVars[index][end]  
        dirI=x[index][0]-xitemp
        for b in (jac(index)  )    # update Qb : to be used to calculate exacte Aindexb...move below updateQ
          elapsedq = simt - tq[b] ;
          if elapsedq>0 integrateState(Val(O-1),q[b],elapsedq);tq[b]=simt end
        end
        firstguess=updateQ(Val(O),index,x,q,quantum,exacteA,cacheA,dxaux,qaux,tx,tq,simt,ft,nextStateTime) ;tq[index] = simt   
        #----------------------------------------------------check dependecy cycles---------------------------------------------   
        trackSimul[1]=0 
        #= for i =1:5
          cacheRatio[i]=0.0; cacheQ[i]=0.0; 
        end       =#       
        for j in SD(index)
          for b in (jac(j)  )    # update Qb: to be used to calculate exacte Ajb
            elapsedq = simt - tq[b] ;
            if elapsedq>0  integrateState(Val(O-1),q[b],elapsedq); tq[b]=simt  end
          end
          cacheA[1]=0.0;exacteA(q,cacheA,index,j);aij=cacheA[1]# can be passed to simul so that i dont call exactfunc again
          cacheA[1]=0.0;exacteA(q,cacheA,j,index);aji=cacheA[1]
         
        
        
          if j!=index && aij*aji!=0.0
            @show aij,aji
              #prvStepValj= savedVars[j][end]#getPrevStepVal(prevStepVal,j) 
              for i =1:3
                cacherealPosi[i][1]=0.0; cacherealPosi[i][2]=0.0
                cacherealPosj[i][1]=0.0; cacherealPosj[i][2]=0.0
              end 
              if nmisCycle_and_simulUpdate(cacherealPosi,cacherealPosj,aij,aji,respp,pp,trackSimul,Val(O),index,j,dirI,firstguess,x,q,quantum,exacteA,cacheA,dxaux,qaux,tx,tq,simt,ft)
                simulStepCount+=1
               clearCache(taylorOpsCache,Val(CS),Val(O));f(index,q,t,taylorOpsCache);computeDerivative(Val(O), x[index], taylorOpsCache[1])
              #  clearCache(taylorOpsCache,Val(CS),Val(O));f(j,q,t,taylorOpsCache);computeDerivative(Val(O), x[j], taylorOpsCache[1])
              # Liqss_reComputeNextTime(Val(O), index, simt, nextStateTime, x, q, quantum)
              #  Liqss_reComputeNextTime(Val(O), j, simt, nextStateTime, x, q, quantum)
   
                for k in SD(j)  #j influences k
                    if k!=index && k!=j
                        elapsedx = simt - tx[k]; x[k].coeffs[1] = x[k](elapsedx);tx[k] = simt
                        elapsedq = simt - tq[k]; if elapsedq > 0  ;integrateState(Val(O-1),q[k],elapsedq); tq[k] = simt end
                        for b in (jac(k)  )   
                          elapsedq = simt - tq[b]
                          if elapsedq>0 integrateState(Val(O-1),q[b],elapsedq);tq[b]=simt end
                        end  
                        clearCache(taylorOpsCache,Val(CS),Val(O));f(k,q,t,taylorOpsCache);computeDerivative(Val(O), x[k], taylorOpsCache[1])
                        Liqss_reComputeNextTime(Val(O), k, simt, nextStateTime, x, q, quantum)
                    end#end if k!=0
                end#end for k depend on j          
              end#end ifcycle check
          # end #end if allow one simulupdate
          end#end if j!=0
        end#end FOR_cycle check
            

      if trackSimul[1]!=0  #qi changed after throw
       # clearCache(taylorOpsCache,Val(CS),Val(O));f(index,q,t,taylorOpsCache);computeDerivative(Val(O), x[index], taylorOpsCache[1])
        Liqss_reComputeNextTime(Val(O), index, simt, nextStateTime, x, q, quantum)
      end

      #-------------------------------------------------------------------------------------
      #---------------------------------normal liqss: proceed--------------------------------
      #-------------------------------------------------------------------------------------

        for c in SD(index)   #index influences c       
          elapsedx = simt - tx[c] ;
          if elapsedx>0 
            x[c].coeffs[1] = x[c](elapsedx);
            tx[c] = simt

           end # 
          elapsedq = simt - tq[c];if elapsedq > 0 ;integrateState(Val(O-1),q[c],elapsedq);tq[c] = simt    end   # c never been visited 
          #= for b in (jac(c)  )    # update other influences
              elapsedq = simt - tq[b] ;if elapsedq>0 integrateState(Val(O-1),q[b],elapsedq);tq[b]=simt  end
          end  =#
          clearCache(taylorOpsCache,Val(CS),Val(O)); f(c,q,t,taylorOpsCache);computeDerivative(Val(O), x[c], taylorOpsCache[1])
          Liqss_reComputeNextTime(Val(O), c, simt, nextStateTime, x, q, quantum)
        end#end for SD
      #=  if 8.377869511741662<=simt<=14.578335986845602 && (index==2 #= || index==5 =#) 
          println("intgrator at simt=$simt index=$index")
         
          @show x[index],nextStateTime[index]
          
         end =#
  
      ##################################input########################################
    elseif sch[3] == :ST_INPUT  # time of change has come to a state var that does not depend on anything...no one will give you a chance to change but yourself    
   #=  println("nmliqss intgrator under input, index= $index, totalsteps= $totalSteps")
    inputSteps+=1
   
      elapsed = simt - tx[index];integrateState(Val(O),x[index],elapsed);tx[index] = simt 
      
      quantum[index] = relQ * abs(x[index].coeffs[1]) ;quantum[index]=quantum[index] < absQ ? absQ : quantum[index];quantum[index]=quantum[index] > maxErr ? maxErr : quantum[index]   
      #for k = 1:O q[index].coeffs[k] = x[index].coeffs[k] end; tq[index] = simt 
        notneeded=updateQ(Val(O),index,x,q,quantum,exacteA,cacheA,dxaux,qaux,tx,tq,simt,ft,nextStateTime) ;tq[index] = simt 
        for b in jac(index) 
          elapsedq = simt - tq[b];if elapsedq>0 integrateState(Val(O-1),q[b],elapsedq);tq[b]=simt end
        end
       clearCache(taylorOpsCache,Val(CS),Val(O));f(index,q,t,taylorOpsCache)
       computeDerivative(Val(O), x[index], taylorOpsCache[1]#= ,integratorCache,elapsed =#)
       reComputeNextTime(Val(O), index, simt, nextStateTime, x, q, quantum)
      
      
      t[0]=simt+0.1; clearCache(taylorOpsCache,Val(CS),Val(O));f(index,q,t,taylorOpsCache);# to detect if rhs contains time components
      computeNextInputTime(Val(O), index, simt, 0.1,taylorOpsCache[1] , nextInputTime, x,  quantum)
      for j in (SD(index))    
          elapsedx = simt - tx[j];
          if elapsedx > 0 
            x[j].coeffs[1] = x[j](elapsedx);tx[j] = simt 
            quantum[j] = relQ * abs(x[j].coeffs[1]) ;quantum[j]=quantum[j] < absQ ? absQ : quantum[j];quantum[j]=quantum[j] > maxErr ? maxErr : quantum[j]   
          end
          elapsedq = simt - tq[j];if elapsedq > 0 integrateState(Val(O-1),q[j],elapsedq);tq[j] = simt  end#q needs to be updated here for recomputeNext                 
          for b in jac(j)  
              elapsedq = simt - tq[b];if elapsedq>0 integrateState(Val(O-1),q[b],elapsedq);tq[b]=simt end
           
          end
           clearCache(taylorOpsCache,Val(CS),Val(O));f(j,q,t,taylorOpsCache);computeDerivative(Val(O), x[j], taylorOpsCache[1]#= ,integratorCache,elapsed =#)
          reComputeNextTime(Val(O), j, simt, nextStateTime, x, q, quantum)
      end#end for =#
     #=  for i = 1:length(SZ[index])
        j = SZ[index][i] 
        if j != 0   
          for b = 1:T # elapsed update all other vars that this derj depends upon.
            if zc_SimpleJac[j][b] != 0     
              elapsedx = simt - tx[b];if elapsedx>0 integrateState(Val(O),x[b],integratorCache,elapsedx);tx[b]=simt end
             # elapsedq = simt - tq[b];if elapsedq>0 integrateState(Val(O-1),q[b],elapsedq);tq[b]=simt end
            end
          end              
         #=   clearCache(taylorOpsCache,Val(CS),Val(O))#normally and later i should update x,q (integrate q=q+e derQ  for higher orders)
          computeNextEventTime(j,zcf[j](x,d,t,taylorOpsCache),oldsignValue,simt,  nextEventTime, quantum)#,maxIterer)  =#
           clearCache(taylorOpsCache,Val(CS),Val(O));f(-1,j,-1,x,d,t,taylorOpsCache)        
                   computeNextEventTime(j,taylorOpsCache[1],oldsignValue,simt,  nextEventTime, quantum)
        end  
      end =#
    #################################################################event########################################
    end#end state/input/event
 
      #  push!(savedVars[index],x[index][0])
        push!(savedVars[index],(x[index][0]+q[index][0])/2)
        push!(savedTimes[index],simt)
       # push!(savedVarsQ[index],q[index][0])
      
       #=  for i=1:T
          push!(savedVars[i],x[i][0])
          push!(savedTimes[i],simt)
        #  push!(savedVarsQ[i],q[i][0])
        end =#
#=   if index==1 && 0.042<simt<0.043
    @show x
    @show q

  end =#
  end#end while
@show inputSteps
  #@show cacheQ
#@show trackSimul
 #= @timeit "createSol" =# 
 #createSol(Val(T),Val(O),savedTimes,savedVars, "nmliqss$O",string(odep.prname),absQ,simulStepCount,numSteps,ft)
 #createSol(Val(T),Val(O),savedTimes,savedVars, "nmliqss$O",string(odep.prname),absQ,totalSteps,simulStepCount,numSteps,ft)
 createSol(Val(T),Val(O),savedTimes,savedVars, "nmliqss$O",string(odep.prname),absQ,totalSteps,simulStepCount,numSteps,ft)
     # change this to function /constrcutor...remember it is bad to access structs (objects) directly
  
end

