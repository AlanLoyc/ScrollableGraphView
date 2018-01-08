//
//  ReferenceLabelView.swift
//  GraphView
//
//  Created by Alan Lo on 8/1/2018.
//

import UIKit

class ReferenceLabelView: UIView {

    private var leftLabelInset: CGFloat = 10
    private var rightLabelInset: CGFloat = 10

    private var topMargin: CGFloat = 10
    private var bottomMargin: CGFloat = 10

    private var maxDecimalDigit: Int = 5
    private var maxFloatingDigit: Int = 2

    var settings: ReferenceLines = ReferenceLines()
    var labels = [UILabel]()

    private var currentRange: (min: Double, max: Double) = (0, 100)

    init(frame: CGRect, referenceLineSettings: ReferenceLines, topMargin: CGFloat, bottomMargin: CGFloat) {
        super.init(frame: frame)

        self.topMargin = topMargin
        self.bottomMargin = bottomMargin

        self.settings = referenceLineSettings

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        let viewWidth = self.maxViewWidth()
        let viewStart = self.frame.width - viewWidth

        let frame = CGRect(x: viewStart, y: self.bounds.origin.y, width: viewWidth, height: self.bounds.size.height)

        self.frame = frame
    }

    private func createLabels() {

        for label in labels {
            label.removeFromSuperview()
        }
        labels.removeAll()

        let labelFrame = CGRect(x: 0, y: topMargin, width: self.frame.width, height: self.bounds.size.height - (topMargin + bottomMargin))

        if self.settings.includeMinLabel {
            createLabel(atPosition: self.bounds.size.height - bottomMargin)
        }

        if self.settings.includeMaxLabel {
            createLabel(atPosition: topMargin)
        }

        switch(settings.positionType) {
        case .relative:
            createLabels(in: labelFrame, atRelativePositions: self.settings.relativePositions)
        default:
            // Not implemented
            break
        }
    }

    private func createLabels(in rect: CGRect, atRelativePositions relativePositions: [Double]) {

        let height = rect.size.height
        var relativePositions = relativePositions

        // If we are including the min and max already need to make sure we don't redraw them.
        if(self.settings.includeMinLabel || self.settings.includeMaxLabel) {
            relativePositions = relativePositions.filter({ (x: Double) -> Bool in
                if(settings.includeMin && settings.includeMax) {
                    return (x != 0 && x != 1)
                } else if(settings.includeMin) {
                    return x != 0
                } else {
                    return x != 1
                }
            })
        }

        for relativePosition in relativePositions {
            let yPosition = height * CGFloat(1 - relativePosition) + rect.origin.y
            createLabel(atPosition: yPosition)
        }
    }

    private func createLabel(in rect: CGRect, atAbsolutePositions absolutePositions: [Double], forPath path: UIBezierPath) {

        for absolutePosition in absolutePositions {
            let yPosition = calculateYPositionForYAxisValue(value: absolutePosition)
            createLabel(atPosition: yPosition)
        }
    }

    private func createLabel(atPosition: CGFloat) {
        if(self.settings.shouldAddLabelsToIntermediateReferenceLines) {

            let numberFormatter = referenceNumberFormatter()
            let value = calculateYAxisValue(value: atPosition)
            let valueString = numberFormatter.string(from: value as NSNumber)!

            let boundingSize = self.boundingSize(forText: valueString)
            let rightLabel = createLabel(withText: valueString)

            rightLabel.frame = CGRect(
                origin: CGPoint(x: rightLabelInset, y: atPosition - (boundingSize.height / 2)),
                size: boundingSize)

            switch self.settings.referenceLinePosition {
            case .right:
                labels.append(rightLabel)
                self.addSubview(rightLabel)
            default:
                break
            }
        }
    }

    private func boundingSize(forText text: String) -> CGSize {
        return (text as NSString).size(withAttributes: [NSAttributedStringKey.font: self.settings.referenceLineLabelFont])
    }

    private func maxViewWidth() -> CGFloat {
        var dummyString = String.init(repeating: "9", count: (maxDecimalDigit + maxFloatingDigit))
        dummyString.append(".")
        return self.boundingSize(forText: dummyString).width
    }

    private func referenceNumberFormatter() -> NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = self.settings.referenceLineNumberStyle
        numberFormatter.minimumFractionDigits = self.settings.referenceLineNumberOfDecimalPlaces
        numberFormatter.maximumFractionDigits = self.settings.referenceLineNumberOfDecimalPlaces

        return numberFormatter
    }

    private func createLabel(withText text: String) -> UILabel {
        let label = UILabel()

        label.text = text
        label.textColor = self.settings.referenceLineLabelColor
        label.font = self.settings.referenceLineLabelFont

        return label
    }

    private func calculateYPositionForYAxisValue(value: Double) -> CGFloat {

        // Just an algebraic re-arrangement of calculateYAxisValue
        let graphHeight = self.frame.size.height - (topMargin + bottomMargin)
        var y = ((CGFloat(value - self.currentRange.max) / CGFloat(self.currentRange.min - self.currentRange.max)) * graphHeight) + topMargin

        if (y == 0) {
            y = 0
        }

        return y
    }

    private func calculateYAxisValue(value: CGFloat) -> Double {

        let graphHeight = self.frame.size.height - (topMargin + bottomMargin)

        var value = (((value - topMargin) / (graphHeight)) * CGFloat((self.currentRange.min - self.currentRange.max))) + CGFloat(self.currentRange.max)

        // Sometimes results in "negative zero"
        if(value == 0) {
            value = 0
        }

        return Double(value)
    }

    func set(range: (min: Double, max: Double)) {
        self.currentRange = range
        self.createLabels()
    }

    func set(viewportWidth: CGFloat, viewportHeight: CGFloat) {
        //self.frame.origin.x = viewportWidth - maxViewWidth()
        //self.frame.size.width = viewportWidth
        //self.frame.size.height = viewportHeight
    }
}
