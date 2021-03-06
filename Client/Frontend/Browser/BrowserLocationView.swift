/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

protocol BrowserLocationViewDelegate {
    func browserLocationViewDidTapLocation(browserLocationView: BrowserLocationView)
    func browserLocationViewDidTapReaderMode(browserLocationView: BrowserLocationView)
}

class BrowserLocationView : UIView, UIGestureRecognizerDelegate {
    var delegate: BrowserLocationViewDelegate?

    private var lockImageView: UIImageView!
    private var locationLabel: UILabel!
    private var readerModeButton: ReaderModeButton!
    var readerModeButtonWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor()
        self.clipsToBounds = true
        self.layer.cornerRadius = 5

        lockImageView = UIImageView(image: UIImage(named: "lock_verified.png"))
        lockImageView.hidden = false
        lockImageView.isAccessibilityElement = true
        lockImageView.accessibilityLabel = NSLocalizedString("Secure connection", comment: "")
        addSubview(lockImageView)

        locationLabel = UILabel()
        locationLabel.font = UIFont(name: "HelveticaNeue-Light", size: 14)
        locationLabel.lineBreakMode = NSLineBreakMode.ByClipping
        locationLabel.userInteractionEnabled = true
        addSubview(locationLabel)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "SELtapLocationLabel:")
        locationLabel.addGestureRecognizer(tapGestureRecognizer)

        readerModeButton = ReaderModeButton(frame: CGRectZero)
        readerModeButton.hidden = true
        readerModeButton.addTarget(self, action: "SELtapReaderModeButton", forControlEvents: UIControlEvents.TouchUpInside)
        addSubview(readerModeButton)

        makeConstraints()
    }

    private func makeConstraints() {
        let container = self
        let padding = UIEdgeInsetsMake(4, 8, 4, 8)

        lockImageView.snp_remakeConstraints { make in
            make.centerY.equalTo(container).centerY
            make.left.equalTo(container.snp_left).with.offset(8)
            make.width.equalTo(self.lockImageView.intrinsicContentSize().width)
        }

        locationLabel.snp_remakeConstraints { make in
            make.centerY.equalTo(container.snp_centerY)
            if self.url?.scheme == "https" {
                make.left.equalTo(self.lockImageView.snp_right).with.offset(8)
            } else {
                make.left.equalTo(container.snp_left).with.offset(8)
            }
            if self.readerModeButton.readerModeState == ReaderModeState.Unavailable {
                make.right.equalTo(container.snp_right).with.offset(-8)
            } else {
                make.right.equalTo(self.readerModeButton.snp_left).with.offset(-4)
            }
        }

        readerModeButton.snp_remakeConstraints { make in
            make.centerY.equalTo(container).centerY
            make.right.equalTo(container.snp_right).with.offset(-4)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: 200, height: 28)
    }

    func SELtapLocationLabel(recognizer: UITapGestureRecognizer) {
        delegate?.browserLocationViewDidTapLocation(self)
    }

    func SELtapReaderModeButton() {
        delegate?.browserLocationViewDidTapReaderMode(self)
    }

    var url: NSURL? {
        didSet {
            lockImageView.hidden = (url?.scheme != "https")
            if let t = url?.absoluteString {
                if t.hasPrefix("http://") {
                    locationLabel.text = t.substringFromIndex(advance(t.startIndex, 7))
                } else if t.hasPrefix("https://") {
                    locationLabel.text = t.substringFromIndex(advance(t.startIndex, 8))
                } else {
                    locationLabel.text = t
                }
            }
            makeConstraints()
        }
    }

    var readerModeState: ReaderModeState {
        get {
            return readerModeButton.readerModeState
        }
        set (newReaderModeState) {
            if newReaderModeState != self.readerModeButton.readerModeState {
                self.readerModeButton.readerModeState = newReaderModeState
                makeConstraints()
                readerModeButton.hidden = (newReaderModeState == ReaderModeState.Unavailable)
                UIView.animateWithDuration(0.1, animations: { () -> Void in
                    if newReaderModeState == ReaderModeState.Unavailable {
                        self.readerModeButton.alpha = 0.0
                    } else {
                        self.readerModeButton.alpha = 1.0
                    }
                    self.layoutIfNeeded()
                })
            }
        }
    }
}

private class ReaderModeButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setImage(UIImage(named: "reader.png"), forState: UIControlState.Normal)
        setImage(UIImage(named: "reader_active.png"), forState: UIControlState.Selected)
        accessibilityLabel = NSLocalizedString("Reader", comment: "Browser function that presents simplified version of the page with bigger text.")
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var _readerModeState: ReaderModeState = ReaderModeState.Unavailable
    
    var readerModeState: ReaderModeState {
        get {
            return _readerModeState;
        }
        set (newReaderModeState) {
            _readerModeState = newReaderModeState
            switch _readerModeState {
            case .Available:
                self.enabled = true
                self.selected = false
            case .Unavailable:
                self.enabled = false
                self.selected = false
            case .Active:
                self.enabled = true
                self.selected = true
            }
        }
    }
}
