module Color exposing (Color, correct, error, overlay, text)

import Element exposing (rgb, rgb255)


type alias Color =
    { s : String, a : Element.Color }


decimal : Float -> Float -> Float -> Color
decimal r g b =
    { s = fromChannels chanFromDec r g b
    , a = rgb r g b
    }


chanFromDec : Float -> String
chanFromDec d =
    d
        * 255
        |> floor
        |> min 255
        |> String.fromInt


chanFromInt : Int -> String
chanFromInt i =
    i
        |> min 255
        |> String.fromInt


fromChannels : (c -> String) -> c -> c -> c -> String
fromChannels converter r g b =
    "rgb(" ++ converter r ++ "," ++ converter g ++ "," ++ converter b ++ ")"


int : Int -> Int -> Int -> Color
int r g b =
    { s = fromChannels chanFromInt r g b
    , a = rgb255 r g b
    }


overlay : Color
overlay =
    decimal 1 1 1


error : Color
error =
    decimal 1 0 0


text : Color
text =
    grayscale 0.3


correct : Color
correct =
    int 55 170 34


grayscale : Float -> Color
grayscale shade =
    { s = fromChannels chanFromDec shade shade shade
    , a = rgb shade shade shade
    }
