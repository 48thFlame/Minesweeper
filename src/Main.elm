module Main exposing (main)

import Browser
import Html exposing (Html, div)
import Html.Attributes exposing (class, style)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { grid : List (List Cell) }


type alias Cell =
    { color : String
    }


init : flags -> ( Model, Cmd Msg )
init _ =
    let
        row =
            List.repeat 7 { color = "cadetblue" }

        grid =
            List.repeat 6 row
    in
    ( Model grid, Cmd.none )


type Msg
    = Msg1
    | Msg2


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Msg1 ->
            ( model, Cmd.none )

        Msg2 ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


gridToHtml : Model -> Html Msg
gridToHtml model =
    let
        cellToHtml rowI colI cell =
            let
                rowNum =
                    (rowI + 1) |> String.fromInt

                colNum =
                    (colI + 1) |> String.fromInt
            in
            div
                [ class "cell"
                , style "grid-row-start" rowNum
                , style "grid-column-start" colNum

                -- , class ("cell-row-" ++ rowNum)
                -- , class ("cell-col-" ++ rowNum)
                ]
                []

        rowToHtml rowI row =
            List.indexedMap (cellToHtml rowI) row
    in
    div [ class "grid_area" ] (List.indexedMap rowToHtml model.grid |> List.concat)


view : Model -> Html Msg
view model =
    div [ class "main" ]
        [ gridToHtml
            model
        ]
