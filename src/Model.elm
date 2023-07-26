module Model exposing (Game, Lock, Model(..), Scores, Second(..), Settings, allMisses, finalTime, guess, guessing, incrementTime, last, missed, missesSoFar, new, next, pause, remaining, restart, resume, start, timeSoFar, usedBorder, usingBorder, usingSkips)

import Cycle exposing (Cycle)
import Holder exposing (Holder)
import States exposing (State, Status(..))


type Second
    = Second Int


addSeconds : Second -> Second -> Second
addSeconds (Second one) (Second two) =
    Second <| one + two


type Model
    = Playing Game
    | Paused Lock
    | Done Scores
    | Creating Settings


type alias Settings =
    { border : Bool, skips : Bool }


start : Cycle State -> Settings -> Game
start states settings =
    Game settings { remaining = states, time = Second 0, missed = Holder.empty States.sorter }


type Game
    = Game Settings { remaining : Cycle State, time : Second, missed : Holder State }


incrementTime : Game -> Game
incrementTime (Game settings game) =
    Game settings { game | time = addSeconds game.time (Second 1) }


selected : Game -> State
selected (Game _ game) =
    Cycle.item game.remaining


guess : State -> Game -> Model
guess state game =
    if state == selected game then
        advance game

    else if notGuessedYet state game then
        Playing <| miss state game

    else
        Playing game


notGuessedYet : State -> Game -> Bool
notGuessedYet state game =
    Cycle.has state (remaining game)


advance : Game -> Model
advance (Game settings game) =
    case Cycle.shrink game.remaining of
        Just rest ->
            Playing <| Game settings { game | remaining = rest, missed = Holder.clear game.missed }

        Nothing ->
            Done <| Scores settings { time = game.time, missed = Holder.clear game.missed }



-- we need targeted removal from a cycle; we need the state in question eliminated
-- this seems like more the job of a set, though it needs to loop; perhaps a set that stores an array of its keys


miss : State -> Game -> Game
miss state (Game settings game) =
    Game settings { game | missed = Holder.push state game.missed, remaining = Cycle.remove state game.remaining }


missesSoFar : Game -> Holder State
missesSoFar (Game _ game) =
    game.missed


restart : Game -> Settings
restart (Game settings _) =
    settings


type Lock
    = Lock Game


pause : Game -> Lock
pause game =
    Lock game


resume : Lock -> Game
resume (Lock game) =
    game


type Scores
    = Scores Settings { time : Second, missed : Holder State }


new : Scores -> Settings
new (Scores settings _) =
    settings


finalTime : Scores -> Second
finalTime (Scores _ scores) =
    scores.time


allMisses : Scores -> Holder State
allMisses (Scores _ scores) =
    scores.missed


timeSoFar : Game -> Second
timeSoFar (Game _ game) =
    game.time


usingBorder : Game -> Bool
usingBorder (Game settings _) =
    settings.border


usingSkips : Game -> Bool
usingSkips (Game settings _) =
    settings.skips


usedBorder : Scores -> Bool
usedBorder (Scores settings _) =
    settings.border


next : Game -> Game
next (Game settings game) =
    if settings.skips then
        Game settings { game | remaining = Cycle.next game.remaining }

    else
        Game settings game


last : Game -> Game
last (Game settings game) =
    if settings.skips then
        Game settings { game | remaining = Cycle.last game.remaining }

    else
        Game settings game


guessing : Game -> State
guessing (Game _ game) =
    Cycle.item game.remaining


remaining : Game -> Cycle State
remaining (Game _ game) =
    game.remaining


missed : Game -> Maybe State
missed (Game _ game) =
    Holder.item game.missed
