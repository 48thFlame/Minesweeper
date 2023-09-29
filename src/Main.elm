port module Main exposing (main)

import Browser
import Html exposing (Html, div, img, text)
import Html.Attributes exposing (class, src)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


port newGrid : ( Int, Int ) -> Cmd msg


port gridReceiver : (List Int -> msg) -> Sub msg



-- i = cols_num * (row ) + col


type alias Model =
    { grid : List Cell }


type Cell
    = Closed
    | Number Int
    | Flag
    | Mine


init : flags -> ( Model, Cmd Msg )
init _ =
    -- let
    -- row =
    --     List.repeat 7 Flag
    -- -- List.repeat 7 (Number 6)
    -- grid =
    --     List.repeat 6 row
    -- grid =
    --     [ [ Number 6, Closed, Closed, Closed, Flag, Number 6, Number 6 ]
    --     , [ Number 6, Number 6, Number 5, Number 6, Number 6, Closed, Number 6 ]
    --     , [ Flag, Number 6, Number 6, Number 6, Number 6, Number 6, Number 6 ]
    --     , [ Number 6, Number 6, Closed, Number 6, Number 6, Flag, Number 6 ]
    --     , [ Number 6, Number 6, Closed, Flag, Number 6, Number 6, Number 6 ]
    --     , [ Number 6, Number 6, Number 6, Flag, Flag, Number 6, Closed ]
    --     ]
    -- in
    ( Model [], newGrid ( 6, 7 ) )


type Msg
    = NewGrid (List Int)


intToCell : Int -> Cell
intToCell i =
    case i of
        9 ->
            Mine

        10 ->
            Closed

        11 ->
            Flag

        num ->
            Number num


decodeIncomingGrid : List Int -> List Cell
decodeIncomingGrid incGrid =
    List.map intToCell incGrid


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewGrid grid ->
            let
                _ =
                    Debug.log "grid" grid
            in
            ( { model | grid = decodeIncomingGrid grid }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    gridReceiver NewGrid


cellToHtml : Cell -> Html Msg
cellToHtml cell =
    case cell of
        Closed ->
            div [ class "cell", class "closed-cell" ] []

        Number num ->
            div [ class "cell", class "number-cell" ]
                [ String.fromInt num |> text ]

        Flag ->
            div [ class "cell", class "flag-cell" ]
                [ img [ src "assets/flag.svg", class "cell-img" ] [] ]

        Mine ->
            div [ class "cell", class "mine-cell" ]
                [ img [ src "assets/mine.svg", class "cell-img" ] [] ]


gridToHtml : Model -> Html Msg
gridToHtml model =
    -- createGridSlot rowI colI cell =
    --     let
    --         rowNum =
    --             (rowI + 1) |> String.fromInt
    --         colNum =
    --             (colI + 1) |> String.fromInt
    --     in
    --     div
    --         [ style "grid-row-start" rowNum
    --         , style "grid-column-start" colNum
    --         ]
    --         [ cellToHtml cell ]
    div [ class "grid_area" ] (List.map cellToHtml model.grid)


view : Model -> Html Msg
view model =
    div [ class "main" ]
        [ gridToHtml
            model
        ]
