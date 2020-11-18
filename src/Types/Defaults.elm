module Types.Defaults exposing
    ( createServerViewParams
    , createVolumeView
    , imageListViewParams
    , jetstreamCreds
    , serverDetailViewParams
    , serverListViewParams
    , sortTableParams
    )

import ServerDeploy exposing (cloudInitUserDataTemplate)
import Set
import Style.Widgets.NumericTextInput.Types exposing (NumericTextInput(..))
import Types.Types as Types


jetstreamCreds : Types.JetstreamCreds
jetstreamCreds =
    { jetstreamProviderChoice = Types.BothJetstreamClouds
    , jetstreamProjectName = ""
    , taccUsername = ""
    , taccPassword = ""
    }


imageListViewParams : Types.ImageListViewParams
imageListViewParams =
    { searchText = ""
    , tags = Set.empty
    , onlyOwnImages = False
    , expandImageDetails = Set.empty
    }


sortTableParams : Types.SortTableParams
sortTableParams =
    { title = ""
    , asc = True
    }


serverListViewParams : Types.ServerListViewParams
serverListViewParams =
    { onlyOwnServers = True
    , selectedServers = Set.empty
    , deleteConfirmations = []
    }


serverDetailViewParams : Types.ServerDetailViewParams
serverDetailViewParams =
    { verboseStatus = False
    , passwordVisibility = Types.PasswordHidden
    , ipInfoLevel = Types.IPSummary
    , serverActionNamePendingConfirmation = Nothing
    , serverNamePendingConfirmation = Nothing
    , activeTooltip = Nothing
    }


createServerViewParams : String -> String -> Maybe Bool -> Types.CreateServerViewParams
createServerViewParams imageUuid imageName deployGuacamole =
    { serverName = imageName
    , imageUuid = imageUuid
    , imageName = imageName
    , count = 1
    , flavorUuid = ""
    , volSizeTextInput = Nothing
    , userDataTemplate = cloudInitUserDataTemplate
    , networkUuid = ""
    , showAdvancedOptions = False
    , keypairName = Nothing
    , deployGuacamole = deployGuacamole
    }


createVolumeView : Types.ProjectViewConstructor
createVolumeView =
    Types.CreateVolume "" (ValidNumericTextInput 10)
