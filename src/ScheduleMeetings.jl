module ScheduleMeetings

using Dates
using RDates
using HolidayCalendars
using Combinatorics
using DataFrames

export Target, TargetEltype, schedule_meetings, complete_list

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
    return 10*(target.date - date)
end

function objective(assigned, targets, alldates)
    obj = Day(0)
    for ((person, target), ideal) in zip(targets, alldates)
        date = assigned[person]
        # Try to hit target
        obj += penalty(date, target)
        # Penalize reordering
        obj += abs(date - ideal)
    end
    return obj
end

function penalize_proximity(assignedlm, assignedjc, people; minsep=Day(7))
    obj = Day(0)
    for person in people
        datelm, datejc = get(assignedlm, person, nothing), get(assignedjc, person, nothing)
        (datelm === nothing || datejc === nothing) && continue
        Δdate = abs(datelm - datejc)
        if Δdate < minsep
            obj += 10*(minsep - Δdate)
        end
    end
    return obj
end

function objective_lm_jc(assignedlm, assignedjc, targetslm, targetsjc, allpeople, dateslm, datesjc; kwargs...)
    ret = objective(assignedlm, targetslm, dateslm) + objective(assignedjc, targetsjc, datesjc) + penalize_proximity(assignedlm, assignedjc, allpeople; kwargs...)
    return ret.value
end

function filldates(start, n, calendars, avoid; gap=Day(7))
    dates = Date[]
    for _ in 1:n
        while any(cal -> is_holiday(cal, start), calendars) || any(rng -> start == rng || (isa(rng, AbstractRange) && start ∈ rng), avoid)
            start += gap
        end
        push!(dates, start)
        start += gap
    end
    return dates
end

function available(targets, dates)
    people, taken = String[], Date[]
    for (person, target) in targets
        if target === nothing
            push!(people, person)
        else
            push!(taken, target.date)
        end
    end
    return people, setdiff(dates, taken)
end

function schedule_meetings(targetslm::typeof(default_target),
                           targetsjc::typeof(default_target),
                           startlm,
                           startjc;
                           calendars=ScheduleMeetings.calendars,
                           avoidlm=nothing,
                           avoidjc=nothing,
                           avoid=nothing,
                           kwargs...)
    if avoid !== nothing
        @assert avoidlm === nothing && avoidjc === nothing
        avoidlm = avoidjc = avoid
    end
    nlm, njc = length(targetslm), length(targetsjc)
    dateslm = filldates(startlm, nlm, calendars, avoidlm)
    datesjc = filldates(startjc, njc, calendars, avoidjc)
    flexlm, availlm = available(targetslm, dateslm)
    flexjc, availjc = available(targetsjc, datesjc)
    allpeople = Set{String}()
    for itr in (targetslm, targetsjc)
        for (person, _) in itr
            push!(allpeople, person)
        end
    end

    to_dict(pairs) = Dict{String,Date}(person => target.date for (person, target) in pairs if target !== nothing)
    to_df(pairs) = DataFrame("Presenter" => first.(pairs), "Date" => last.(pairs))

    tmplm, bestlm = to_dict(targetslm), to_dict(targetslm)
    tmpjc, bestjc = to_dict(targetsjc), to_dict(targetsjc)
    bestobj = typemax(Int)
    for plm in permutations(availlm), pjc in permutations(availjc)
        for (person, datelm) in zip(flexlm, plm)
            tmplm[person] = datelm
        end
        for (person, datejc) in zip(flexjc, pjc)
            tmpjc[person] = datejc
        end
        val = objective_lm_jc(tmplm, tmpjc, targetslm, targetsjc, allpeople, dateslm, datesjc; kwargs...)
        if val < bestobj
            bestobj = val
            copyto!(bestlm, tmplm)
            copyto!(bestjc, tmpjc)
        end
    end

    return to_df(sort!(collect(bestlm); by=last)), to_df(sort!(collect(bestjc); by=last))
end

complete_list(targeted::AbstractDict, all) = TargetEltype[k => get(targeted, k, nothing) for k in all]
complete_list(targeted, all) = complete_list(Dict(k => v for (k, v) in targeted), all)

# private copyto!
function copyto!(dest, src)
    for (k, v) in src
        dest[k] = v
    end
    return dest
end

function __init__()
    push!(calendars, calendar(CALENDARS, "US/SETTLEMENT"))
    return nothing
end

end
