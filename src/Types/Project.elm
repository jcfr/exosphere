module Types.Project exposing (Endpoints, Project, ProjectName, ProjectSecret(..), ProjectTitle)

import Helpers.RemoteDataPlusPlus as RDPP
import OpenStack.DnsRecordSet
import OpenStack.Types as OSTypes
import OpenStack.VolumeSnapshots exposing (VolumeSnapshot)
import RemoteData exposing (WebData)
import Types.Error exposing (HttpErrorWithBody)
import Types.HelperTypes as HelperTypes
import Types.Jetstream2Accounting
import Types.Server exposing (Server)



{- Project types -}


type alias Project =
    { secret : ProjectSecret
    , auth : OSTypes.ScopedAuthToken
    , region : Maybe OSTypes.Region
    , endpoints : Endpoints
    , description : Maybe String
    , images : RDPP.RemoteDataPlusPlus HttpErrorWithBody (List OSTypes.Image)
    , servers : RDPP.RemoteDataPlusPlus HttpErrorWithBody (List Server)
    , shares : RDPP.RemoteDataPlusPlus HttpErrorWithBody (List OSTypes.Share)
    , flavors : List OSTypes.Flavor
    , keypairs : RDPP.RemoteDataPlusPlus HttpErrorWithBody (List OSTypes.Keypair)
    , volumes : WebData (List OSTypes.Volume)
    , volumeSnapshots : RDPP.RemoteDataPlusPlus HttpErrorWithBody (List VolumeSnapshot)
    , networks : RDPP.RemoteDataPlusPlus HttpErrorWithBody (List OSTypes.Network)
    , autoAllocatedNetworkUuid : RDPP.RemoteDataPlusPlus HttpErrorWithBody OSTypes.NetworkUuid
    , floatingIps : RDPP.RemoteDataPlusPlus HttpErrorWithBody (List OSTypes.FloatingIp)
    , dnsRecordSets : RDPP.RemoteDataPlusPlus HttpErrorWithBody (List OpenStack.DnsRecordSet.DnsRecordSet)
    , ports : RDPP.RemoteDataPlusPlus HttpErrorWithBody (List OSTypes.Port)
    , securityGroups : RDPP.RemoteDataPlusPlus HttpErrorWithBody (List OSTypes.SecurityGroup)
    , computeQuota : RDPP.RemoteDataPlusPlus HttpErrorWithBody OSTypes.ComputeQuota
    , volumeQuota : RDPP.RemoteDataPlusPlus HttpErrorWithBody OSTypes.VolumeQuota
    , networkQuota : RDPP.RemoteDataPlusPlus HttpErrorWithBody OSTypes.NetworkQuota
    , jetstream2Allocations : RDPP.RemoteDataPlusPlus HttpErrorWithBody (List Types.Jetstream2Accounting.Allocation)
    }


type ProjectSecret
    = ApplicationCredential OSTypes.ApplicationCredential
    | NoProjectSecret


type alias Endpoints =
    { cinder : HelperTypes.Url
    , glance : HelperTypes.Url
    , keystone : HelperTypes.Url
    , manila : Maybe HelperTypes.Url
    , nova : HelperTypes.Url
    , neutron : HelperTypes.Url
    , jetstream2Accounting : Maybe HelperTypes.Url
    , designate : Maybe HelperTypes.Url
    }


type alias ProjectName =
    String


type alias ProjectTitle =
    String
