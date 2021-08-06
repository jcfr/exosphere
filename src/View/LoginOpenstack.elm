module View.LoginOpenstack exposing (EntryType, Model, Msg, init, update, view)

import Element
import Element.Font as Font
import Element.Input as Input
import OpenStack.OpenRc
import OpenStack.Types as OSTypes
import Style.Helpers as SH
import Types.SharedMsg as SharedMsg
import Types.Types exposing (SharedModel)
import View.Helpers as VH
import View.Types
import Widget


type alias Model =
    { creds : OSTypes.OpenstackLogin
    , openRc : String
    , entryType : EntryType
    }


type Msg
    = InputAuthUrl String
    | InputUserDomain String
    | InputUsername String
    | InputPassword String
    | InputOpenRc String
    | SelectOpenRcInput
    | SelectCredsInput
    | ProcessOpenRc
    | RequestAuthToken
    | SelectLoginPicker
    | NoOp


type EntryType
    = CredsEntry
    | OpenRcEntry


init : Model
init =
    { creds =
        { authUrl = ""
        , userDomain = ""
        , username = ""
        , password = ""
        }
    , openRc = ""
    , entryType = CredsEntry
    }


update : Msg -> SharedModel -> Model -> ( Model, Cmd Msg, SharedMsg.SharedMsg )
update msg _ model =
    let
        oldCreds =
            model.creds

        updateCreds : Model -> OSTypes.OpenstackLogin -> Model
        updateCreds model_ newCreds =
            { model_ | creds = newCreds }
    in
    case msg of
        InputAuthUrl authUrl ->
            ( updateCreds model { oldCreds | authUrl = authUrl }, Cmd.none, SharedMsg.NoOp )

        InputUserDomain userDomain ->
            ( updateCreds model { oldCreds | userDomain = userDomain }, Cmd.none, SharedMsg.NoOp )

        InputUsername username ->
            ( updateCreds model { oldCreds | username = username }, Cmd.none, SharedMsg.NoOp )

        InputPassword password ->
            ( updateCreds model { oldCreds | password = password }, Cmd.none, SharedMsg.NoOp )

        InputOpenRc openRc ->
            ( { model | openRc = openRc }, Cmd.none, SharedMsg.NoOp )

        SelectOpenRcInput ->
            ( { model | entryType = OpenRcEntry }, Cmd.none, SharedMsg.NoOp )

        SelectCredsInput ->
            ( { model | entryType = CredsEntry }, Cmd.none, SharedMsg.NoOp )

        ProcessOpenRc ->
            let
                newCreds =
                    OpenStack.OpenRc.processOpenRc model.creds model.openRc
            in
            ( { model
                | creds = newCreds
                , entryType = CredsEntry
              }
            , Cmd.none
            , SharedMsg.NoOp
            )

        RequestAuthToken ->
            ( model, Cmd.none, SharedMsg.RequestUnscopedToken model.creds )

        SelectLoginPicker ->
            -- TODO somehow navigate to login picker
            ( model, Cmd.none, SharedMsg.NoOp )

        NoOp ->
            ( model, Cmd.none, SharedMsg.NoOp )


view : View.Types.Context -> Model -> Element.Element Msg
view context model =
    let
        allCredsEntered =
            -- These fields must be populated before login can be attempted
            [ model.creds.authUrl
            , model.creds.userDomain
            , model.creds.username
            , model.creds.password
            ]
                |> List.any (\x -> String.isEmpty x)
                |> not
    in
    Element.column (VH.exoColumnAttributes ++ [ Element.width Element.fill ])
        [ Element.el
            (VH.heading2 context.palette)
            (Element.text "Add an OpenStack Account")
        , Element.column VH.formContainer
            [ case model.entryType of
                CredsEntry ->
                    loginOpenstackCredsEntry context model allCredsEntered

                OpenRcEntry ->
                    loginOpenstackOpenRcEntry context model
            , Element.row (VH.exoRowAttributes ++ [ Element.width Element.fill ])
                (case model.entryType of
                    CredsEntry ->
                        [ Element.el [] (loginPickerButton context)
                        , Widget.textButton
                            (SH.materialStyle context.palette).button
                            { text = "Use OpenRC File"
                            , onPress = Just SelectOpenRcInput
                            }
                        , Element.el [ Element.alignRight ]
                            (Widget.textButton
                                (SH.materialStyle context.palette).primaryButton
                                { text = "Log In"
                                , onPress =
                                    if allCredsEntered then
                                        Just RequestAuthToken

                                    else
                                        Nothing
                                }
                            )
                        ]

                    OpenRcEntry ->
                        [ Element.el VH.exoPaddingSpacingAttributes
                            (Widget.textButton
                                (SH.materialStyle context.palette).button
                                { text = "Cancel"
                                , onPress = Just SelectCredsInput
                                }
                            )
                        , Element.el (VH.exoPaddingSpacingAttributes ++ [ Element.alignRight ])
                            (Widget.textButton
                                (SH.materialStyle context.palette).primaryButton
                                { text = "Submit"
                                , onPress = Just ProcessOpenRc
                                }
                            )
                        ]
                )
            ]
        ]


loginOpenstackCredsEntry : View.Types.Context -> Model -> Bool -> Element.Element Msg
loginOpenstackCredsEntry context model allCredsEntered =
    let
        creds =
            model.creds

        textField text placeholderText onChange labelText =
            Input.text
                (VH.inputItemAttributes context.palette.background)
                { text = text
                , placeholder = Just (Input.placeholder [] (Element.text placeholderText))
                , onChange = onChange
                , label = Input.labelAbove [ Font.size 14 ] (Element.text labelText)
                }
    in
    Element.column
        VH.formContainer
        [ Element.el [] (Element.text "Enter your credentials")
        , textField
            creds.authUrl
            "OS_AUTH_URL e.g. https://mycloud.net:5000/v3"
            InputAuthUrl
            "Keystone auth URL"
        , textField
            creds.userDomain
            "User domain e.g. default"
            InputUserDomain
            "User Domain (name or ID)"
        , textField
            creds.username
            "User name e.g. demo"
            InputUsername
            "User Name"
        , Input.currentPassword
            (VH.inputItemAttributes context.palette.surface)
            { text = creds.password
            , placeholder = Just (Input.placeholder [] (Element.text "Password"))
            , show = False
            , onChange = InputPassword
            , label = Input.labelAbove [ Font.size 14 ] (Element.text "Password")
            }
        , if allCredsEntered then
            Element.none

          else
            Element.el
                (VH.exoElementAttributes
                    ++ [ Element.alignRight
                       , Font.color (context.palette.error |> SH.toElementColor)
                       ]
                )
                (Element.text "All fields are required.")
        ]


loginOpenstackOpenRcEntry : View.Types.Context -> Model -> Element.Element Msg
loginOpenstackOpenRcEntry context model =
    Element.column
        VH.formContainer
        [ Element.paragraph []
            [ Element.text "Paste an "
            , VH.browserLink
                context
                "https://docs.openstack.org/newton/install-guide-rdo/keystone-openrc.html"
              <|
                View.Types.BrowserLinkTextLabel "OpenRC"
            , Element.text " file"
            ]
        , Input.multiline
            (VH.inputItemAttributes context.palette.background
                ++ [ Element.width Element.fill
                   , Element.height (Element.px 250)
                   , Font.size 12
                   ]
            )
            { onChange = InputOpenRc
            , text = model.openRc
            , placeholder = Nothing
            , label = Input.labelLeft [] Element.none
            , spellcheck = False
            }
        ]


loginPickerButton : View.Types.Context -> Element.Element Msg
loginPickerButton context =
    Element.link
        []
        -- TODO this needs a path prefix?
        { url = "/loginpicker"
        , label =
            Widget.textButton
                (SH.materialStyle context.palette).button
                { text = "Other Login Methods"
                , onPress =
                    Just NoOp
                }
        }
