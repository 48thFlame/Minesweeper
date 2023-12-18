{-
   i = cols_num * (row ) + col

   -col = cols_num * row - i
   col = - (cols_num * row - i)
   col = -cols_num * row + i

   col = mod(i, cols_num)

   cols_num * row = i - col
   row = (i - col) / cols_num

   row = floor(i / cols_num)

   ~~~~~~~~~

   -cn-1 -cn -cn+1
   -1 0 1
   cn-1 cn cn+1
-}


module Main exposing (main)

import Browser
import Html exposing (Html, div, img, text)
import Html.Attributes exposing (class, src, style)
import Html.Events exposing (on)
import Json.Decode as Decode exposing (Decoder)
import Random
import Set exposing (Set)


main : Program ( Int, Int ) Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { rowsNum : Int
    , colsNum : Int
    , mines : Set Int
    , flagged : Set Int
    , opened : Set Int
    }


percentMines : Float
percentMines =
    0.18


init : ( Int, Int ) -> ( Model, Cmd Msg )
init flags =
    let
        rowsNum : Int
        rowsNum =
            Tuple.first flags

        colsNum : Int
        colsNum =
            Tuple.second flags

        gridSize : Int
        gridSize =
            rowsNum * colsNum

        {- |
           // number of mines that should be, adds one because if user clicks a mine spot should remove that mine otherwise just remove a mine
           TODO: duplicates problem, losing on first turn problem.
        -}
        numberOfMines : Int
        numberOfMines =
            floor (percentMines * toFloat gridSize)
    in
    ( { rowsNum = rowsNum
      , colsNum = colsNum
      , mines = Set.empty
      , flagged = Set.empty
      , opened = Set.empty
      }
    , Random.list numberOfMines (Random.int 0 gridSize)
        |> Random.generate NewMines
    )


type Msg
    = NewMines (List Int)
    | OpenCell Int
    | FlagCell Int


expandOpened : Int -> Int -> Set Int -> Set Int -> Int -> Set Int -> Set Int
expandOpened rowsNum colsNum mines flagged i opened =
    let
        numberOfMines =
            countMines rowsNum colsNum mines i

        newOpened =
            Set.insert i opened

        indexes =
            getIndexesAround rowsNum colsNum i
    in
    if Set.member i opened || numberOfMines /= 0 then
        newOpened

    else
        List.foldl (expandOpened rowsNum colsNum mines flagged) newOpened indexes


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewMines mines ->
            ( { model | mines = Set.fromList mines }, Cmd.none )

        OpenCell i ->
            let
                newOpened =
                    if Set.member i model.flagged then
                        -- If cell is flagged, can't open it
                        model.opened

                    else
                        expandOpened model.rowsNum model.colsNum model.mines model.flagged i model.opened
            in
            ( { model
                | opened =
                    newOpened
              }
            , Cmd.none
            )

        FlagCell i ->
            ( { model
                | flagged =
                    if Set.member i model.flagged then
                        Set.remove i model.flagged

                    else if not (Set.member i model.opened) then
                        Set.insert i model.flagged

                    else
                        model.flagged
              }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


type Cell
    = Closed
    | Number Int
    | Flag
    | Mine


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


getIndexesAround : Int -> Int -> Int -> List Int
getIndexesAround rowsNum colsNum i =
    let
        row =
            i // rowsNum

        col =
            modBy colsNum i

        upLeft =
            i - colsNum - 1

        directUp =
            i - colsNum

        upRight =
            i - colsNum + 1

        directLeft =
            i - 1

        directRight =
            i + 1

        downLeft =
            i + colsNum - 1

        directDown =
            i + colsNum

        downRight =
            i + colsNum + 1
    in
    if row == 0 then
        if col == 0 then
            [ directRight, directDown, downRight ]

        else if col == colsNum - 1 then
            [ directLeft, directDown, downLeft ]

        else
            [ directLeft, downLeft, directDown, downRight, directRight ]

    else if row == rowsNum - 1 then
        if col == 0 then
            [ directUp, upRight, directRight ]

        else if col == colsNum - 1 then
            [ directUp, upLeft, directLeft ]

        else
            [ directLeft, upLeft, directUp, upRight, directRight ]

    else if col == 0 then
        [ directUp, upRight, directRight, downRight, directDown ]

    else if col == colsNum - 1 then
        [ directUp, upLeft, directLeft, downLeft, directDown ]

    else
        [ directUp, upRight, directRight, downRight, directDown, downLeft, directLeft, upLeft ]


countMines : Int -> Int -> Set Int -> Int -> Int
countMines rowsNum colsNum mines i =
    getIndexesAround rowsNum colsNum i
        |> Set.fromList
        |> Set.intersect mines
        |> Set.size


getGrid : Int -> Int -> Set Int -> Set Int -> Set Int -> List Cell
getGrid rowsNum colsNum opened flagged mines =
    -- let
    --     replaceItemIfInSet set newItem i currentItem =
    --         if Set.member i set then
    --             newItem
    --         else
    --             currentItem
    -- in
    -- List.repeat (rowsNum * colsNum) Closed
    --     |> List.indexedMap (replaceItemIfInSet flagged Flag)
    let
        getCellAtIndex : Int -> Cell
        getCellAtIndex i =
            if Set.member i flagged then
                Flag

            else if Set.member i opened then
                if Set.member i mines then
                    Mine

                else
                    Number (countMines rowsNum colsNum mines i)

            else
                Closed
    in
    List.range 0 (rowsNum * colsNum - 1)
        |> List.map getCellAtIndex


mouseMsgFromEventId : Int -> Int -> Msg
mouseMsgFromEventId cellI mouseBtnId =
    -- 0 -> MainButton
    -- 1 -> MiddleButton
    -- 2 -> SecondButton
    -- 3 -> BackButton
    -- 4 -> ForwardButton
    case mouseBtnId of
        0 ->
            OpenCell cellI

        2 ->
            FlagCell cellI

        _ ->
            -- if its any mouse button by default just open the cell
            OpenCell cellI


gridToHtml : Int -> Int -> List Cell -> Html Msg
gridToHtml rowsNum colsNum grid =
    let
        getCellRowStr : Int -> String
        getCellRowStr i =
            (i // colsNum) + 1 |> String.fromInt

        getCellColStr : Int -> String
        getCellColStr i =
            modBy colsNum i + 1 |> String.fromInt

        clickMsgEventDecoder : Int -> Decoder Msg
        clickMsgEventDecoder i =
            Decode.map
                (mouseMsgFromEventId i)
                (Decode.field "button" Decode.int)

        cellInGridToHtml : Int -> Cell -> Html Msg
        cellInGridToHtml i cell =
            div
                [ class "cell"
                , style "grid-row-start" (getCellRowStr i)
                , style "grid-column-start" (getCellColStr i)
                , on "mousedown" (clickMsgEventDecoder i)
                ]
                [ cellToHtml cell ]

        colsNumStr =
            String.fromInt colsNum

        rowsNumStr =
            String.fromInt rowsNum
    in
    div
        [ class "grid_area"
        , style "aspect-ratio" (colsNumStr ++ "/" ++ rowsNumStr)
        , style "grid-template-rows" ("repeat(" ++ rowsNumStr ++ ", 1fr)")
        , style "grid-template-columns" ("repeat(" ++ colsNumStr ++ ", 1fr)")
        ]
        (List.indexedMap cellInGridToHtml grid)


view : Model -> Html Msg
view model =
    div [ class "main" ]
        [ gridToHtml
            model.rowsNum
            model.colsNum
            (getGrid model.rowsNum model.colsNum model.opened model.flagged model.mines)
        ]
