module Rest.Glance exposing
    ( receiveDeleteImage
    , receiveImages
    , requestDeleteImage
    , requestImages
    )

import Dict
import Helpers.GetterSetters as GetterSetters
import Helpers.RemoteDataPlusPlus as RDPP
import Helpers.Url as UrlHelpers
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import OpenStack.Types as OSTypes
import Rest.Helpers exposing (expectJsonWithErrorBody, openstackCredentialedRequest, resultToMsgErrorBody)
import Types.Error exposing (ErrorContext, ErrorLevel(..))
import Types.HelperTypes exposing (HttpRequestMethod(..), MetadataFilter)
import Types.Project exposing (Project)
import Types.SharedModel exposing (SharedModel)
import Types.SharedMsg exposing (ProjectSpecificMsgConstructor(..), SharedMsg(..))



{- HTTP Requests -}


requestImages : SharedModel -> Project -> Cmd SharedMsg
requestImages model project =
    let
        projectKeystoneHostname =
            UrlHelpers.hostnameFromUrl project.endpoints.keystone

        maybeExcludeFilter : Maybe MetadataFilter
        maybeExcludeFilter =
            Dict.get projectKeystoneHostname model.viewContext.cloudSpecificConfigs
                |> Maybe.andThen (\csc -> csc.imageExcludeFilter)

        errorContext =
            ErrorContext
                ("get a list of images for project \"" ++ project.auth.project.name ++ "\"")
                ErrorCrit
                Nothing

        resultToMsg_ =
            resultToMsgErrorBody
                errorContext
                (\images -> ProjectMsg (GetterSetters.projectIdentifier project) <| ReceiveImages images)
    in
    openstackCredentialedRequest
        (GetterSetters.projectIdentifier project)
        Get
        Nothing
        (project.endpoints.glance ++ "/v2/images?limit=999999")
        Http.emptyBody
        (expectJsonWithErrorBody
            resultToMsg_
            (decodeImages maybeExcludeFilter)
        )


requestDeleteImage : Project -> OSTypes.ImageUuid -> Cmd SharedMsg
requestDeleteImage project imageUuid =
    let
        errorContext =
            ErrorContext
                ("delete image with UUID " ++ imageUuid)
                ErrorCrit
                Nothing

        resultToMsg_ =
            resultToMsgErrorBody
                errorContext
                (\_ ->
                    ProjectMsg
                        project.auth.project.uuid
                        (ReceiveDeleteImage imageUuid)
                )
    in
    openstackCredentialedRequest
        project.auth.project.uuid
        Delete
        Nothing
        (project.endpoints.glance ++ "/v2/images/" ++ imageUuid)
        Http.emptyBody
        (Rest.Helpers.expectStringWithErrorBody
            resultToMsg_
        )



{- HTTP Response Handling -}


receiveImages : SharedModel -> Project -> List OSTypes.Image -> ( SharedModel, Cmd SharedMsg )
receiveImages model project images =
    let
        newProject =
            { project
                | images =
                    RDPP.RemoteDataPlusPlus
                        (RDPP.DoHave images model.clientCurrentTime)
                        (RDPP.NotLoading Nothing)
            }

        newModel =
            GetterSetters.modelUpdateProject model newProject
    in
    ( newModel, Cmd.none )


receiveDeleteImage : SharedModel -> Project -> OSTypes.IpAddressUuid -> ( SharedModel, Cmd SharedMsg )
receiveDeleteImage model project imageUuid =
    case project.images.data of
        RDPP.DoHave images _ ->
            let
                newImages =
                    List.filter (\i -> i.uuid /= imageUuid) images

                newProject =
                    { project
                        | images =
                            RDPP.RemoteDataPlusPlus
                                (RDPP.DoHave newImages model.clientCurrentTime)
                                (RDPP.NotLoading Nothing)
                    }

                newModel =
                    GetterSetters.modelUpdateProject model newProject
            in
            ( newModel, Cmd.none )

        _ ->
            ( model, Cmd.none )



{- JSON Decoders -}


catMaybes : List (Maybe a) -> List a
catMaybes =
    List.filterMap identity


decodeImages : Maybe MetadataFilter -> Decode.Decoder (List OSTypes.Image)
decodeImages maybeExcludeFilter =
    Decode.field "images" (Decode.map catMaybes (Decode.list <| imageDecoder maybeExcludeFilter))


decodeAdditionalProperties : List String -> Decode.Decoder (Dict.Dict String String)
decodeAdditionalProperties basePropertyNames =
    let
        fromBool val =
            if val then
                "True"

            else
                "False"

        asString =
            Decode.oneOf
                [ Decode.string
                , Decode.map String.fromInt Decode.int
                , Decode.map String.fromFloat Decode.float
                , Decode.map fromBool Decode.bool
                , Decode.null ""
                , Decode.succeed "IGNORE"
                ]
    in
    Decode.dict asString
        |> Decode.map
            (\someDict ->
                Dict.filter (\k _ -> not (List.member k basePropertyNames)) someDict
            )


imageDecoder : Maybe MetadataFilter -> Decode.Decoder (Maybe OSTypes.Image)
imageDecoder maybeExcludeFilter =
    case maybeExcludeFilter of
        Nothing ->
            Decode.map Just imageDecoderHelper

        Just excludeFilter ->
            Decode.andThen
                (\maybeFilterValue ->
                    case maybeFilterValue of
                        Nothing ->
                            Decode.map Just imageDecoderHelper

                        Just filterValue ->
                            if filterValue == excludeFilter.filterValue then
                                Decode.succeed Nothing

                            else
                                Decode.map Just imageDecoderHelper
                )
                (Decode.maybe (Decode.field excludeFilter.filterKey Decode.string))


imageDecoderHelper : Decode.Decoder OSTypes.Image
imageDecoderHelper =
    let
        -- Currently hard-coded. TODO: Load these from Glance image schema endpoint
        basePropertyNames =
            [ "architecture"
            , "backend"
            , "checksum"
            , "container_format"
            , "created_at"
            , "direct_url"
            , "disk_format"
            , "file"
            , "id"
            , "instance_uuid"
            , "kernel_id"
            , "locations"
            , "min_disk"
            , "min_ram"
            , "name"
            , "os_distro"
            , "os_hash_algo"
            , "os_hash_value"
            , "os_hidden"
            , "os_version"
            , "owner"
            , "protected"
            , "ramdisk_id"
            , "schema"
            , "self"
            , "size"
            , "status"
            , "tags"
            , "updated_at"
            , "virtual_size"
            , "visibility"
            ]
    in
    Decode.succeed
        OSTypes.Image
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "status" (Decode.string |> Decode.andThen imageStatusDecoder)
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "size" (Decode.oneOf [ Decode.int, Decode.null 0 ] |> Decode.andThen (\i -> Decode.succeed <| Just i))
        |> Pipeline.optional "checksum" (Decode.string |> Decode.andThen (\s -> Decode.succeed <| Just s)) Nothing
        |> Pipeline.optional "disk_format" (Decode.string |> Decode.andThen (\s -> Decode.succeed <| Just s)) Nothing
        |> Pipeline.optional "container_format" (Decode.string |> Decode.andThen (\s -> Decode.succeed <| Just s)) Nothing
        |> Pipeline.required "tags" (Decode.list Decode.string)
        |> Pipeline.required "owner" Decode.string
        |> Pipeline.required "visibility" (Decode.string |> Decode.andThen imageVisibilityDecoder)
        |> Pipeline.custom (decodeAdditionalProperties basePropertyNames)
        |> Pipeline.required "created_at" (Decode.string |> Decode.andThen Rest.Helpers.iso8601StringToPosixDecodeError)
        |> Pipeline.optional "os_distro" (Decode.string |> Decode.andThen (\s -> Decode.succeed <| Just s)) Nothing
        |> Pipeline.optional "os_version" (Decode.string |> Decode.andThen (\s -> Decode.succeed <| Just s)) Nothing
        |> Pipeline.required "protected" Decode.bool


imageVisibilityDecoder : String -> Decode.Decoder OSTypes.ImageVisibility
imageVisibilityDecoder visibility =
    case visibility of
        "public" ->
            Decode.succeed OSTypes.ImagePublic

        "community" ->
            Decode.succeed OSTypes.ImageCommunity

        "shared" ->
            Decode.succeed OSTypes.ImageShared

        "private" ->
            Decode.succeed OSTypes.ImagePrivate

        _ ->
            Decode.fail "Unrecognized image visibility value"


imageStatusDecoder : String -> Decode.Decoder OSTypes.ImageStatus
imageStatusDecoder status =
    case status of
        "queued" ->
            Decode.succeed OSTypes.ImageQueued

        "saving" ->
            Decode.succeed OSTypes.ImageSaving

        "active" ->
            Decode.succeed OSTypes.ImageActive

        "killed" ->
            Decode.succeed OSTypes.ImageKilled

        "deleted" ->
            Decode.succeed OSTypes.ImageDeleted

        "pending_delete" ->
            Decode.succeed OSTypes.ImagePendingDelete

        "deactivated" ->
            Decode.succeed OSTypes.ImageDeactivated

        _ ->
            Decode.fail "Unrecognized image status"
