module Toggle exposing (toggleSwitch)

import Color
import Element exposing (Element, focused)
import Element.Input exposing (button)
import Svg exposing (Svg, svg)
import Svg.Attributes exposing (..)


toggleSwitch : { on : msg, off : msg } -> Bool -> Element msg
toggleSwitch { on, off } state =
    button [ focused [] ] <|
        if state then
            { onPress = Just off, label = toggleRight }

        else
            { onPress = Just on, label = toggleLeft }


svgFeatherIcon : String -> List (Svg msg) -> Element msg
svgFeatherIcon className =
    Element.html
        << svg
            [ class <| "feather feather-" ++ className
            , fill "none"
            , height "20"
            , width "20"
            , stroke "currentColor"
            , strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "2"
            , viewBox "0 0 24 24"
            ]


toggleLeft : Element msg
toggleLeft =
    svgFeatherIcon "toggle-left"
        [ Svg.rect [ Svg.Attributes.x "1", y "5", width "22", height "14", rx "7", ry "7", fill Color.error.s ] []
        , Svg.circle [ cx "8", cy "12", r "3" ] []
        ]


toggleRight : Element msg
toggleRight =
    svgFeatherIcon "toggle-right"
        [ Svg.rect [ Svg.Attributes.x "1", y "5", width "22", height "14", rx "7", ry "7", fill Color.correct.s ] []
        , Svg.circle [ cx "16", cy "12", r "3" ] []
        ]
