// The MIT License (MIT)
//
// Copyright (c) 2015 Joakim Gyllström
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

/**
 Used as an overlay on selected cells
 */
@IBDesignable final class SelectionView: UIView {
    var selectionString: String = "" {
        didSet {
            if selectionString != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()
        
        //// Frames
        let checkmarkFrame = bounds;
        
        //// Subframes
        let group = CGRect(x: checkmarkFrame.minX + 3, y: checkmarkFrame.minY + 3, width: checkmarkFrame.width - 6, height: checkmarkFrame.height - 6)
        
        //// CheckedOval Drawing
        let checkedOvalPath = UIBezierPath(ovalIn: CGRect(x: group.minX + floor(group.width * 0.0 + 0.5), y: group.minY + floor(group.height * 0.0 + 0.5), width: floor(group.width * 1.0 + 0.5) - floor(group.width * 0.0 + 0.5), height: floor(group.height * 1.0 + 0.5) - floor(group.height * 0.0 + 0.5)))
        context?.saveGState()
        
        UIView().tintColor.setFill()
        checkedOvalPath.fill()
        context?.restoreGState()
        
        UIColor.white.setStroke()
        checkedOvalPath.lineWidth = 1
        checkedOvalPath.stroke()
        
        context?.setFillColor(UIColor.white.cgColor)
        
        let selectionTextAttributes: [NSAttributedString.Key: AnyObject] = {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byTruncatingTail
            paragraphStyle.alignment = .center
            return [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10.0),
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
        }()
        
        //// Bezier Drawing (Picture Number)
        let size = selectionString.size(withAttributes: selectionTextAttributes)
        
        selectionString.draw(in: CGRect(x: checkmarkFrame.midX - size.width / 2.0,
                                        y: checkmarkFrame.midY - size.height / 2.0,
                                        width: size.width,
                                        height: size.height), withAttributes: selectionTextAttributes)
    }
}
