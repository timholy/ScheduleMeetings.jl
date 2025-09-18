using ScheduleMeetings
using Dates
using Test

@testset "ScheduleMeetings.jl" begin
    startlm, startjc = Date(2023, 3, 21), Date(2023, 3, 24)
    people = ["A", "B", "C"]
    for (targetslm, targetsjc) in [
        (TargetEltype["A" => nothing, "B" => Target(Date(2023, 4, 11)), "C" => nothing],
         TargetEltype["A" => nothing, "C" => nothing, "D" => nothing]),
        (TargetEltype["B" => Target(Date(2023, 4, 11))],
        TargetEltype["A" => nothing, "C" => nothing, "D" => nothing])
    ]
        targetslm = sort!(complete_list(targetslm, people); by=first)
        avoid = [Date(2023, 3, 26):Day(1):Date(2023, 3, 31)]
        slm, sjc = schedule_meetings(targetslm, targetsjc, startlm, startjc; avoid)
        @test slm[1, :Presenter] == "A" && slm[1, :Date] == Date(2023, 3, 21)
        @test slm[2, :Presenter] == "C" && slm[2, :Date] == Date(2023, 4, 4)
        @test slm[3, :Presenter] == "B" && slm[3, :Date] == Date(2023, 4, 11)
        @test sjc[1, :Presenter] == "C" && sjc[1, :Date] == Date(2023, 3, 24)
        @test sjc[2, :Presenter] == "A" && sjc[2, :Date] == Date(2023, 4, 7)
        @test sjc[3, :Presenter] == "D" && sjc[3, :Date] == Date(2023, 4, 14)

        slm, sjc = schedule_meetings(targetslm, targetsjc, startlm, startjc; avoid, gap=Day(14))
        @test all(==(Day(14)), diff(sjc.Date))
        slm, sjc = schedule_meetings(targetslm, targetsjc, startlm, startjc; avoid, avoidlm=[Date(2023, 4, 4)])
        @test slm[2, :Date] == Date(2023, 4, 11)
    end
end
