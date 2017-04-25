port module Main exposing (..)

import Html.Attributes as A exposing (style, value)
import Html.Events exposing (onInput, onClick, onWithOptions, on)
import Html exposing (Html, text, div)
import Html
import Visualization.Scale as Scale exposing (ContinuousScale, ContinuousTimeScale)
import Visualization.Axis as Axis
import Visualization.List as List
import Visualization.Shape as Shape
import Date
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Date exposing (Date)
import String
import Tuple
import Maybe as M
import Window


padding : Float
padding =
    30


getMinimumDate data =
    List.map Tuple.first data |> List.minimum |> M.withDefault 1492711206157


getMaximumDate data =
    List.map Tuple.first data |> List.maximum |> M.withDefault 1592711206157


view : Model -> Svg msg
view model =
    let
        size : Window.Size
        size = model.size

        w : Float
        w = toFloat size.width

        h : Float
        h = toFloat size.height

        xScale : ContinuousTimeScale
        xScale =
            Scale.time ( Date.fromTime (getMinimumDate model.data), Date.fromTime (getMaximumDate model.data) ) ( 0, w - 2 * padding )

        yScale : ContinuousScale
        yScale =
            Scale.linear ( 0, 120 ) ( h - 2 * padding, 0 )

        opts : Axis.Options a
        opts =
            Axis.defaultOptions

        xAxis : Svg msg
        xAxis =
            Axis.axis { opts | orientation = Axis.Bottom, tickCount = List.length model.data } xScale

        yAxis : Svg msg
        yAxis =
            Axis.axis { opts | orientation = Axis.Left, tickCount = 5 } yScale

        areaGenerator : ( Float, Float ) -> Maybe ( ( Float, Float ), ( Float, Float ) )
        areaGenerator ( x, y ) =
            Just ( ( Scale.convert xScale (Date.fromTime x), Tuple.first (Scale.rangeExtent yScale) ), ( Scale.convert xScale (Date.fromTime x), Scale.convert yScale y ) )

        lineGenerator : ( Float, Float ) -> Maybe ( Float, Float )
        lineGenerator ( x, y ) =
            Just ( Scale.convert xScale (Date.fromTime x), Scale.convert yScale y )

        area : String
        area =
            List.map areaGenerator model.data
                |> Shape.area Shape.linearCurve

        line : String
        line =
            List.map lineGenerator model.data
                |> Shape.line Shape.linearCurve
    in
        svg [ width (toString w ++ "px"), height (toString h ++ "px") ]
            [ g [ transform ("translate(" ++ toString (padding - 1) ++ ", " ++ toString (h - padding) ++ ")") ]
                [ xAxis ]
            , g [ transform ("translate(" ++ toString (padding - 1) ++ ", " ++ toString padding ++ ")") ]
                [ yAxis ]
            , g [ transform ("translate(" ++ toString padding ++ ", " ++ toString padding ++ ")"), class "series" ]
                [ Svg.path [ d area, stroke "none", strokeWidth "3px", fill "rgba(255, 0, 0, 0.54)" ] []
                , Svg.path [ d line, stroke "red", strokeWidth "3px", fill "none" ] []
                ]
            ]

main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL

type alias Flags =
    { width : Int
    , height : Int
    }


type alias Model =
    { data : List ( Float, Float )
    , size : Window.Size
    }


type Msg
    = NewPoint ( Float, Float )
    | Resize Window.Size
    | NoOp


initialModel : Flags -> Model
initialModel size =
    { data = []
    , size = size
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( initialModel flags
    , Cmd.none
    )



-- PORTS


port newData : (( Float, Float ) -> msg) -> Sub msg



-- UPDATE


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        NewPoint d ->
            ( { model
                | data =
                    if List.length model.data < 100 then
                        (d :: model.data)
                    else
                        (d :: (List.take 99 model.data))
              }
            , Cmd.none
            )

        Resize size ->
            ( { model | size = size }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ newData (\p -> NewPoint p)
        , Window.resizes (\size -> Resize size)
        ]
