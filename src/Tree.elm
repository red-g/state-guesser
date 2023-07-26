module Tree exposing (..)

import Array exposing (Array)
import Sort exposing (Sorter)


type Tree a
    = Node { item : a, lt : Tree a, gt : Tree a }
    | End


type alias C a =
    { item : a, lt : Tree a, gt : Tree a, sorter : Sorter a }


fromSorted : Array a -> Tree a
fromSorted array =
    let
        len =
            Array.length array

        pivot =
            len // 2
    in
    case Array.get pivot array of
        Just v ->
            Node
                { item = v
                , lt = fromSorted <| Array.slice 0 pivot array
                , gt = fromSorted <| Array.slice (pivot + 1) len array
                }

        Nothing ->
            End


fromList : Sorter a -> List a -> Tree a
fromList sorter ls =
    fromSorted <| Array.fromList <| Sort.list sorter ls


remove_ : a -> C a -> Maybe (C a)
remove_ val cycle =
    case nodeRemove cycle.sorter val { item = cycle.item, lt = cycle.lt, gt = cycle.gt } of
        Node node ->
            Just { sorter = cycle.sorter, item = node.item, lt = cycle.lt, gt = cycle.gt }

        End ->
            Nothing


treeRemove : Sorter a -> a -> Tree a -> Tree a
treeRemove sorter val tree =
    case tree of
        Node node ->
            nodeRemove sorter val node

        End ->
            tree


nodeRemove : Sorter a -> a -> { item : a, gt : Tree a, lt : Tree a } -> Tree a
nodeRemove sorter val node =
    case Sort.toOrder sorter val node.item of
        EQ ->
            -- not right - should preserve the other branches below it
            nodeFill { gt = node.gt, lt = node.lt }

        GT ->
            Node { node | gt = treeRemove sorter val node.gt }

        LT ->
            Node { node | lt = treeRemove sorter val node.lt }


rm : { item : a, gt : Tree a, lt : Tree a } -> Tree a
rm node =
    case ( node.gt, node.lt ) of
        ( End, l ) ->
            l

        ( g, End ) ->
            g

        ( Node gtNode, l ) ->
            let
                ( i, t ) =
                    splitLastLt gtNode
            in
            Node { item = i, gt = t, lt = l }


splitLastLt : { item : a, gt : Tree a, lt : Tree a } -> ( a, Tree a )
splitLastLt node =
    case node.lt of
        End ->
            ( node.item, node.gt )

        Node ltNode ->
            let
                ( i, lt ) =
                    splitLastLt ltNode
            in
            ( i, Node { node | lt = lt } )


nodeFill : { gt : Tree a, lt : Tree a } -> Tree a
nodeFill branches =
    case ( branches.gt, branches.lt ) of
        ( node, End ) ->
            node

        ( End, node ) ->
            node

        ( Node gt, lt ) ->
            Node
                { item = gt.item
                , lt = addToLt lt gt.lt
                , gt = gt.gt
                }


addToLt : Tree a -> Tree a -> Tree a
addToLt lt tree =
    case tree of
        Node node ->
            Node { node | lt = addToLt lt node.lt }

        End ->
            lt


has : a -> C a -> Bool
has val cycle =
    nodeHas cycle.sorter val { item = cycle.item, gt = cycle.gt, lt = cycle.lt }


nodeHas : Sorter a -> a -> { item : a, gt : Tree a, lt : Tree a } -> Bool
nodeHas sorter val node =
    case Sort.toOrder sorter val node.item of
        GT ->
            treeHas sorter node.item node.gt

        LT ->
            treeHas sorter node.item node.lt

        EQ ->
            True


treeHas : Sorter a -> a -> Tree a -> Bool
treeHas sorter val tree =
    case tree of
        Node node ->
            nodeHas sorter val node

        End ->
            False


last_ : a -> C a -> Maybe a
last_ val cycle =
    nodeLast cycle.sorter Nothing val { item = cycle.item, gt = cycle.gt, lt = cycle.lt }


nodeLast : Sorter a -> Maybe a -> a -> { item : a, gt : Tree a, lt : Tree a } -> Maybe a
nodeLast sorter prev val node =
    case Sort.toOrder sorter val node.item of
        GT ->
            treeLast sorter (Just val) node.item node.gt

        LT ->
            treeLast sorter Nothing node.item node.lt

        EQ ->
            prev


treeLast : Sorter a -> Maybe a -> a -> Tree a -> Maybe a
treeLast sorter prev val tree =
    case tree of
        Node node ->
            nodeLast sorter prev val node

        End ->
            Nothing


next_ : a -> C a -> Maybe a
next_ val cycle =
    nodeNext cycle.sorter Nothing val { item = cycle.item, gt = cycle.gt, lt = cycle.lt }


nodeNext : Sorter a -> Maybe a -> a -> { item : a, gt : Tree a, lt : Tree a } -> Maybe a
nodeNext sorter prev val node =
    case Sort.toOrder sorter val node.item of
        GT ->
            treeNext sorter Nothing node.item node.gt

        LT ->
            treeNext sorter (Just val) node.item node.lt

        EQ ->
            prev


treeNext : Sorter a -> Maybe a -> a -> Tree a -> Maybe a
treeNext sorter prev val tree =
    case tree of
        Node node ->
            nodeNext sorter prev val node

        End ->
            Nothing


getNext : Sorter a -> a -> Maybe a -> { item : a, gt : Tree a, lt : Tree a } -> Maybe a
getNext sorter val gt node =
    case Sort.toOrder sorter val node.item of
        EQ ->
            case node.gt of
                Node gtNode ->
                    Just <| minItem gtNode

                End ->
                    gt

        LT ->
            case node.lt of
                Node ltNode ->
                    getNext sorter val (Just node.item) ltNode

                End ->
                    Nothing

        GT ->
            case node.gt of
                Node gtNode ->
                    getNext sorter val gt gtNode

                End ->
                    Nothing


minItem : { item : a, gt : Tree a, lt : Tree a } -> a
minItem node =
    case node.lt of
        Node ltNode ->
            minItem ltNode

        End ->
            node.item
