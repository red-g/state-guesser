module Holder exposing (Holder, clear, empty, has, item, push, size)

import Sort exposing (Sorter)
import Sort.Set as Set exposing (Set)


type Holder a
    = Holder (Maybe a) (Set a)


item : Holder a -> Maybe a
item (Holder i _) =
    i


clear : Holder a -> Holder a
clear (Holder i s) =
    Holder Nothing <|
        case i of
            Just p ->
                Set.insert p s

            Nothing ->
                s


has : a -> Holder a -> Bool
has val (Holder i s) =
    i == Just val || Set.memberOf s val


push : a -> Holder a -> Holder a
push val (Holder i s) =
    Holder (Just val) <|
        case i of
            Just p ->
                Set.insert p s

            Nothing ->
                s


empty : Sorter a -> Holder a
empty sorter =
    Holder Nothing (Set.empty sorter)


size : Holder a -> Int
size (Holder i s) =
    case i of
        Just _ ->
            1 + Set.size s

        Nothing ->
            Set.size s
