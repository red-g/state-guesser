module Structures exposing (..)

import Expect exposing (equal)
import Fuzz exposing (int, intRange)
import RB
import Set exposing (Set)
import Sort
import Test exposing (..)


range : { list : List Int, set : Set Int, rb : RB.Set Int }
range =
    let
        l =
            List.range 1 50
    in
    { list = l, set = Set.fromList l, rb = RB.fromList Sort.increasing l }


suite : Test
suite =
    describe "Custom data structure manipulation"
        [ fuzz (intRange 0 51) "Get next element" <|
            \i ->
                RB.next Sort.increasing i range.rb
                    |> equal
                        (if Set.member i range.set && Set.member (i + 1) range.set then
                            Just (i + 1)

                         else
                            Nothing
                        )
        , fuzz (intRange 0 51) "Get last element" <|
            \i ->
                RB.last Sort.increasing i range.rb
                    |> equal
                        (if Set.member i range.set && Set.member (i - 1) range.set then
                            Just (i - 1)

                         else
                            Nothing
                        )
        , fuzz int "Check for membership" <|
            \i ->
                RB.member Sort.increasing i range.rb
                    |> equal (Set.member i range.set)
        , fuzz (intRange 0 51) "Remove item" <|
            \i ->
                RB.remove Sort.increasing i range.rb
                    |> rbToList
                    |> equal (Set.toList <| Set.remove i range.set)
        ]


rbToList : RB.Set k -> List k
rbToList rb =
    RB.foldr (::) [] rb
