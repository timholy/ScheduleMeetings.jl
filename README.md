# ScheduleMeetings

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://timholy.github.io/ScheduleMeetings.jl/dev/)
[![Build Status](https://github.com/timholy/ScheduleMeetings.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/timholy/ScheduleMeetings.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/timholy/ScheduleMeetings.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/timholy/ScheduleMeetings.jl)

Schedule weekly meetings for lists of presenters. The package is currently set up for two weekly meetings, internally called "lab meeting" and "journal club." It attempts to schedule with the following goals:

- schedule each presenter once for each slated list (the lists of presenters in the two meetings do not have to be identical)
- allow individuals to have target dates; for example, if a person is presenting in an external meeting on a particular, you might want to schedule a practice talk before (but not too far before) their official talk
- avoid holidays and travel
- try to avoid having the same person presenting in both meetings within the same 7-day period
- try to preserve the order of presentation as passed in by the targets

It defines an objective function and uses evolutionary optimization where the mutation operation is to make swaps.

Demo:

```julia
using Dates, ScheduleMeetings
# Pick the starting dates for the two meetings. They occur weekly.
startlm, startjc = Date(2023, 3, 21), Date(2023, 3, 24)
# "A", "B", and "C" have to present in lab meeting; "A", "C", and "D" must present in journal club
# "B" has an external talk on 2023-04-11, so try schedule a practice before that.
targetslm = TargetEltype["A" => nothing, "B" => Target(Date(2023, 4, 11)), "C" => nothing]
targetsjc = TargetEltype["A" => nothing, "C" => nothing, "D" => nothing]
# avoid some travel
avoid = [Date(2023, 3, 26):Day(1):Date(2023, 3, 31)]
# find a solution (not guaranteed to be globally optimal)
presentlm, presentjc = schedule_meetings(targetslm, targetsjc, startlm, startjc; avoid)
```
