
using StaticArrays
using BenchmarkTools



#TP2: compare stack-fetch vs heap-fetch via vectors and svectors
function simulatorSvector()
  s=0.0
  v1 =  @SVector[1.1,2.2,3.3,4.4,5.5]
  for i = 1:1e+3
    for j = 1:5
        s=s+v1[j]
     end
  end
  s
end
function simulatorMvector()
  s=0.0
  v1 =  @MVector[1.1,2.2,3.3,4.4,5.5]
  for i = 1:1e+3
    for j = 1:5
        s=s+v1[j]
     end
  end
  s   
end
function simulatorvector()
  s=0.0
  v1 = [1.1,2.2,3.3,4.4,5.5]
  for i = 1:1e+3
    for j = 1:5
        s=s+v1[j]
     end
  end
  s
end
@btime simulatorSvector()
@btime simulatorvector()
@btime simulatorMvector()

#display(simulatorMvector(2))
#display(simulatorvector(2))

