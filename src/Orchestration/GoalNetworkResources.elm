module Orchestration.GoalNetworkResources exposing (goalPollNetworkResources)

import Helpers.GetterSetters as GetterSetters
import Orchestration.Helpers exposing (applyProjectStep, pollRDPP)
import Rest.Neutron
import Time
import Types.Types
    exposing
        ( CloudSpecificConfig
        , ExoSetupStatus(..)
        , FloatingIpAssignmentStatus(..)
        , FloatingIpOption(..)
        , FloatingIpReuseOption(..)
        , Msg(..)
        , Project
        , ProjectSpecificMsgConstructor(..)
        , Server
        , ServerFromExoProps
        , ServerOrigin(..)
        , ServerSpecificMsgConstructor(..)
        , UserAppProxyHostname
        )


goalPollNetworkResources : Time.Posix -> Project -> ( Project, Cmd Msg )
goalPollNetworkResources time project =
    let
        steps =
            [ stepPollFloatingIps time
            , stepPollPorts time
            ]

        ( newProject, newCmds ) =
            List.foldl
                applyProjectStep
                ( project, Cmd.none )
                steps
    in
    ( newProject, newCmds )


stepPollFloatingIps : Time.Posix -> Project -> ( Project, Cmd Msg )
stepPollFloatingIps time project =
    let
        requestStuff =
            ( GetterSetters.projectSetFloatingIpsLoading time project
            , Rest.Neutron.requestFloatingIps project
            )

        pollIntervalMs =
            120000
    in
    if pollRDPP project.floatingIps time pollIntervalMs then
        ( project, Cmd.none )

    else
        requestStuff


stepPollPorts : Time.Posix -> Project -> ( Project, Cmd Msg )
stepPollPorts time project =
    let
        requestStuff =
            ( GetterSetters.projectSetPortsLoading time project
            , Rest.Neutron.requestPorts project
            )

        pollIntervalMs =
            120000
    in
    if pollRDPP project.ports time pollIntervalMs then
        requestStuff

    else
        ( project, Cmd.none )
