module View.ResourceUsageCharts exposing (charts)

import Color
import Dict
import Element
import LineChart
import LineChart.Area as Area
import LineChart.Axis as Axis
import LineChart.Axis.Intersection as Intersection
import LineChart.Axis.Line as AxisLine
import LineChart.Axis.Range as Range
import LineChart.Axis.Tick as Tick
import LineChart.Axis.Ticks as Ticks
import LineChart.Axis.Title as Title
import LineChart.Container as Container
import LineChart.Dots as Dots
import LineChart.Events as Events
import LineChart.Grid as Grid
import LineChart.Interpolation as Interpolation
import LineChart.Junk as Junk
import LineChart.Legends as Legends
import LineChart.Line as Line
import Time
import Tuple
import Types.ServerResourceUsage exposing (DataPoint, TimeSeries)
import Types.Types exposing (Msg)
import View.Helpers as VH


charts : ( Time.Posix, Time.Zone ) -> TimeSeries -> Element.Element Msg
charts ( currentTime, timeZone ) timeSeriesDict =
    let
        timeSeriesList =
            Dict.toList timeSeriesDict

        timeSeriesListLast30m =
            let
                thirtyMinMillis =
                    1800000

                thirtyMinAgo =
                    Time.posixToMillis currentTime - thirtyMinMillis
            in
            List.filter (\t -> Tuple.first t > thirtyMinAgo) timeSeriesList

        getTime : ( Int, DataPoint ) -> Float
        getTime dataPointTuple =
            Tuple.first dataPointTuple
                |> toFloat

        getMetricUsedPct : (DataPoint -> Int) -> ( Int, DataPoint ) -> Float
        getMetricUsedPct accessor dataPointTuple =
            Tuple.second dataPointTuple
                |> accessor
                |> toFloat

        percentRange getDataFunc =
            let
                ticks =
                    Ticks.custom <|
                        \_ _ ->
                            [ Tick.int 0
                            , Tick.int 25
                            , Tick.int 50
                            , Tick.int 75
                            , Tick.int 100
                            ]
            in
            Axis.custom
                { title = Title.default "Percent"
                , variable = Just << getDataFunc
                , pixels = 220
                , range = Range.window 0 100
                , axisLine = AxisLine.full Color.black
                , ticks = ticks
                }

        timeRange getDataFunc =
            Axis.custom
                { title = Title.default ""
                , variable = Just << getDataFunc
                , pixels = 550
                , range = Range.default
                , axisLine = AxisLine.full Color.black
                , ticks = Ticks.time timeZone 6
                }

        chartConfig : (( Int, DataPoint ) -> Float) -> LineChart.Config ( Int, DataPoint ) msg
        chartConfig getYData =
            { y = percentRange getYData
            , x = timeRange getTime
            , container = Container.spaced "line-chart-1" 40 20 40 70
            , interpolation = Interpolation.monotone
            , intersection = Intersection.default
            , legends = Legends.none
            , events = Events.default
            , junk = Junk.default
            , grid = Grid.default
            , area = Area.default
            , line = Line.default
            , dots = Dots.default
            }

        series : List (LineChart.Series ( Int, DataPoint ))
        series =
            [ LineChart.line
                (Color.rgb255 0 108 163)
                Dots.circle
                ""
                timeSeriesListLast30m
            ]
    in
    Element.column VH.exoColumnAttributes
        [ Element.el VH.heading4 (Element.text "CPU Usage")
        , Element.html <|
            LineChart.viewCustom (chartConfig (getMetricUsedPct .cpuPctUsed)) series
        , Element.el VH.heading4 (Element.text "Memory Usage")
        , Element.html <|
            LineChart.viewCustom (chartConfig (getMetricUsedPct .memPctUsed)) series
        , Element.el VH.heading4 (Element.text "Root Filesystem Usage")
        , Element.html <|
            LineChart.viewCustom (chartConfig (getMetricUsedPct .rootfsPctUsed)) series
        ]
