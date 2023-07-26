module RB exposing (Set, end, foldl, foldr, fromList, isEmpty, last, member, middle, next, remove, start)

import Sort exposing (Sorter)


type Color
    = Red
    | Black


type Set k
    = Node Color k (Set k) (Set k)
    | Leaf


middle : Set k -> Maybe k
middle set =
    case set of
        Node _ key _ _ ->
            Just key

        Leaf ->
            Nothing


empty : Set k
empty =
    Leaf


member : Sorter a -> a -> Set a -> Bool
member sorter key set =
    memberHelper (Sort.toOrder sorter key) set


memberHelper : (a -> Order) -> Set a -> Bool
memberHelper sorter set =
    case set of
        Leaf ->
            False

        Node _ key lt gt ->
            case sorter key of
                EQ ->
                    True

                LT ->
                    memberHelper sorter lt

                GT ->
                    memberHelper sorter gt


isEmpty : Set a -> Bool
isEmpty set =
    case set of
        Leaf ->
            True

        _ ->
            False


insert : Sorter a -> a -> Set a -> Set a
insert sorter key dict =
    -- Root node is always Black
    case insertHelp sorter key dict of
        Node Red k l r ->
            Node Black k l r

        x ->
            x


insertHelp : Sorter a -> a -> Set a -> Set a
insertHelp sorter key dict =
    case dict of
        Leaf ->
            -- New nodes are always red. If it violates the rules, it will be fixed
            -- when balancing.
            Node Red key Leaf Leaf

        Node nColor nKey nLeft nRight ->
            case Sort.toOrder sorter key nKey of
                LT ->
                    balance nColor nKey (insertHelp sorter key nLeft) nRight

                EQ ->
                    Node nColor nKey nLeft nRight

                GT ->
                    balance nColor nKey nLeft (insertHelp sorter key nRight)


balance : Color -> k -> Set k -> Set k -> Set k
balance color key left right =
    case right of
        Node Red rK rLeft rRight ->
            case left of
                Node Red lK lLeft lRight ->
                    Node
                        Red
                        key
                        (Node Black lK lLeft lRight)
                        (Node Black rK rLeft rRight)

                _ ->
                    Node color rK (Node Red key left rLeft) rRight

        _ ->
            case left of
                Node Red lK (Node Red llK llLeft llRight) lRight ->
                    Node
                        Red
                        lK
                        (Node Black llK llLeft llRight)
                        (Node Black key lRight right)

                _ ->
                    Node color key left right


{-| Remove a key from a set. If the key is not found,
no changes are made.
-}
remove : Sorter a -> a -> Set a -> Set a
remove sorter key dict =
    -- Root node is always Black
    case removeHelp (Sort.toOrder sorter key) dict of
        Node Red k l r ->
            Node Black k l r

        x ->
            x


{-| The easiest thing to remove from the tree, is a red node. However, when searching for the
node to remove, we have no way of knowing if it will be red or not. This remove implementation
makes sure that the bottom node is red by moving red colors down the tree through rotation
and color flips. Any violations this will cause, can easily be fixed by balancing on the way
up again.
-}
removeHelp : (a -> Order) -> Set a -> Set a
removeHelp sorter set =
    case set of
        Leaf ->
            Leaf

        Node color key left right ->
            if sorter key == LT then
                case left of
                    Node Black _ lLeft _ ->
                        case lLeft of
                            Node Red _ _ _ ->
                                Node color key (removeHelp sorter left) right

                            _ ->
                                case moveRedLeft set of
                                    Node nColor nKey nLeft nRight ->
                                        balance nColor nKey (removeHelp sorter nLeft) nRight

                                    Leaf ->
                                        Leaf

                    _ ->
                        Node color key (removeHelp sorter left) right

            else
                removeHelpEQGT sorter (removeHelpPrepEQGT set color key left right)


removeHelpPrepEQGT : Set a -> Color -> a -> Set a -> Set a -> Set a
removeHelpPrepEQGT set color key left right =
    case left of
        Node Red lK lLeft lRight ->
            Node
                color
                lK
                lLeft
                (Node Red key lRight right)

        _ ->
            case right of
                Node Black _ (Node Black _ _ _) _ ->
                    moveRedRight set

                Node Black _ Leaf _ ->
                    moveRedRight set

                _ ->
                    set


{-| When we find the node we are looking for, we can remove by replacing the key-value
pair with the key-value pair of the left-most node on the right side (the closest pair).
-}
removeHelpEQGT : (a -> Order) -> Set a -> Set a
removeHelpEQGT sorter set =
    case set of
        Node color key left right ->
            if sorter key == EQ then
                case getMin right of
                    Node _ minKey _ _ ->
                        balance color minKey left (removeMin right)

                    Leaf ->
                        Leaf

            else
                balance color key left (removeHelp sorter right)

        Leaf ->
            Leaf


getMin : Set k -> Set k
getMin set =
    case set of
        Node _ _ ((Node _ _ _ _) as left) _ ->
            getMin left

        _ ->
            set


removeMin : Set k -> Set k
removeMin set =
    case set of
        Node color key ((Node lColor _ lLeft _) as left) right ->
            case lColor of
                Black ->
                    case lLeft of
                        Node Red _ _ _ ->
                            Node color key (removeMin left) right

                        _ ->
                            case moveRedLeft set of
                                Node nColor nKey nLeft nRight ->
                                    balance nColor nKey (removeMin nLeft) nRight

                                Leaf ->
                                    Leaf

                _ ->
                    Node color key (removeMin left) right

        _ ->
            Leaf


moveRedLeft : Set k -> Set k
moveRedLeft set =
    case set of
        Node _ k (Node _ lK lLeft lRight) (Node _ rK (Node Red rlK rlL rlR) rRight) ->
            Node
                Red
                rlK
                (Node Black k (Node Red lK lLeft lRight) rlL)
                (Node Black rK rlR rRight)

        Node clr k (Node _ lK lLeft lRight) (Node _ rK rLeft rRight) ->
            case clr of
                Black ->
                    Node
                        Black
                        k
                        (Node Red lK lLeft lRight)
                        (Node Red rK rLeft rRight)

                Red ->
                    Node
                        Black
                        k
                        (Node Red lK lLeft lRight)
                        (Node Red rK rLeft rRight)

        _ ->
            set


moveRedRight : Set k -> Set k
moveRedRight set =
    case set of
        Node _ k (Node _ lK (Node Red llK llLeft llRight) lRight) (Node _ rK rLeft rRight) ->
            Node Red lK (Node Black llK llLeft llRight) (Node Black k lRight (Node Red rK rLeft rRight))

        Node clr k (Node _ lK lLeft lRight) (Node _ rK rLeft rRight) ->
            case clr of
                Black ->
                    Node Black k (Node Red lK lLeft lRight) (Node Red rK rLeft rRight)

                Red ->
                    Node Black k (Node Red lK lLeft lRight) (Node Red rK rLeft rRight)

        _ ->
            set


{-| Convert an association list into a set.
-}
fromList : Sorter a -> List a -> Set a
fromList sorter assocs =
    List.foldl (\key set -> insert sorter key set) empty assocs


next : Sorter a -> a -> Set a -> Maybe a
next sorter val set =
    case set of
        Node _ k lt gt ->
            nextHelper (Sort.toOrder sorter val) Nothing k lt gt

        Leaf ->
            Nothing


nextHelper : (a -> Order) -> Maybe a -> a -> Set a -> Set a -> Maybe a
nextHelper sorter fallback key lt gt =
    case sorter key of
        EQ ->
            mink fallback gt

        LT ->
            traverseNext sorter (Just key) lt

        GT ->
            traverseNext sorter fallback gt


traverseNext : (a -> Order) -> Maybe a -> Set a -> Maybe a
traverseNext sorter fallback set =
    case set of
        Node _ key lt gt ->
            nextHelper sorter fallback key lt gt

        Leaf ->
            Nothing


mink : Maybe a -> Set a -> Maybe a
mink key set =
    case set of
        Node _ k lt _ ->
            mink (Just k) lt

        Leaf ->
            key


last : Sorter a -> a -> Set a -> Maybe a
last sorter val set =
    case set of
        Node _ k lt gt ->
            lastHelper (Sort.toOrder sorter val) Nothing k lt gt

        Leaf ->
            Nothing


lastHelper : (a -> Order) -> Maybe a -> a -> Set a -> Set a -> Maybe a
lastHelper sorter fallback key lt gt =
    case sorter key of
        EQ ->
            maxk fallback lt

        LT ->
            traverseLast sorter fallback lt

        GT ->
            traverseLast sorter (Just key) gt


traverseLast : (a -> Order) -> Maybe a -> Set a -> Maybe a
traverseLast sorter fallback set =
    case set of
        Node _ key lt gt ->
            lastHelper sorter fallback key lt gt

        Leaf ->
            Nothing


maxk : Maybe a -> Set a -> Maybe a
maxk key set =
    case set of
        Node _ k _ gt ->
            maxk (Just k) gt

        Leaf ->
            key


foldr : (k -> b -> b) -> b -> Set k -> b
foldr func acc t =
    case t of
        Leaf ->
            acc

        Node _ key left right ->
            foldr func (func key (foldr func acc right)) left


foldl : (k -> b -> b) -> b -> Set k -> b
foldl func acc dict =
    case dict of
        Leaf ->
            acc

        Node _ key left right ->
            foldl func (func key (foldl func acc left)) right


start : Set k -> Maybe k
start set =
    mink Nothing set


end : Set k -> Maybe k
end set =
    maxk Nothing set
