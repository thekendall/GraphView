//
//  GraphView.swift
//  Grapher
//
//  Created by Kendall Lui on 3/31/16.
//  Copyright (c) 2016 Kendall Lui. All rights reserved.
//

import UIKit
@IBDesignable

class GraphView: UIView {
    
    private struct PlotData {
        var coordinates:[[Double]]
        var path:UIBezierPath
        var color: (Float,Float,Float)
    }
    
    
    // Drawing setting
    var axesStroke: CGFloat = 1 { didSet { setNeedsDisplay() } }
    @IBInspectable
    var axes_color: UIColor = UIColor.blueColor() { didSet { setNeedsDisplay() } }
    @IBInspectable
    var margin:Double = 20.0 { didSet { setNeedsDisplay() } }
    @IBInspectable
    var plot_color:UIColor = UIColor.redColor() { didSet { setNeedsDisplay() } }
    @IBInspectable
    var showAxes:Bool = true { didSet { setNeedsDisplay() } }
    @IBInspectable
    var showIncrementLabels:Bool = false { didSet { setNeedsDisplay() } }
    @IBInspectable
    var plotStroke:CGFloat = 1 { didSet{setNeedsDisplay()} }
    @IBInspectable
    
    var autoscaleAxis = true;
    
    private var plots = [Int: PlotData]()
    
    // Canvas Data
    private var screenWidth: CGFloat
        {
        get {
            return bounds.size.width
        }
    }
    
    private var screenHeight: CGFloat
        {
        get {
            return bounds.size.height
        }
    }
    
    // Graph Scaling
    var x_min:Double = -1
        {
        didSet{ replot() }
    }
    var x_max:Double = 1
        {
        didSet{ replot() }
    }
    var y_min:Double = -1
        {
        didSet{ replot() }
    }
    var y_max:Double = 1
        {
        didSet{ replot() }
    }
    var x_increment = 1.0;
    var y_increment = 1.0;
    
    //Keeping Track of Plot Shifts!
    var xShift:CGFloat = 0.0
    var yShift:CGFloat = 0.0
    
    //Plot with default values
    
    override func drawRect(rect: CGRect)
    {
        
        /*
        for( var i = 0; i < plotPaths.count; i++)
        {
        plotPaths[i].lineWidth = plotStroke;
        UIColor(colorLiteralRed: plotColors[i].0, green: plotColors[i].1, blue: plotColors[i].2, alpha: 1.0).set()
        plotPaths[i].stroke()
        }
        */
        
        if(showAxes) {
            let axesPath = bezierPathForAxes()
            axesPath.lineWidth = axesStroke
            axes_color.set()
            axesPath.stroke()
        }
        if(showIncrementLabels){ drawAxesLabels()};
        for (_, plot) in plots
        {
            UIColor(red: CGFloat(plot.color.0)/CGFloat(255), green: CGFloat(plot.color.1)/CGFloat(255), blue: CGFloat(plot.color.2)/CGFloat(255), alpha: 1).set()
            plot.path.stroke()
        }
        
    }
    
    func replot()
    {
        for (index, plot) in plots
        {
            let path = bezierPathForPlot(plot.coordinates[0], y_coors: plot.coordinates[1])
            let newPlot = PlotData(coordinates: plot.coordinates, path: path, color: plot.color)
            plots.updateValue(newPlot, forKey: index)
        }
        
        setNeedsDisplay()
    }
    func shiftPlots(x: Double, y: Double)
    {
        let xScale = Double ((screenWidth - CGFloat(margin*2)) / CGFloat(abs(x_max - x_min)))
        let yScale = Double((screenHeight - CGFloat(margin*2)) / CGFloat(abs(y_max - y_min)))
        xShift += CGFloat(xScale * x);
        yShift += CGFloat(yScale * y);
        for (index, _) in plots
        {
            plots[index]!.path.applyTransform(CGAffineTransformMakeTranslation(CGFloat(xScale * x), CGFloat(yScale * y)));
        }
        
        setNeedsDisplay()
    }
    
    func unshiftPlots()
    {
        for (index, _) in plots
        {
            plots[index]!.path.applyTransform(CGAffineTransformMakeTranslation(-xShift, -yShift));
        }

        xShift = 0.0;
        yShift = 0.0;
        setNeedsDisplay();
    }
    
    func scale(x: Double, y: Double)
    {
        let xScaled = CGFloat(x) * ((screenWidth - CGFloat(margin*2)) / CGFloat(abs(x_max - x_min)))
        let yScaled = CGFloat(y) * ((screenHeight - CGFloat(margin*2)) / CGFloat(abs(y_max - y_min)))

        for (index, _) in plots
        {
            plots[index]!.path.applyTransform(CGAffineTransformMakeScale(xScaled, yScaled));
        }
        setNeedsDisplay()
    }
    
    func maximize()
    { //maximize window
    }
    
    func addPlot(x_coors x_coors: [Double], y_coors: [Double], color: (Float,Float,Float)) -> Int //Plot index for tracking
    {
        let index = plots.count
        if(autoscaleAxis)
        {
            if(x_min > floor(x_coors.minElement()!)) {
                x_min = floor(x_coors.minElement()!)
            }
            if(x_max < ceil(x_coors.maxElement()!))
            {
                x_max = ceil(x_coors.maxElement()!)
            }
            
            if(y_min > floor(y_coors.minElement()!)) {
                y_min = floor(y_coors.minElement()!)
            }
            if(y_max < ceil(y_coors.maxElement()!))
            {
                y_max = ceil(y_coors.maxElement()!)
            }
            
        }
        plots[index] = PlotData(coordinates: [x_coors, y_coors], path: bezierPathForPlot(x_coors, y_coors: y_coors), color: color)
        setNeedsDisplay()
        return index
    }
    
    func removePlot(index: Int)
    {
        plots.removeValueForKey(index)
    }
    
    func addPointToPlotAtIndex(index: Int, x: Double, y:Double)
    {
        plots[index]?.coordinates[0].append(x)
        plots[index]?.coordinates[1].append(y)
        
        if(autoscaleAxis)
        {
            if(x_min > x) {
                x_min = floor(x)
            }
            if(x_max < x)
            {
                x_max = ceil(x)
            }
            if(y_min > y) {
                x_min = floor(x)
            }
            if(y_max < x)
            {
                y_max = ceil(x)
            }
        }
        plots[index]?.path.addLineToPoint(getPlotCoordinates(x, y: y))
        setNeedsDisplay()
    }
    
    func replacePlotAtIndex(index: Int, x: [Double], y:[Double])
    {
        plots[index]?.coordinates = [x,y]
        
        plots[index]?.path = bezierPathForPlot(x, y_coors: y)
    }
    
    
    private func bezierPathForAxes() -> UIBezierPath
    {
        let path = UIBezierPath()
        if(x_min > 0 || x_max < 0)
        {
            path.moveToPoint(getPlotCoordinates(x_min, y: y_min))
            path.addLineToPoint(getPlotCoordinates(x_min, y: y_max))
        } else {
            path.moveToPoint(getPlotCoordinates(0, y: y_min))
            path.addLineToPoint(getPlotCoordinates(0, y: y_max))
        }
        
        if(y_min > 0 || y_max < 0)
        {
            path.moveToPoint(getPlotCoordinates(x_min, y: y_min))
            path.addLineToPoint(getPlotCoordinates(x_max, y: y_min))
        } else {
            path.moveToPoint(getPlotCoordinates(x_min, y: 0))
            path.addLineToPoint(getPlotCoordinates(x_max, y: 0))
        }
        
        return path
    }
    
    private func drawAxesLabels()
    {
        for(var i = x_min; i <= x_max; i+=x_increment)
        {
            let label = UILabel(frame: bounds)
            label.center = getPlotCoordinates(i - 0.2, y: -0.2)
            label.textAlignment = NSTextAlignment.Center
            label.text = String(format: "%.1f", i)
            label.font = label.font.fontWithSize(5.0)
            label.textColor = axes_color
            self.addSubview(label)
            
        }
        for(var i = y_min; i <= y_max; i+=y_increment)
        {
            let label = UILabel(frame: bounds)
            label.center = getPlotCoordinates(0, y: i)
            label.center.x -= CGFloat(margin/2)
            label.textAlignment = NSTextAlignment.Center
            label.text = String(format: "%.1f", i)
            label.font = label.font.fontWithSize(5.0)
            label.textColor = axes_color
            self.addSubview(label)
        }
        
    }
    
    private func getPlotCoordinates(x: Double, y: Double) -> CGPoint
    {
        let xScale = (screenWidth - CGFloat(margin*2)) / CGFloat(abs(x_max - x_min))
        let yScale = (screenHeight - CGFloat(margin*2)) / CGFloat(abs(y_max - y_min))
        
        var x_coor: CGFloat;
        var y_coor: CGFloat = 0;
        
        x_coor = CGFloat((x-x_min))*xScale + CGFloat(margin) + xShift;
        y_coor = CGFloat((y_max-y_min)-(y-y_min))*yScale + CGFloat(margin) + yShift; //offset because y:0 is at top in ios coordinate axes
        
        return CGPoint(x: x_coor, y: y_coor)
    }
    
    private func bezierPathForPlot(x_coors :[Double], y_coors: [Double]) -> UIBezierPath
    {
        let path = UIBezierPath()
        path.moveToPoint(getPlotCoordinates(x_coors[0], y: y_coors[0]))
        for(var i = 1; i < x_coors.count; i++ )
        {
            path.addLineToPoint(getPlotCoordinates(x_coors[i], y: y_coors[i]))
        }
        return path;
    }
    
    //clears all plots
    func clearAllPlots(){
        for (index, _) in plots {
            removePlot(index)
        }
        xShift = 0.0
        yShift = 0.0
        setNeedsDisplay()
    }
    
}