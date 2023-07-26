module Main exposing (main)

import Browser exposing (Document)
import Browser.Events exposing (onKeyDown)
import Color
import Cycle exposing (Cycle)
import Element exposing (Attribute, Element, alignLeft, alignRight, centerX, centerY, column, el, fill, focused, height, inFront, padding, px, row, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Events exposing (onClick)
import Element.Font as Font
import Element.Input exposing (button)
import FeatherIcons as Icon exposing (Icon)
import Holder
import Json.Decode as Decode exposing (Decoder)
import Model exposing (Game, Lock, Model(..), Scores, Second(..), Settings)
import Random
import States exposing (State, Status(..), Statuses)
import Svg
import Svg.Attributes
import Time
import Toggle exposing (toggleSwitch)


type alias Flags =
    ()


main : Program Flags Model Msg
main =
    Browser.document { init = init, update = update, view = view, subscriptions = subscriptions }


type Msg
    = Guess State
    | GotShuffled (Cycle State)
    | Resume
    | SecondPassed
    | ViewBorders
    | HideBorders
    | Pause
    | NewGame
    | Start
    | Restart
    | AllowSkips
    | DisableSkips
    | Space
    | LeftArrow
    | RightArrow


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ timeSub, keySub ]


keySub : Sub Msg
keySub =
    onKeyDown <| Decode.andThen keyToMsg keyDecoder


keyDecoder : Decoder String
keyDecoder =
    Decode.field "key" Decode.string


keyToMsg : String -> Decoder Msg
keyToMsg key =
    case key of
        " " ->
            Decode.succeed Space

        "ArrowLeft" ->
            Decode.succeed LeftArrow

        "ArrowRight" ->
            Decode.succeed RightArrow

        _ ->
            Decode.fail "No binding for key"


timeSub : Sub Msg
timeSub =
    Time.every (secondInMillis <| Second 1) (always SecondPassed)


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( Creating { border = True, skips = True }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Guess state ->
            guess state model

        GotShuffled cycle ->
            start cycle model

        Start ->
            shuffle model

        Resume ->
            resume model

        SecondPassed ->
            incrementTime model

        ViewBorders ->
            setBorders True model

        HideBorders ->
            setBorders False model

        Pause ->
            pause model

        NewGame ->
            new model

        Restart ->
            restart model

        AllowSkips ->
            setSkips True model

        DisableSkips ->
            setSkips False model

        Space ->
            flipMode model

        LeftArrow ->
            last model

        RightArrow ->
            next model


flipMode : Model -> ( Model, Cmd Msg )
flipMode model =
    case model of
        Playing game ->
            ( Paused <| Model.pause game, Cmd.none )

        Paused lock ->
            ( Playing <| Model.resume lock, Cmd.none )

        _ ->
            ( model, Cmd.none )


setSkips : Bool -> Model -> ( Model, Cmd Msg )
setSkips skips model =
    case model of
        Creating settings ->
            ( Creating { settings | skips = skips }, Cmd.none )

        _ ->
            ( model, Cmd.none )


restart : Model -> ( Model, Cmd Msg )
restart model =
    case model of
        Playing game ->
            ( Creating <| Model.restart game, Cmd.none )

        _ ->
            ( model, Cmd.none )


new : Model -> ( Model, Cmd Msg )
new model =
    case model of
        Done scores ->
            ( Creating <| Model.new scores, Cmd.none )

        _ ->
            ( model, Cmd.none )


pause : Model -> ( Model, Cmd Msg )
pause model =
    case model of
        Playing game ->
            ( Paused <| Model.pause game, Cmd.none )

        _ ->
            ( model, Cmd.none )


shuffle : Model -> ( Model, Cmd Msg )
shuffle model =
    case model of
        Creating settings ->
            ( Creating settings, Random.generate GotShuffled <| Cycle.shuffle States.all.cycle )

        _ ->
            ( model, Cmd.none )


resume : Model -> ( Model, Cmd Msg )
resume model =
    case model of
        Paused lock ->
            ( Playing <| Model.resume lock, Cmd.none )

        _ ->
            ( model, Cmd.none )


incrementTime : Model -> ( Model, Cmd Msg )
incrementTime model =
    case model of
        Playing game ->
            ( Playing <| Model.incrementTime game, Cmd.none )

        _ ->
            ( model, Cmd.none )


start : Cycle State -> Model -> ( Model, Cmd Msg )
start states model =
    case model of
        Creating settings ->
            ( Playing <| Model.start states settings, Cmd.none )

        _ ->
            ( model, Cmd.none )


setBorders : Bool -> Model -> ( Model, Cmd Msg )
setBorders borders model =
    case model of
        Creating settings ->
            ( Creating { settings | border = borders }, Cmd.none )

        _ ->
            ( model, Cmd.none )


guess : State -> Model -> ( Model, Cmd Msg )
guess state model =
    case model of
        Playing game ->
            ( Model.guess state game, Cmd.none )

        _ ->
            ( model, Cmd.none )


secondInMillis : Second -> Float
secondInMillis (Second time) =
    toFloat <| time * 1000


next : Model -> ( Model, Cmd Msg )
next model =
    case model of
        Playing game ->
            ( Playing <| Model.next game, Cmd.none )

        _ ->
            ( model, Cmd.none )


last : Model -> ( Model, Cmd Msg )
last model =
    case model of
        Playing game ->
            ( Playing <| Model.last game, Cmd.none )

        _ ->
            ( model, Cmd.none )


view : Model -> Document Msg
view model =
    doc <|
        case model of
            Playing game ->
                viewGame game

            Paused lock ->
                viewPaused lock

            Done scores ->
                viewScores scores

            Creating settings ->
                viewSettings settings


title : String
title =
    "State Guesser"


doc : Element Msg -> Document Msg
doc =
    Document title << List.singleton << Element.layout [ width fill, height fill, Font.color Color.text.a ]


viewGame : Game -> Element Msg
viewGame game =
    let
        remaining =
            Model.remaining game

        misses =
            Model.missesSoFar game

        getStatus state =
            if Cycle.has state remaining then
                Unselected

            else if Holder.has state misses then
                Incorrect

            else
                Correct
    in
    map []
        { border = Model.usingBorder game
        , statuses = States.getStatuses getStatus
        , header = Just <| viewGameTooltip (Model.timeSoFar game) (Model.guessing game)
        , footer = Maybe.map viewMissedState (Model.missed game)
        }


viewGameTooltip : Second -> State -> Element Msg
viewGameTooltip time guessing =
    row [ width fill ]
        [ el [ alignLeft ] restartButton
        , el [ centerX ] <| text <| States.toString guessing
        , el [ alignRight ] <| viewTime time
        ]


overlay : Element Msg -> Attribute Msg
overlay element =
    inFront <| el [ width <| px 150, height <| px 120, centerX, centerY, Background.color Color.overlay.a, Border.rounded 20 ] element


viewMissedState : State -> Element Msg
viewMissedState state =
    el [ Font.color Color.error.a ] <| text <| States.toString state


map : List (Attribute Msg) -> { border : Bool, statuses : Statuses, header : Maybe (Element Msg), footer : Maybe (Element Msg) } -> Element Msg
map attributes { border, statuses, header, footer } =
    column (attributes ++ [ centerX ])
        [ el infoBar <| viewOrNone header
        , Element.map Guess <| States.view { border = border, statuses = statuses }
        , el infoBar <| viewOrNone footer
        ]


viewOrNone : Maybe (Element msg) -> Element msg
viewOrNone maybeEl =
    case maybeEl of
        Just el ->
            el

        Nothing ->
            Element.none


infoBar : List (Attribute Msg)
infoBar =
    [ width fill, height <| px 20 ]


restartButton : Element Msg
restartButton =
    button [ centerX, focused [] ] { onPress = Just Restart, label = viewIcon (squareSvg 20) Icon.rotateCw }


withMinutes : Second -> { minutes : Int, seconds : Int }
withMinutes (Second time) =
    { minutes = time // 60, seconds = remainderBy 60 time }


viewTime : Second -> Element Msg
viewTime time =
    let
        { minutes, seconds } =
            withMinutes time
    in
    row []
        [ text <| String.fromInt minutes
        , text ":"
        , text <| String.padLeft 2 '0' <| String.fromInt seconds
        ]


viewPaused : Lock -> Element Msg
viewPaused _ =
    el [ width fill, height fill, onClick Resume ] <|
        el [ centerX, centerY ] <|
            viewIcon (squareSvg 40) Icon.pause


viewScores : Scores -> Element Msg
viewScores scores =
    let
        misses =
            Model.allMisses scores

        getStatus state =
            if Holder.has state misses then
                Incorrect

            else
                Correct
    in
    map
        [ overlay <| viewScoresOverlay (Holder.size misses) (Model.finalTime scores) ]
        { border = Model.usedBorder scores
        , statuses = States.getStatuses getStatus
        , header = Nothing
        , footer = Nothing
        }


viewScoresOverlay : Int -> Second -> Element Msg
viewScoresOverlay misses time =
    column [ width fill, height fill, padding 10 ]
        [ row [ width fill ] [ text "Misses", el [ alignRight ] <| text <| String.fromInt misses ]
        , row [ width fill ] [ text "Time", el [ alignRight ] <| viewTime time ]
        , el [ width fill, height fill ] newGameButton
        ]


newGameButton : Element Msg
newGameButton =
    button [ centerX, centerY, focused [] ] { onPress = Just NewGame, label = viewIcon (squareSvg 20) Icon.chevronRight }


squareSvg : Int -> List (Svg.Attribute msg)
squareSvg size =
    let
        sizeString =
            String.fromInt size
    in
    [ Svg.Attributes.height sizeString, Svg.Attributes.width sizeString ]


viewIcon : List (Svg.Attribute msg) -> Icon -> Element msg
viewIcon attrs icon =
    Element.html <| Icon.toHtml attrs icon


viewSettings : Settings -> Element Msg
viewSettings settings =
    map [ overlay <| viewSettingsOverlay settings ]
        { border = settings.border
        , statuses = allUnselected
        , header = Nothing
        , footer = Nothing
        }


viewSettingsOverlay : Settings -> Element Msg
viewSettingsOverlay settings =
    column [ width fill, height fill, padding 10 ]
        [ row [ width fill ] [ text "Borders", el [ alignRight ] <| toggleSwitch { on = ViewBorders, off = HideBorders } settings.border ]
        , row [ width fill ] [ text "Skips", el [ alignRight ] <| toggleSwitch { on = AllowSkips, off = DisableSkips } settings.skips ]
        , el [ height fill, width fill ] startButton
        ]



-- animate


startButton : Element Msg
startButton =
    button [ centerX, centerY, focused [] ] { onPress = Just Start, label = viewIcon (squareSvg 20) Icon.play }


allUnselected : States.Statuses
allUnselected =
    States.getStatuses (always Unselected)
