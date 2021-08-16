module Types.OuterMsg exposing (OuterMsg(..))

import Page.FloatingIpAssign
import Page.FloatingIpList
import Page.GetSupport
import Page.KeypairCreate
import Page.KeypairList
import Page.LoginJetstream
import Page.LoginOpenstack
import Page.LoginPicker
import Page.MessageLog
import Page.SelectProjects
import Page.Settings
import Page.VolumeCreate
import Types.HelperTypes as HelperTypes
import Types.SharedMsg
import Types.View as ViewTypes


type OuterMsg
    = SetNonProjectView ViewTypes.NonProjectViewConstructor
    | SetProjectView HelperTypes.ProjectIdentifier ViewTypes.ProjectViewConstructor
    | SharedMsg Types.SharedMsg.SharedMsg
    | LoginOpenstackMsg Page.LoginOpenstack.Msg
    | LoginJetstreamMsg Page.LoginJetstream.Msg
    | MessageLogMsg Page.MessageLog.Msg
    | SettingsMsg Page.Settings.Msg
    | GetSupportMsg Page.GetSupport.Msg
    | LoginPickerMsg Page.LoginPicker.Msg
    | SelectProjectsMsg Page.SelectProjects.Msg
    | FloatingIpListMsg Page.FloatingIpList.Msg
    | FloatingIpAssignMsg Page.FloatingIpAssign.Msg
    | KeypairListMsg Page.KeypairList.Msg
    | KeypairCreateMsg Page.KeypairCreate.Msg
    | VolumeCreateMsg Page.VolumeCreate.Msg
