using TaylorSeries
#use_show_default(true)
q1=Taylor1([1.1,1.0],4)
println(q1)
#= v1=Taylor1([2.0, 0.0,0.0])
println(q1(v1))
v11=Taylor1([0.0, 2.0,1.0])
println(q1(v11))
v111=Taylor1([2.0, 2.0])
println(q1(v111)) =#
v1111=Taylor1([2.0, 1.0])
println(q1(v1111))
println(q1)
#= q1=Taylor1([2.0,1.3,1.0],4)
v1=Taylor1([1.1, 0.0])
println(q1(v1))
q1=Taylor1([2.0,1.3,1.0],4)
v1=Taylor1([1.1, 0.0])
println(q1(v1))
 =#