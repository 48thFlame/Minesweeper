port module Main exposing (main)

import Browser
import Html exposing (Html, div, img, text)
import Html.Attributes exposing (class, src, style)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


{-| `gridGetter` is an incoming port to get updated grid to display, for example after sends `updateGrid` because new cell was opened.
-}
port gridGetter : (List Int -> msg) -> Sub msg


{-| `minesGetter` is an incoming port to get new mines after starting a new game.
-}
port minesGetter : (List Int -> msg) -> Sub msg


{-| `newGame` is an outgoing port to get a random list of mine locations.
-}
port newGame : { rowsNum : Int, colsNum : Int } -> Cmd msg


{-| `updateGrid` is an outgoing port to update the grid because new cell was opened.
-}
port updateGrid :
    { rowsNum : Int
    , colsNum : Int
    , mines : List Int
    , opened : List Int
    }
    -> Cmd msg


type alias Model =
    { grid : List Cell
    , rowsNum : Int
    , colsNum : Int
    , mines : List Int
    , opened : List Int
    }


{-| `Cell` is a cell of the grid top to display
-}
type Cell
    = Closed
    | Number Int
    | Flag
    | Mine


init : flags -> ( Model, Cmd Msg )
init _ =
    let
        rowsNum =
            6

        colsNum =
            7
    in
    ( { grid = []
      , rowsNum = rowsNum
      , colsNum = colsNum
      , mines = []
      , opened = []
      }
    , newGame { rowsNum = rowsNum, colsNum = colsNum }
    )


type Msg
    = NewGrid (List Int)
    | NewMines (List Int)
    | OpenCell Int


decodeIncomingGrid : List Int -> List Cell
decodeIncomingGrid incGrid =
    let
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
    in
    List.map intToCell incGrid


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewGrid grid ->
            ( { model | grid = decodeIncomingGrid grid }, Cmd.none )

        NewMines mines ->
            ( { model | mines = mines |> Debug.log "mines" }, Cmd.none )

        OpenCell _ ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ gridGetter NewGrid
        , minesGetter NewMines
        ]


cellToHtml : Cell -> Html Msg
cellToHtml cell =
    case cell of
        Closed ->
            div [ class "closed-cell" ] []

        Number num ->
            div [ class "number-cell" ]
                [ String.fromInt num |> text ]

        Flag ->
            div [ class "flag-cell" ]
                [ img [ src "assets/flag.svg", class "cell-img" ] [] ]

        Mine ->
            div [ class "mine-cell" ]
                [ img [ src "assets/mine.svg", class "cell-img" ] [] ]



{-
   i = cols_num * (row ) + col

   -col = cols_num * row - i
   col = - (cols_num * row - i)
   col = -cols_num * row + i

   col = mod(i, cols_num)

   cols_num * row = i - col
   row = (i - col) / cols_num

   row = floor(i / cols_num)
-}


gridToHtml : Model -> Html Msg
gridToHtml model =
    let
        colsNum =
            model.colsNum

        getRowNumStr : Int -> String
        getRowNumStr i =
            (i // colsNum) + 1 |> String.fromInt

        getColNumStr : Int -> String
        getColNumStr i =
            modBy colsNum i + 1 |> String.fromInt

        gridCell i cell =
            div
                [ class "cell"
                , style "grid-row-start" (getRowNumStr i)
                , style "grid-column-start" (getColNumStr i)
                ]
                [ cellToHtml cell ]

        colsNumStr =
            model.colsNum |> String.fromInt

        rowsNumStr =
            model.rowsNum |> String.fromInt
    in
    div
        [ class "grid_area"
        , style "aspect-ratio" (colsNumStr ++ "/" ++ rowsNumStr)
        , style "grid-template-rows" ("repeat(" ++ rowsNumStr ++ ", 1fr)")
        , style "grid-template-columns" ("repeat(" ++ colsNumStr ++ ", 1fr)")
        ]
        (List.indexedMap gridCell model.grid)


view : Model -> Html Msg
view model =
    div [ class "main" ]
        [ gridToHtml
            model
        ]
