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
import Html.Events exposing (on, onClick)
import Json.Decode as Decode exposing (Decoder)
import Random
import Random.Set
import Set exposing (Set)


main : Program ( Int, Int ) Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type GameResult
    = Playing
    | Won
    | Lost


type alias Model =
    { gameResult : GameResult
    , rowsNum : Int
    , colsNum : Int
    , mines : Set Int
    , flagged : Set Int
    , questionFlagged : Set Int
    , opened : Set Int
    }


percentMines : Float
percentMines =
    0.15625


init : ( Int, Int ) -> ( Model, Cmd Msg )
init flags =
    let
        rowsNum : Int
        rowsNum =
            Tuple.first flags

        colsNum : Int
        colsNum =
            Tuple.second flags
    in
    ( { gameResult = Playing
      , rowsNum = rowsNum
      , colsNum = colsNum
      , mines = Set.empty
      , flagged = Set.empty
      , questionFlagged = Set.empty
      , opened = Set.empty
      }
    , Cmd.none
    )


type Msg
    = StartGame Int (Set Int)
    | OpenCell Int
    | FlagCell Int
    | ExpandCell Int
    | NewGame


{-| expand a cell that is 0 all around and continue doing so until can't,
doesn't need questionFlagged because doesn't use `flagged` to count mines instead just to not open it
-}
expandOpenedFromClosed : Int -> Int -> Set Int -> Set Int -> Int -> Set Int -> Set Int
expandOpenedFromClosed rowsNum colsNum mines flagged i opened =
    let
        numberOfMines =
            countMines rowsNum colsNum mines i

        newOpened =
            Set.insert i opened

        indexes =
            getIndexesAround rowsNum colsNum i
    in
    if Set.member i flagged then
        -- If the cell is flagged don't open it
        opened

    else if Set.member i opened || numberOfMines /= 0 then
        newOpened

    else
        List.foldl (expandOpenedFromClosed rowsNum colsNum mines flagged) newOpened indexes


expandCell : Int -> Int -> Set Int -> Set Int -> Set Int -> Set Int -> Int -> List Int
expandCell rowsNum colsNum mines flagged questionFlagged opened i =
    let
        unFlaggedMinesNum =
            countUnFlaggedMines rowsNum colsNum mines flagged i

        indexes =
            getIndexesAround rowsNum colsNum i
    in
    if unFlaggedMinesNum == 0 then
        -- If should expand cell then filter out all already opened cells
        List.filter (\j -> not (Set.member j (Set.union opened questionFlagged))) indexes

    else
        []


expandOpenedFromModel : Int -> Model -> Model
expandOpenedFromModel i model =
    { model
        | opened =
            expandOpenedFromClosed
                model.rowsNum
                model.colsNum
                model.mines
                (Set.union model.flagged model.questionFlagged)
                i
                model.opened
    }


getGameResult : Model -> GameResult
getGameResult model =
    let
        minesThatOpened =
            Set.intersect model.mines model.opened

        flaggedWithOpened =
            Set.union model.flagged model.opened

        flaggedAllAndOnlyMines =
            Set.diff model.flagged model.mines
                |> Set.union (Set.diff model.mines model.flagged)
                |> Set.isEmpty
    in
    if Set.size minesThatOpened /= 0 then
        Lost

    else if Set.size flaggedWithOpened >= (model.rowsNum * model.colsNum) && flaggedAllAndOnlyMines then
        Won

    else
        Playing


generateMines : Int -> Int -> Int -> Cmd Msg
generateMines rowsNum colsNum i =
    let
        gridSize : Int
        gridSize =
            rowsNum * colsNum

        numberOfMines : Int
        numberOfMines =
            round (percentMines * toFloat gridSize)
    in
    Random.Set.set numberOfMines (Random.int 0 (gridSize - 1))
        |> Random.generate (StartGame i)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewGame ->
            init ( model.rowsNum, model.colsNum )

        StartGame i mines ->
            let
                newMines =
                    -- remove cause need to not lost on first turn
                    Set.remove i mines
            in
            ( { model | mines = newMines |> Debug.log "mines" }
                |> expandOpenedFromModel i
            , Cmd.none
            )

        OpenCell i ->
            if not (Set.isEmpty model.mines) then
                -- If game started because mines exist
                ( if Set.member i (Set.union model.flagged model.questionFlagged) then
                    -- If cell is flagged, can't open it
                    model

                  else
                    expandOpenedFromModel i model
                        |> (\m -> { m | gameResult = getGameResult m })
                , Cmd.none
                )

            else
                ( model
                , generateMines model.rowsNum model.colsNum i
                )

        FlagCell i ->
            let
                inSet : Set Int -> Bool
                inSet s =
                    Set.member i s

                flags =
                    if inSet model.opened then
                        ( model.flagged, model.questionFlagged )

                    else if inSet model.flagged then
                        ( Set.remove i model.flagged, Set.insert i model.questionFlagged )

                    else if inSet model.questionFlagged then
                        ( model.flagged, Set.remove i model.questionFlagged )

                    else
                        ( Set.insert i model.flagged, model.questionFlagged )
            in
            ( { model
                | flagged = Tuple.first flags
                , questionFlagged = Tuple.second flags
              }
                |> (\m -> { m | gameResult = getGameResult m })
            , Cmd.none
            )

        ExpandCell i ->
            let
                indexes =
                    expandCell
                        model.rowsNum
                        model.colsNum
                        model.mines
                        model.flagged
                        model.questionFlagged
                        model.opened
                        i

                folder j m =
                    update (OpenCell j) m |> Tuple.first
            in
            ( List.foldl folder model indexes, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


type Cell
    = ClosedCell
    | NumberCell Int
    | MineFlagCell
    | QuestionFlagCell
    | MineCell


cellToHtml : Cell -> Html Msg
cellToHtml cell =
    case cell of
        ClosedCell ->
            div [ class "closed-cell" ] []

        NumberCell num ->
            div [ class "number-cell" ]
                [ String.fromInt num |> text ]

        MineFlagCell ->
            div [ class "flag-cell" ]
                [ img [ src "assets/flag.svg", class "cell-img" ] [] ]

        QuestionFlagCell ->
            div [ class "flag-cell" ]
                [ img [ src "assets/question flag.svg", class "cell-img" ] [] ]

        MineCell ->
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


countUnFlaggedMines : Int -> Int -> Set Int -> Set Int -> Int -> Int
countUnFlaggedMines rowsNum colsNum mines flagged i =
    let
        minesNum =
            countMines rowsNum colsNum mines i

        flaggedAroundNum =
            getIndexesAround rowsNum colsNum i
                |> Set.fromList
                |> Set.intersect flagged
                |> Set.size
    in
    minesNum - flaggedAroundNum


getGrid : Int -> Int -> Set Int -> Set Int -> Set Int -> Set Int -> List Cell
getGrid rowsNum colsNum mines flagged questionFlagged opened =
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
                MineFlagCell

            else if Set.member i questionFlagged then
                QuestionFlagCell

            else if Set.member i opened then
                if Set.member i mines then
                    MineCell

                else
                    NumberCell (countMines rowsNum colsNum mines i)

            else
                ClosedCell
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

        1 ->
            ExpandCell cellI

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
        [ Html.h1 [ class "title" ] [ text "Minesweeper!" ]
        , div [ class "game-result" ]
            (case model.gameResult of
                Playing ->
                    []

                Won ->
                    [ Html.h2 [ class "game-result-text" ] [ text "You Won!!" ] ]

                Lost ->
                    [ Html.h2 [ class "game-result-text" ] [ text "You Lost :(" ] ]
            )
        , gridToHtml
            model.rowsNum
            model.colsNum
            (getGrid
                model.rowsNum
                model.colsNum
                model.mines
                model.flagged
                model.questionFlagged
                model.opened
            )
        , div [ class "bottom-control-div" ]
            [ Html.p
                [ class "mine-count" ]
                [ text
                    ("Mines left: "
                        ++ String.fromInt (Set.size model.flagged)
                        ++ "/"
                        ++ String.fromInt (Set.size model.mines)
                    )
                ]
            , Html.button
                [ class "play-again-button"
                , onClick NewGame
                ]
                [ text "Play Again" ]
            ]
        ]
