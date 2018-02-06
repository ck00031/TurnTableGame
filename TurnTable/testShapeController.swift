//
//  testShapeController.swift
//  FeeBee
//
//  Created by Alex on 2017/12/19.
//  Copyright © 2017年 alex. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

extension CGFloat {
    func radians() -> CGFloat {
        let b = CGFloat(Double.pi) * (self/180)
        return b
    }
}

extension UIColor{
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.characters.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
        
    }
}

extension UIBezierPath {
    convenience init(circleSegmentCenter center:CGPoint, radius:CGFloat, startAngle:CGFloat, endAngle:CGFloat)
    {
        self.init()
        self.move(to: CGPoint.init(x: center.x, y: center.y))
        self.addArc(withCenter: center, radius:radius, startAngle:startAngle.radians(), endAngle: endAngle.radians(), clockwise:true)
        self.close()
    }
}

class testShapeController: UIViewController,CAAnimationDelegate {
    var piechartView:UIView = UIView()
    var piechartCoverView:UIView = UIView()
    //定義最後中獎的piece，可以指定，也可以隨機，it's up to you
	var finalStopPiece:Double = 5
	//color array，如果想要定義每一piece的顏色的話可以unMark這個array跟137行
//	let pieceColorArray = [UIColor.init(hexString: "FFAF60"),UIColor.init(hexString: "A6A6D2"),UIColor.init(hexString: "93FF93"),UIColor.init(hexString: "00CACA"),UIColor.init(hexString: "FF5151"),UIColor.init(hexString: "AAAAFF"),UIColor.init(hexString: "66B3FF"),UIColor.init(hexString: "CF9E9E"),UIColor.init(hexString: "C2C287"),UIColor.init(hexString: "FF95CA"),UIColor.init(hexString: "FFFF6F"),UIColor.init(hexString: "d3a4ff"),UIColor.init(hexString: "CA8EC2"),UIColor.init(hexString: "ADADAD"),UIColor.init(hexString: "FFAF60")]
	let rewardLabel:UILabel = UILabel()
	let rewardArray = ["冰箱一台","iPhone X","HTC U11","再接再勵","100元禮券","再來一次"]
	var audioPlayer:AVAudioPlayer = AVAudioPlayer()
    
    override func viewDidLoad() {
		//決定要中幾號
		
		//這裡採亂數隨機中獎
		let randFinalStopPiece:Double = self.getRandomFinalReward(totalPieceCount: rewardArray.count)
		print("randFinalStopPiece:\(randFinalStopPiece)")
		finalStopPiece = randFinalStopPiece
		
		//UI初始化
		self.createUI()
    }
	
	//MARK: - UI
	private func createUI(){
		self.view.backgroundColor = UIColor.init(hexString: "150d25")
		
		//spin Header
		//638*351
		let spinHeaderImageViewWidth:CGFloat = self.view.frame.size.width
		let spinHeaderImageViewHeight:CGFloat = (spinHeaderImageViewWidth/638)*351
		let spinHeaderImageView:UIImageView = UIImageView.init(frame: CGRect.init(x: 0, y: 20, width: spinHeaderImageViewWidth, height: spinHeaderImageViewHeight))
		spinHeaderImageView.image = UIImage.init(named: "spinHeader")
		
		//turnTable容器
		let turnTableContainerView:UIView = UIView()
		let turnTableContainerViewWidth:CGFloat = self.view.frame.size.width - 40
		let turnTableContainerViewOriginY:CGFloat = spinHeaderImageView.frame.origin.y + spinHeaderImageView.frame.size.height + 30
		turnTableContainerView.frame = CGRect.init(x: 20, y: turnTableContainerViewOriginY, width: turnTableContainerViewWidth, height: turnTableContainerViewWidth)
		
		//中獎label
		let rewardLabelOriginY:CGFloat = turnTableContainerView.frame.origin.y + turnTableContainerView.frame.size.height + 20
		rewardLabel.frame = CGRect.init(x: 0, y: rewardLabelOriginY, width: self.view.frame.size.width, height: 30)
		rewardLabel.textColor = UIColor.white
		rewardLabel.textAlignment = .center
		rewardLabel.font = UIFont.boldSystemFont(ofSize: 30)
		rewardLabel.text = "點擊\"Go\"開始轉盤"
		
		self.view.addSubview(spinHeaderImageView)
		self.view.addSubview(turnTableContainerView)
		self.view.addSubview(rewardLabel)
		
		//計算中心點
		let middlePoint:CGPoint = CGPoint.init(x: turnTableContainerViewWidth/2, y: turnTableContainerViewWidth/2)
		
		//最外圈的圓
		let outCircleView:UIView = UIView()
		let outCircleViewWidth:CGFloat = turnTableContainerViewWidth
		outCircleView.frame = CGRect.init(x: 0, y: 0, width: outCircleViewWidth, height: outCircleViewWidth)
		outCircleView.center = middlePoint
		outCircleView.backgroundColor = UIColor.init(hexString: "FF5151")
		outCircleView.layer.cornerRadius = outCircleViewWidth / 2
		
		//內圈的圓
		let overCircleView:UIView = UIView()
		let overCircleViewBorderWidth:CGFloat = 20
		let overCircleViewWidth:CGFloat = outCircleViewWidth - overCircleViewBorderWidth
		overCircleView.frame = CGRect.init(x: 0, y: 0, width: overCircleViewWidth, height: overCircleViewWidth)
		overCircleView.center = middlePoint
		overCircleView.backgroundColor = UIColor.init(hexString: "01814A")
		overCircleView.layer.cornerRadius = overCircleView.frame.size.width / 2
		
		let rectSize = CGRect.init(x: 0, y: 0, width: overCircleViewWidth - 50, height: overCircleViewWidth - 50)
		let centrePointOfChart = CGPoint.init(x: rectSize.midX, y: rectSize.midY)
		let radius:CGFloat = rectSize.width / 2
		let piePieceArray:NSMutableArray = NSMutableArray.init()
		let piePieceCoverArray:NSMutableArray = NSMutableArray.init()
		
		var startAngle:CGFloat = 0
		var endAngel:CGFloat = CGFloat(360.0/Double(rewardArray.count))
		//產生piece
		for index in 1...rewardArray.count {
			var pieColor = UIColor.init(hexString: "FFD306")
			if index % 2 == 0 {
				pieColor = UIColor.init(hexString: "EA7500")
			}
            
            //要客製化每一個piece的顏色就unMark這裡
//			if pieceColorArray.count > index{
//				pieColor = pieceColorArray[index]
//			}
			
			piePieceArray.add((UIBezierPath(circleSegmentCenter: centrePointOfChart, radius: radius, startAngle: startAngle, endAngle: endAngel),pieColor))
			piePieceCoverArray.add((UIBezierPath(circleSegmentCenter: centrePointOfChart, radius: radius, startAngle: startAngle, endAngle: endAngel),UIColor.clear))
			startAngle = endAngel
			endAngel = endAngel + CGFloat(360.0/Double(rewardArray.count))
		}
		
		//產生piechart
		let pieChartViewOriginX:CGFloat = (self.view.frame.size.width - rectSize.width) / 2
		piechartView = pieChart(pieces: piePieceArray as! [(UIBezierPath, UIColor)], viewRect: CGRect.init(x: pieChartViewOriginX, y: 64, width: rectSize.width, height: rectSize.height))
		piechartView.center = middlePoint
		piechartView.layer.shadowRadius = 5
		piechartView.layer.shadowColor = UIColor.black.cgColor
		piechartView.layer.shadowOpacity = 0.3
		piechartView.layer.shadowOffset = CGSize.init(width: 0, height: 0)
		
		//中間的圓形
		let goButtton:UIButton = UIButton()
		let goButtonOriginX:CGFloat = piechartView.center.x
		let goButtonOriginY:CGFloat = piechartView.center.y
		let goButtonWidth:CGFloat = 60
		let goButtonHeight:CGFloat = 60
		goButtton.frame = CGRect.init(x: goButtonOriginX, y: goButtonOriginY, width: goButtonWidth, height: goButtonHeight)
		goButtton.center = piechartView.center
		goButtton.backgroundColor = UIColor.red
		goButtton.setTitle("Go", for: .normal)
		goButtton.setTitleColor(UIColor.white, for: .normal)
		goButtton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
		goButtton.layer.cornerRadius = goButtonWidth/2
		goButtton.layer.shadowRadius = 2
		goButtton.layer.shadowColor = UIColor.black.cgColor
		goButtton.layer.shadowOpacity = 0.3
		goButtton.layer.shadowOffset = CGSize.init(width: 0, height: 0)
		goButtton.addTarget(self, action: #selector(self.actionButtonClick), for: UIControlEvents.touchUpInside)
		
		//畫三角形
		let triangleView:UIView = UIView()
		triangleView.frame = CGRect.init(x: goButtton.frame.origin.x + goButtton.frame.size.width - 5, y: goButtton.frame.origin.y + (goButtton.frame.size.height/2)-15, width: 30, height: 30)
		triangleView.layer.addSublayer(self.triangleCAShapeLayer())
		triangleView.backgroundColor = UIColor.clear
		
		var layerIndex = 0
		var layerStartAngle:CGFloat = 0
		var layerEndAngel:CGFloat = 0
		
		//產生文字
		for _ in self.piechartView.layer.sublayers! {
			layerEndAngel = CGFloat(Double.pi * 2 / Double(rewardArray.count) + Double(layerStartAngle))
			
			let angle:CGFloat = (layerEndAngel - (layerEndAngel-layerStartAngle)/2)
			let labelNumber = self.createTextLayer(labelString: "\(rewardArray[layerIndex])", angle: angle)
			piechartView.layer.addSublayer(labelNumber)
			
			layerStartAngle = layerEndAngel
			layerEndAngel = layerEndAngel + CGFloat(360.0/Double(rewardArray.count))
			layerIndex = layerIndex + 1
		}
		
		turnTableContainerView.addSubview(outCircleView)
		turnTableContainerView.addSubview(overCircleView)
		turnTableContainerView.addSubview(piechartView)
		turnTableContainerView.addSubview(goButtton)
		turnTableContainerView.addSubview(triangleView)
	}
	
	//產生piechart
    func pieChart(pieces:[(UIBezierPath, UIColor)], viewRect:CGRect) -> UIView {
        var layers = [CAShapeLayer]()
        for p in pieces {
            let layer = CAShapeLayer()
            layer.path = p.0.cgPath
            layer.fillColor = p.1.cgColor
            layers.append(layer)
        }
        let view = UIView(frame: viewRect)
        
        for l in layers {
            view.layer.addSublayer(l)
        }
		
        return view
    }
	
	//產生文字layer
    func createTextLayer(labelString:String, angle:CGFloat)->CATextLayer{
        let txtLayer:CATextLayer = CATextLayer.init()
        txtLayer.frame = CGRect.init(x: 0, y: 0, width: piechartView.bounds.size.width - 30, height: 25)
        txtLayer.string = labelString
        txtLayer.anchorPoint = CGPoint.init(x: 0.5, y: 0.5)
        txtLayer.alignmentMode = kCAAlignmentLeft
        txtLayer.fontSize = 18
        txtLayer.foregroundColor = UIColor.white.cgColor
        txtLayer.contentsScale = UIScreen.main.scale
        txtLayer.position = CGPoint.init(x: piechartView.bounds.size.width/2, y: piechartView.bounds.size.width/2)
        txtLayer.transform = CATransform3DMakeRotation((CGFloat(Double(angle)+Double.pi)), 0, 0, 1)
		txtLayer.shadowRadius = 2
		txtLayer.shadowColor = UIColor.black.cgColor
		txtLayer.shadowOpacity = 0.3
		txtLayer.shadowOffset = CGSize.init(width: 0, height: 0)
		
        return txtLayer
    }
	
	//畫三角形
	func triangleCAShapeLayer()->CAShapeLayer{
		let triangleLayer:CAShapeLayer = CAShapeLayer.init()
		let path:UIBezierPath = UIBezierPath()
		path.move(to: CGPoint.init(x: 0, y: 0))
		path.addLine(to: CGPoint.init(x: 30, y: 15))
		path.addLine(to: CGPoint.init(x: 0, y: 30))
		triangleLayer.path = path.cgPath
		triangleLayer.fillColor = UIColor.red.cgColor
		
		return triangleLayer
	}
	
	//MARK: - Animation Delegate
	//動畫停止時
	func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
//		print("恭喜抽中：\(rewardArray[Int(finalStopPiece)-1])")
		rewardLabel.text = "恭喜抽中：\(rewardArray[Int(finalStopPiece)-1])"
		self.playBGM(soundEffectName: "game-sound-effects-winning-something-sound-for-game-developer", type:"mp3")
        
		//再次指定下一次中獎的piece，這裡採隨機中獎
		let randFinalStopPiece:Double = self.getRandomFinalReward(totalPieceCount: rewardArray.count)
		print("randFinalStopPiece:\(randFinalStopPiece)")
		finalStopPiece = randFinalStopPiece
	}
	
	//MARK: - Button Event
	//開始按鈕
	@objc func actionButtonClick(){
		rewardLabel.text = "旋轉、跳躍、我閉著眼..."
        
        //播放旋轉音效
		self.playBGM(soundEffectName: "cartoon-miscellaneous-comedy-wheel-1", type: "mp3")
        
		//一圈是2個pi
		//可以得知每一度是2pi/360
		//假設手指在0度的位置
		//每一piece的範圍:假設總杯有8piece，則每一piece的度數是360/8=45
		//若想要讓第一格停在手指的位置，則要旋轉2pi+-45-1(確保在範圍內)
		//預設要轉到第幾個位置
		let rewardPosition:Double = self.finalStopPiece
		//每一個piece的弧度，留個5度比較不會離線太接近
		let pieceAngle:Double = Double(360/rewardArray.count)
		let oneDegreeAngle:Double = ((2*Double.pi)/360)
        
		//取亂數，此亂數用來讓每次停下來的位置都會有一點偏移，看起來比較真實
		let randFinalAngleWithRewardPosition:Double = Double(Int(arc4random_uniform(UInt32(pieceAngle-2)))+2)
		
        //這裡計算最後停下來的位置
		let finalPieceAngle = (oneDegreeAngle*(randFinalAngleWithRewardPosition+((rewardPosition-1)*pieceAngle)))
		let rotation = CGFloat(((2*10) * Double.pi) - finalPieceAngle)
		let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
		rotationAnimation.duration = 5
		rotationAnimation.toValue = rotation
		rotationAnimation.isCumulative = true
		rotationAnimation.delegate = self
		rotationAnimation.fillMode=kCAFillModeForwards
		rotationAnimation.isRemovedOnCompletion = false;
		rotationAnimation.timingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionEaseOut)
		
		piechartView.layer.add(rotationAnimation, forKey: "rotationAnimation")
	}
	
	//MARK: - Random Number
	private func getRandomFinalReward(totalPieceCount:Int)->Double{
		//隨機中獎
		let randFinalStopPiece:Double = Double(arc4random_uniform(UInt32(totalPieceCount))+1)
		
		return randFinalStopPiece
	}
    
    //MARK: - Audio Event
    private func playBGM(soundEffectName:String, type:String){
        // To find file path of audio
        if let filePath = Bundle.main.path(forResource: soundEffectName, ofType: type){
            
            // To find file path url from file path
            
            let filePathUrl = URL.init(fileURLWithPath: filePath)
            
            do{
                
                // init audioPlayer using file path url
                
                audioPlayer = try AVAudioPlayer.init(contentsOf: filePathUrl)
//                audioPlayer.numberOfLoops = 1
            }catch{
                
                print("the filePathUrl is empty")
                
            }
            
        } else {
            
            print("the filePath is empty")
            
        }
        
        audioPlayer.play()
    }
}
