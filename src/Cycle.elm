module Cycle exposing (Cycle, has, item, last, list, next, remove, shrink, shuffle)

import RB
import Random exposing (Generator)
import Random.List
import Sort exposing (Sorter)
import Sort.Dict as Dict exposing (Dict)


type Cycle a
    = Cycle (Sorter a) a (RB.Set a)


list : Sorter a -> a -> List a -> Cycle a
list sorter first rest =
    let
        set =
            RB.fromList sorter (first :: rest)

        minVal =
            Maybe.withDefault first (RB.start set)
    in
    Cycle sorter minVal set


rbToList : RB.Set k -> List k
rbToList set =
    RB.foldr (::) [] set


withIncreasingValues : Sorter a -> List a -> Dict a Int
withIncreasingValues sorter keys =
    keys
        |> List.foldl (\k ( i, d ) -> ( i + 1, Dict.insert k i d )) ( 0, Dict.empty sorter )
        |> Tuple.second


shuffle : Cycle a -> Generator (Cycle a)
shuffle (Cycle sorter selected set) =
    let
        indexSort imap =
            Sort.by (\k -> Maybe.withDefault 0 (Dict.get k imap)) Sort.increasing
    in
    rbToList set
        |> Random.List.shuffle
        |> Random.map
            (\keys ->
                let
                    sorter2 =
                        indexSort <| withIncreasingValues sorter keys

                    set2 =
                        RB.fromList sorter2 keys
                in
                case RB.middle set2 of
                    Just selected2 ->
                        Cycle sorter2 selected2 set2

                    Nothing ->
                        Cycle sorter selected set
            )


next : Cycle a -> Cycle a
next (Cycle sorter selected set) =
    case RB.next sorter selected set of
        Just val ->
            Cycle sorter val set

        Nothing ->
            case RB.start set of
                Just val ->
                    Cycle sorter val set

                Nothing ->
                    Cycle sorter selected set


last : Cycle a -> Cycle a
last (Cycle sorter selected set) =
    case RB.last sorter selected set of
        Just val ->
            Cycle sorter val set

        Nothing ->
            case RB.end set of
                Just val ->
                    Cycle sorter val set

                Nothing ->
                    Cycle sorter selected set


has : a -> Cycle a -> Bool
has val (Cycle sorter _ set) =
    RB.member sorter val set


shrink : Cycle a -> Maybe (Cycle a)
shrink (Cycle sorter selected set) =
    case RB.next sorter selected set of
        Just val ->
            Just <| Cycle sorter val <| RB.remove sorter selected set

        Nothing ->
            let
                shrunk =
                    RB.remove sorter selected set
            in
            Maybe.map (\val -> Cycle sorter val shrunk) <| RB.start shrunk


remove : a -> Cycle a -> Cycle a
remove val (Cycle sorter selected set) =
    if val /= selected then
        Cycle sorter selected <| RB.remove sorter val set

    else
        Cycle sorter selected set


item : Cycle a -> a
item (Cycle _ selected _) =
    selected
