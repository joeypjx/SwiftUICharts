//
//  StackedBarChartData.swift
//  
//
//  Created by Will Dale on 12/02/2021.
//

import SwiftUI

/**
 Data model for drawing and styling a Stacked Bar Chart.
 
 The grouping data informs the model as to how the datapoints are linked.
 */
public final class StackedBarChartData: CTMultiBarChartDataProtocol {
    
    // MARK: Properties
    public let id: UUID = UUID()
    
    @Published public final var dataSets: StackedBarDataSets
    @Published public final var metadata: ChartMetadata
    @Published public final var xAxisLabels: [String]?
    @Published public final var yAxisLabels: [String]?
    @Published public final var barStyle: BarStyle
    @Published public final var chartStyle: BarChartStyle
    @Published public final var legends: [LegendData]
    @Published public final var viewData: ChartViewData
    @Published public final var infoView: InfoViewData<StackedBarDataPoint> = InfoViewData()
    @Published public final var groups: [GroupingData]
    
    public final var noDataText: Text
    public final var chartType: (chartType: ChartType, dataSetType: DataSetType)
    
    // MARK: Initializer
    /// Initialises a Stacked Bar Chart.
    ///
    /// - Parameters:
    ///   - dataSets: Data to draw and style the bars.
    ///   - groups: Information for how to group the data points.
    ///   - metadata: Data model containing the charts Title, Subtitle and the Title for Legend.
    ///   - xAxisLabels: Labels for the X axis instead of the labels in the data points.
    ///   - yAxisLabels: Labels for the Y axis instead of the labels generated from data point values.   
    ///   - barStyle: Control for the aesthetic of the bar chart.
    ///   - chartStyle: The style data for the aesthetic of the chart.
    ///   - noDataText: Customisable Text to display when where is not enough data to draw the chart.
    public init(
        dataSets: StackedBarDataSets,
        groups: [GroupingData],
        metadata: ChartMetadata = ChartMetadata(),
        xAxisLabels: [String]? = nil,
        yAxisLabels: [String]? = nil,
        barStyle: BarStyle = BarStyle(),
        chartStyle: BarChartStyle = BarChartStyle(),
        noDataText: Text = Text("No Data")
    ) {
        self.dataSets = dataSets
        self.groups = groups
        self.metadata = metadata
        self.xAxisLabels = xAxisLabels
        self.yAxisLabels = yAxisLabels
        self.barStyle = barStyle
        self.chartStyle = chartStyle
        self.noDataText = noDataText
        self.legends = [LegendData]()
        self.viewData = ChartViewData()
        self.chartType = (chartType: .bar, dataSetType: .multi)
        self.setupLegends()
    }

    
    // MARK:  Touch
    public final func getTouchInteraction(touchLocation: CGPoint, chartSize: CGRect) -> some View {
        self.markerSubView()
    }
    
    public final func getDataPoint(touchLocation: CGPoint, chartSize: CGRect) {
        // Filter to get the right dataset based on the x axis.
        let superXSection: CGFloat = chartSize.width / CGFloat(dataSets.dataSets.count)
        let superIndex: Int = Int((touchLocation.x) / superXSection)
        if superIndex >= 0 && superIndex < dataSets.dataSets.count {
            // Filter to get the right dataset based on the y axis.
            let calculatedIndex = calculateIndex(dataSet: dataSets.dataSets[superIndex], touchLocation: touchLocation, chartSize: chartSize)
            if let index = calculatedIndex.yIndex?.offset {
                if index >= 0 && index < dataSets.dataSets[superIndex].dataPoints.count {
                    dataSets.dataSets[superIndex].dataPoints[index].legendTag = dataSets.dataSets[superIndex].setTitle
                    self.infoView.touchOverlayInfo = [dataSets.dataSets[superIndex].dataPoints[index]]
                }
            }
        }
    }
    
    public final func getPointLocation(dataSet: StackedBarDataSets, touchLocation: CGPoint, chartSize: CGRect) -> CGPoint? {
        // Filter to get the right dataset based on the x axis.
        let superXSection: CGFloat = chartSize.width / CGFloat(dataSet.dataSets.count)
        let superIndex: Int = Int((touchLocation.x) / superXSection)
        if superIndex >= 0 && superIndex < dataSet.dataSets.count {
            // Filter to get the right dataset based on the y axis.
            let subDataSet = dataSet.dataSets[superIndex]
            let calculatedIndex = calculateIndex(dataSet: subDataSet, touchLocation: touchLocation, chartSize: chartSize)
            if let index = calculatedIndex.yIndex?.offset {
                if index >= 0 && index < subDataSet.dataPoints.count {
                    return CGPoint(x: (CGFloat(superIndex) * superXSection) + (superXSection / 2),
                                   y: (chartSize.height - calculatedIndex.endPointOfElements[index]))
                }
            }
        }
        return nil
    }
    
    private final func calculateIndex(
        dataSet: StackedBarDataSet,
        touchLocation: CGPoint,
        chartSize: CGRect
    ) -> (yIndex: EnumeratedSequence<[CGFloat]>.Element?, endPointOfElements: [CGFloat]) {
        
        // Get the max value of the dataset relative to max value of all datasets.
        // This is used to set the height of the y axis filtering.
        let setMaxValue = dataSet.maxValue()
        let allMaxValue = self.maxValue
        let fraction: CGFloat = CGFloat(setMaxValue / allMaxValue)
        
        // Gets the height of each datapoint
        let sum: Double = dataSet.dataPoints
            .map(\.value)
            .reduce(0, +)
        let heightOfElements: [CGFloat] = dataSet.dataPoints
            .map(\.value)
            .map { (chartSize.height * fraction) * CGFloat($0 / sum) }
        
        // Gets the highest point of each element.
        let endPointOfElements: [CGFloat] = heightOfElements
            .enumerated()
            .map {
                (0...$0.offset)
                    .map { heightOfElements[$0] }
                    .reduce(0, +)
            }
        
        let yIndex = endPointOfElements
            .enumerated()
            .first(where:) { $0.element > abs(touchLocation.y - chartSize.height) }
        
        return (yIndex, endPointOfElements)
    }
    
    public typealias Set = StackedBarDataSets
    public typealias DataPoint = StackedBarDataPoint
    public typealias CTStyle = BarChartStyle
}
