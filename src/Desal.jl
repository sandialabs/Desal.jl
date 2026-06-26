"""
Desal

Lightweight reverse-osmosis desalination toolkit with static and dynamic simulation modes.
"""
module Desal

include("types.jl")
include("desalination.jl")

export DesignStruct, OperationStruct
export StaticOutputs, DynamicOutputs
export Desalinate

end
