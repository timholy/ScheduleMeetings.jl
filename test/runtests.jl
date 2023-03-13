using ScheduleMeetings
using Dates
using Test

@testset "ScheduleMeetings.jl" begin
    startlm, startjc = Date(2023, 3, 21), Date(2023, 3, 24)
    targetslm = TargetEltype["A" => nothing, "B" => Target(Date(2023, 4, 11)), "C" => nothing]
    targetsjc = TargetEltype["A" => nothing, "C" => nothing, "D" => nothing]
    avoid = [Date(2023, 3, 26):Day(1):Date(2023, 3, 31)]
    ret = schedule_meetings(targetslm, targetsjc, startlm, startjc; avoid)
end
