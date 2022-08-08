module DesignSystem.Stories.Toast exposing (makeToast, stories)

import DesignSystem.Helpers exposing (Plugins, Renderer, palettize)
import Element
import Html
import Style.Types
import Style.Widgets.Button as Button
import Style.Widgets.Toast exposing (config, notes, view)
import Toasty
import Types.Error exposing (ErrorLevel(..), Toast)
import UIExplorer
    exposing
        ( storiesOf
        )


{-| Configure an example toast based on error level.
-}
makeToast : ErrorLevel -> Toast
makeToast level =
    case level of
        ErrorDebug ->
            Toast
                { actionContext = "request console log for server 5b8ad28f-3a82-4eec-aee6-7389f62ce04e"
                , level = level
                , recoveryHint = Nothing
                }
                "Server not found."

        ErrorInfo ->
            Toast
                { actionContext = "format volume b2b1a743-9c27-41bd-a430-4b38ae65fb5f"
                , level = level
                , recoveryHint = Just "Try choose a different volume."
                }
                "Volume not found."

        ErrorWarn ->
            Toast
                { actionContext = "decode stored application state retrieved from browser local storage"
                , level = level
                , recoveryHint = Nothing
                }
                "Missing OpenStack username."

        ErrorCrit ->
            Toast
                { actionContext = "get a list of volumes"
                , level = level
                , recoveryHint = Nothing
                }
                """
<html> <head><title>404 Not
Found</title></head> <body> <center>
<h1>404 Not Found</h1></center>
<hr><center>nginx/1.21.6</center>
</body> </html> <!-- a padding to
disable MSIE and Chrome friendly error
page -> <- a padding to disable MSIE
and Chrome friendly error page -> <!-
a padding to disable MSIE and Chrome
friendly error page -> <- a padding to
disable MSIE and Chrome friendly error
page -> <!- a padding to disable MSIE
and Chrome friendly error page -> <!-
a padding to disable MSIE and Chrome
friendly error page -> (response code:
404)
"""


stories :
    Renderer msg
    -> (Toasty.Msg Toast -> msg)
    -> List { name : String, onPress : Maybe msg }
    ->
        UIExplorer.UI
            { model
                | deployerColors : Style.Types.DeployerColorThemes
                , toasties : Toasty.Stack Toast
            }
            msg
            Plugins
stories renderer tagger levels =
    storiesOf
        "Toast"
        (List.map
            (\level ->
                ( level.name
                , \m ->
                    let
                        button press =
                            Button.primary (palettize m)
                                { text = "Show toast"
                                , onPress = press
                                }
                    in
                    Html.div []
                        [ renderer (palettize m) <|
                            Element.el [ Element.paddingXY 400 100 ]
                                (button level.onPress)
                        , Toasty.view config (view { palette = palettize m } { showDebugMsgs = True }) tagger m.customModel.toasties
                        ]
                , { note = notes }
                )
            )
            levels
        )
