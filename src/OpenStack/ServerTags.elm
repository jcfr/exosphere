module OpenStack.ServerTags exposing (requestCreateServerTag)

import Error exposing (ErrorContext, ErrorLevel(..))
import Http
import OpenStack.Types as OSTypes
import Rest.Helpers exposing (openstackCredentialedRequest, resultToMsg)
import Types.Types exposing (HttpRequestMethod(..), Msg(..), Project)


requestCreateServerTag : Project -> OSTypes.ServerUuid -> String -> Cmd Msg
requestCreateServerTag project serverUuid tag =
    let
        errorContext =
            ErrorContext
                ("create a server tag for server with UUID" ++ serverUuid)
                ErrorCrit
                Nothing
    in
    openstackCredentialedRequest
        project
        Put
        (Just "compute 2.26")
        (project.endpoints.nova ++ "/servers/" ++ serverUuid ++ "/tags/" ++ tag)
        Http.emptyBody
        (Http.expectString
            (resultToMsg errorContext (\_ -> NoOp))
        )
