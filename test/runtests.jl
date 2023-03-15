using ScheduleMeetings
using Dates
using Test

@testset "ScheduleMeetings.jl" begin
    startlm, startjc = Date(2023, 3, 21), Date(2023, 3, 24)
    targetslm = TargetEltype["A" => nothing, "B" => Target(Date(2023, 4, 18)), "C" => nothing]
    targetsjc = TargetEltype["A" => nothing, "C" => nothing, "D" => nothing]
    avoid = [Date(2023, 3, 26):Day(1):Date(2023, 3, 31)]
    slm, sjc = schedule_meetings(targetslm, targetsjc, startlm, startjc; avoid)
    @test slm[1] == ("A" => Date(2023, 3, 21))
    @test slm[2] == ("B" => Date(2023, 4, 11))
    @test slm[3] == ("C" => Date(2023, 4, 4))
    @test sjc[1] == ("A" => Date(2023, 3, 24))
    @test sjc[2] == ("C" => Date(2023, 4, 7))
    @test sjc[3] == ("D" => Date(2023, 4, 14))
end
