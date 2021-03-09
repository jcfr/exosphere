module View.QuotaUsage exposing (dashboard)

import Element
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import OpenStack.Types as OSTypes
import RemoteData exposing (RemoteData(..), WebData)
import Style.Helpers as SH
import Types.Types
    exposing
        ( Msg(..)
        , Project
        )
import View.Helpers as VH
import View.Types


dashboard : View.Types.ViewContext -> Project -> Element.Element Msg
dashboard context project =
    Element.column
        (VH.exoColumnAttributes ++ [ Element.width Element.fill ])
        [ Element.el VH.heading2 <| Element.text "Quota/Usage"
        , quotaSections context project
        ]


quotaSections : View.Types.ViewContext -> Project -> Element.Element Msg
quotaSections context project =
    Element.column
        (VH.exoColumnAttributes ++ [ Element.width Element.fill ])
        [ computeQuota context project
        , volumeQuota context project

        -- networkQuota stuff - whenever I find that
        ]


infoItem : View.Types.ViewContext -> { inUse : Int, limit : Maybe Int } -> ( String, String ) -> Element.Element Msg
infoItem context detail ( label, units ) =
    let
        labelLimit m_ =
            m_
                |> Maybe.map labelUse
                |> Maybe.withDefault "N/A"

        labelUse i_ =
            String.fromInt i_

        bg =
            Background.color <| SH.toElementColor context.palette.surface

        border =
            Border.rounded 5

        pad =
            Element.paddingXY 4 2
    in
    Element.row
        (VH.exoRowAttributes ++ [ Element.width Element.fill ])
        [ Element.el [ Font.bold ] <|
            Element.text label
        , Element.el [ bg, border, pad ] <|
            Element.text (labelUse detail.inUse)
        , Element.el [] <|
            Element.text "of"
        , Element.el [ bg, border, pad ] <|
            Element.text (labelLimit detail.limit)
        , Element.el [ Font.italic ] <|
            Element.text units
        ]


computeQuota : View.Types.ViewContext -> Project -> Element.Element Msg
computeQuota context project =
    Element.column
        (VH.exoColumnAttributes ++ [ Element.width Element.fill ])
        [ Element.el VH.heading3 <| Element.text "Compute"
        , computeQuotaDetails context project.computeQuota
        ]


computeInfoItems : View.Types.ViewContext -> OSTypes.ComputeQuota -> Element.Element Msg
computeInfoItems context quota =
    Element.column
        (VH.exoColumnAttributes ++ [ Element.width Element.fill ])
        [ infoItem context quota.cores ( "Cores:", "total" )
        , infoItem context quota.instances ( "Instances:", "total" )
        , infoItem context quota.ram ( "RAM:", "MB" )
        ]


quotaDetail : WebData q -> (q -> Element.Element Msg) -> Element.Element Msg
quotaDetail quota infoItemsF =
    case quota of
        NotAsked ->
            Element.el [] <| Element.text "Quota data loading ..."

        Loading ->
            Element.el [] <| Element.text "Quota data still loading ..."

        Failure _ ->
            Element.el [] <| Element.text "Quota data could not be loaded ..."

        Success quota_ ->
            infoItemsF quota_


computeQuotaDetails : View.Types.ViewContext -> WebData OSTypes.ComputeQuota -> Element.Element Msg
computeQuotaDetails context quota =
    Element.row
        (VH.exoRowAttributes ++ [ Element.width Element.fill ])
        [ quotaDetail quota (computeInfoItems context) ]


volumeQuota : View.Types.ViewContext -> Project -> Element.Element Msg
volumeQuota context project =
    Element.column
        (VH.exoColumnAttributes ++ [ Element.width Element.fill ])
        [ Element.el VH.heading3 <| Element.text "Volumes"
        , volumeQuoteDetails context project.volumeQuota
        ]


volumeInfoItems : View.Types.ViewContext -> OSTypes.VolumeQuota -> Element.Element Msg
volumeInfoItems context quota =
    Element.column
        (VH.exoColumnAttributes ++ [ Element.width Element.fill ])
        [ infoItem context quota.gigabytes ( "Storage:", "GB" )
        , infoItem context quota.volumes ( "Volumes:", "total" )
        ]


volumeQuoteDetails : View.Types.ViewContext -> WebData OSTypes.VolumeQuota -> Element.Element Msg
volumeQuoteDetails context quota =
    Element.row
        (VH.exoRowAttributes ++ [ Element.width Element.fill ])
        [ quotaDetail quota (volumeInfoItems context) ]
