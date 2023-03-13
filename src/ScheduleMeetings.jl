module ScheduleMeetings

using Dates
using RDates
using HolidayCalendars
using Evolutionary

export Target, TargetEltype, schedule_meetings

struct Target
    date::Date
    prior::Bool    # must the chosen date be prior to the target date?
end
Target(date::Date) = Target(date, true)

const calendars = CachedCalendar[]
const TargetEltype = Pair{String,Union{Target,Nothing}}
const default_target = TargetEltype[]
const DateRange = typeof(today():Day(1):today()+Day(5))

penalty(_, ::Nothing) = Day(0)
function penalty(date, target::Target)
    target.prior && date >= target.date && return Day(10^5)  # something big but won't overflow
    return target.date - date
end

function objective(dates, targets)
    obj = Day(0)
    prev = typemin(Date)
    for (person, target) in targets
        date = dates[person]
        # Try to hit target
        obj += penalty(date, target)
        # Penalize reordering
        if date < prev
            obj += prev - date
        end
        prev = date
    end
    return obj
end

function penalize_proximity(dateslm, datesjc, people; minsep=Day(7))
    obj = Day(0)
    for person in people
        datelm, datejc = get(dateslm, person, nothing), get(datesjc, person, nothing)
        (datelm === nothing || datejc === nothing) && continue
        Δdate = abs(datelm - datejc)
        if Δdate < minsep
            obj += minsep - Δdate
        end
    end
    return obj
end

function objective_lm_jc(dateslm, datesjc, targetslm, targetsjc; kwargs...)
    allpeople = Set{String}()
    for itr in (targetslm, targetsjc)
        for (person, _) in itr
            push!(allpeople, person)
        end
    end
    ret = objective(dateslm, targetslm) + objective(datesjc, targetsjc) + penalize_proximity(dateslm, datesjc, allpeople; kwargs...)
    return ret.value
end

function filldates(start, n, calendars, avoid; gap=Day(7))
    dates = Date[]
    for _ in 1:n
        while any(cal -> is_holiday(cal, start), calendars) || any(rng -> start ∈ rng, avoid)
            start += gap
        end
        push!(dates, start)
        start += gap
    end
    return dates
end

function schedule_meetings(targetslm::typeof(default_target),
                           targetsjc::typeof(default_target),
                           startlm,
                           startjc;
                           calendars=ScheduleMeetings.calendars,
                           avoid=DateRange[],
                           kwargs...)
    nlm, njc = length(targetslm), length(targetsjc)
    dateslm = filldates(startlm, nlm, calendars, avoid)
    datesjc = filldates(startjc, njc, calendars, avoid)

    builddict(dates, p, targets) = Dict(person => dates[i] for ((person, _), i) in zip(targets, p))
    buildlist(dates, p, targets) = [person => dates[i] for ((person, _), i) in zip(targets, p)]

    f(perm) = objective_lm_jc(builddict(dateslm, view(perm, 1:nlm), targetslm),
                              builddict(datesjc, view(perm, nlm+1:nlm+njc), targetsjc),
                              targetslm, targetsjc; kwargs...)
    function swap2blocks(perm; rng=nothing)
        if rand() < 0.5
            swap2(view(perm, 1:nlm))
        else
            swap2(view(perm, nlm+1:nlm+njc))
        end
        return perm
    end
    perm0 = [1:nlm; 1:njc]
    result = Evolutionary.optimize(f, perm0, GA(mutation=swap2blocks), Evolutionary.Options(iterations=10^3, show_trace=true))
    @show Evolutionary.minimum(result) f(perm0)
    @show Evolutionary.minimizer(result) perm0
    perm = f(perm0) < Evolutionary.minimum(result) ? perm0 : Evolutionary.minimizer(result)
    return buildlist(dateslm, perm[1:nlm], targetslm), buildlist(datesjc, perm[nlm+1:nlm+njc], targetsjc)
end


function __init__()
    push!(calendars, calendar(CALENDARS, "US/SETTLEMENT"))
    return nothing
end

end
