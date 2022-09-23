//
//  GraphViewMaker.swift
//  GyroData
//
//  Created by 유영훈 on 2022/09/22.
//

import Foundation
import UIKit

protocol GraphViewMakerDelegate {
    /// 그래프가 업데이트 될때 호출됨.
    func graphViewDidUpdate(interval: Float, x: Float, y: Float, z: Float)
    /// graphView의 에니메이션을 수행하는 타이머가 중지될때 호출되어짐.
    func graphViewDidEnd()
    /// graphView의 에니메이션을 수행하는 타이머가 시작될때 호출되어짐.
    func graphViewDidPlay()
}


/**
    그래프뷰 모듈
 
    그래프 제공 및 애니메이션 시작, 중단, 리셋기능 존재
 */
class GraphViewMaker {
    
    enum addLayerOption {
        case multiple
        case single
    }
    
    let customGreen: UIColor = UIColor(red: 0.3608, green: 0.8196, blue: 0.3804, alpha: 1.0)
    
    static let shared = GraphViewMaker()
    public var delegate: GraphViewMakerDelegate!
    
    /// 그래프 뷰의 Height
    private let graphViewHeight: CGFloat = 280.0
    
    /// 그래프 뷰의 Width
    private let graphViewWidth: CGFloat = 280.0
    
    /// 1개의 데이터가 차지할 width
    private var blockWidth: CGFloat = 0.0

    /// 그래프 기준점
    private var graphBaseHeight: CGFloat = 0.0
    
    private var xValue: Float = 0.0
    private var yValue: Float = 0.0
    private var ySubValue: Float = 0.0
    private var zValue: Float = 0.0
    
    /// 그래프 뷰를 불러옵니다.
    lazy public var graphView: UIView = {
        let uiView = UIView()
            uiView.layer.borderColor = UIColor.black.cgColor
            uiView.layer.borderWidth = 2.0
        
        // 그래프 차트의 백그라운드 표현
        self.blockWidth = self.graphViewHeight/8 // 차트 백그라운드의 가로, 세로 칸 수
        let backgroundPath = UIBezierPath()
        for i in [1,2,3,4,5,6,7,8] {
            backgroundPath.move(to: CGPoint(x: Int(blockWidth)*i, y: 0))
            backgroundPath.addLine(to: CGPoint(x: Int(blockWidth)*i, y: Int(graphViewWidth)))
        }
        
        for i in [1,2,3,4,5,6,7,8] {
            backgroundPath.move(to: CGPoint(x: 0, y: Int(blockWidth)*i))
            backgroundPath.addLine(to: CGPoint(x: Int(graphViewWidth), y: Int(blockWidth)*i))
        }
        
        let chartBackgroundLayer = CAShapeLayer()
        chartBackgroundLayer.frame = uiView.bounds
        chartBackgroundLayer.path = backgroundPath.cgPath
        chartBackgroundLayer.fillColor = UIColor.clear.cgColor
        chartBackgroundLayer.strokeColor = UIColor.gray.cgColor
        chartBackgroundLayer.lineWidth = 1.5
        uiView.layer.addSublayer(chartBackgroundLayer)
        
        return uiView
    }()

    /// 센서 x 값
    lazy private var xOffsetLabel: UILabel = {
        let label = CommonUIModule().creatLabel(text: "x: 0", color: .red, alignment: .left, fontSize: 13, fontWeight: .regular)
        return label
    }()
    
    /// 센서 y값
    lazy private var yOffsetLabel: UILabel = {
        let label = CommonUIModule().creatLabel(text: "y: 0", color: customGreen, alignment: .center, fontSize: 13, fontWeight: .regular)
        return label
    }()
    
    /// 센서 z값
    lazy private var zOffsetLabel: UILabel = {
        let label = CommonUIModule().creatLabel(text: "z: 0", color: .blue, alignment: .right, fontSize: 13, fontWeight: .regular)
        return label
    }()
    
    /// x, y, z 좌표값 표시 뷰
    lazy public var OffsetPannelStackView: UIStackView = {
        let stackView = UIStackView()
            stackView.backgroundColor = UIColor(white: 0.98, alpha: 0.8)
            stackView.layer.masksToBounds = true
            stackView.layer.cornerRadius = 8
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8)
            stackView.addArrangedSubview(xOffsetLabel)
            stackView.addArrangedSubview(yOffsetLabel)
            stackView.addArrangedSubview(zOffsetLabel)
            xOffsetLabel.widthAnchor.constraint(equalTo: yOffsetLabel.widthAnchor).isActive = true
            xOffsetLabel.widthAnchor.constraint(equalTo: zOffsetLabel.widthAnchor).isActive = true
        return stackView
    }()

    // MARK: 전역 변수
    
    // sample struct
    public struct gyroValue {
        let x: Float
        let y: Float
        let z: Float
        
        init(x: Float, y: Float, z: Float) {
            self.x = x
            self.y = y
            self.z = z
        }
    }
    
    /// 센서 측정 타이머
    lazy private var timer = Timer()
    
    /// 그래프 데이터가 저장된 배열
    private var graphData = [gyroValue]()
    
    // x, y, z선을 추가할 layer
    private var xLineLayer = CAShapeLayer()
    private var yLineLayer = CAShapeLayer()
    private var zLineLayer = CAShapeLayer()
    
    // x, y, z 선
    private var xLine = UIBezierPath()
    private var yLine = UIBezierPath()
    private var zLine = UIBezierPath()
    
    ///; 데이터를 선택할 인덱스
    private var index: Int = 0
    
    /// 그래프 뷰 애니메이션을 담당하는 타이머의 상태
    public var isRunning: Bool = false
    
    // 기록 총 시간
    private var interval: Float = 0.0
    
    /// 그래프 스케일링 시 적용될 변수 값
    private var multiplier: Float = 1.0
    
    /// 현재 x, y, z 좌표값의 절대값 최대치를 담는 변수
    private var maxOffset: Float = 0.0
    
    /**
        그래프에 데이터 배열을 0.1초 단위로 그려줍니다.
     */
    public func play(animated: Bool) {
        resetGraph()
        if !animated {
            showGraph()
        } else {
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateGraph), userInfo: nil, repeats: true)
            isRunning = true
        }
        delegate.graphViewDidPlay()
    }
    
    /**
        그래프 데이터를 한번에 보여줌.
     */
    func showGraph() {
        // sample data
        while graphData.count <= 600 {
            let x = Float.random(in: -100 ..< -70.0)
            let y = Float.random(in: -20.0 ..< 50.0)
            let z = Float.random(in: 60.0 ..< 100.0)
            graphData.append(GraphViewMaker.gyroValue(x: x, y: y, z: z))
            let max = [x, y, z].sorted { abs($0) > abs($1) }.first!
            maxOffset = abs(max) > maxOffset ?
                abs(max) : maxOffset
        }
        
        // 한개의 점이 차지할 width
        blockWidth = graphViewHeight/600.0
        
        xLine = UIBezierPath()
        xLine.move(to: CGPoint(x: 1.5, y: Double(graphBaseHeight)))
        yLine = UIBezierPath()
        yLine.move(to: CGPoint(x: 1.5, y: Double(graphBaseHeight)))
        zLine = UIBezierPath()
        zLine.move(to: CGPoint(x: 1.5, y: Double(graphBaseHeight)))
        
        // 각 x, y, z 레이어 add
        addLayer(xLine, xLineLayer, .red, .multiple)
        addLayer(yLine, yLineLayer, customGreen, .multiple)
        addLayer(zLine, zLineLayer, .blue, .multiple)
    }
    
    /**
        그래프 애니메이션을 중단합니다. timer invalidate
     */
    @objc public func stop() {
        timer.invalidate()
        isRunning = false
        delegate.graphViewDidEnd()
    }
    
    /**
        0.1초 간격으로 timer가 호출할 graphView upadte 함수
     */
    @objc private func updateGraph() {
        // 모든 데이터를 보여준 뒤 timer out
        if index == graphData.count-1 {
            stop()
            return
        }
        
        // MARK: 테스트 데이터 START
        
        // 각 좌표의 값들이 최대값을 넘기는 CASE 발생시키기
        
        if index < 30 {
            xValue += Float(Int.random(in: -10 ..< 13))
            yValue += Float(Int.random(in: -5 ..< 5))
            zValue += Float(Int.random(in: -7 ..< 7))
        }
        
        if index < 70 && index > 30 {
            xValue += 7.4
            yValue += 0
            zValue += 0
        }
        
        if index < 100 && index > 70 {
            xValue += Float(Int.random(in: -3 ..< 3))
            yValue += Float(Int.random(in: -4 ..< 5))
            zValue += Float(Int.random(in: -1 ..< 3))
        }
        
        if index < 150 && index > 100 {
            xValue += Float(Int.random(in: -8 ..< 12))
            yValue += Float(Int.random(in: -3 ..< 3))
            zValue += Float(Int.random(in: -2 ..< 2))
        }
        
        if index < 220 && index > 150 {
            xValue -= 0.7
            yValue += 3.2
            zValue += 0
        }else {
            xValue += Float(Int.random(in: -10 ..< 10))
            yValue += Float(Int.random(in: -20 ..< 20))
            zValue += Float(Int.random(in: -20 ..< 20))
        }
        
        
        // 0.1초마다 데이터 적재
        let x = Float.random(in: xValue-1 ..< xValue)
        let y = Float.random(in: yValue-1 ..< yValue)
        let z = Float.random(in: zValue-1 ..< zValue)
        // MARK: 테스트 데이터 END
        
        graphData.append(gyroValue(x: x, y: y, z: z))
        
        xOffsetLabel.text = "x: \(String(format: "%0.f", x))"
        yOffsetLabel.text = "y: \(String(format: "%0.f", y))"
        zOffsetLabel.text = "z: \(String(format: "%0.f", z))"
        
        delegate.graphViewDidUpdate(interval: interval, x: x, y: y, z: z)
        
        // x, y, z 절대값으로 비교 및 최대값 대체
        let max = [x, y, z].sorted { abs($0) > abs($1) }.first!
        maxOffset = abs(max) > maxOffset ?
            abs(max) : maxOffset
        
        // 타이머 라벨 update
        interval += Float(timer.timeInterval)
        
        // 한개의 점이 차지할 width
        blockWidth = graphViewHeight/600.0
        
        // 각 x, y, z 레이어 add
        addLayer(xLine, xLineLayer, .red)
        addLayer(yLine, yLineLayer, customGreen)
        addLayer(zLine, zLineLayer, .blue)
        
        // 다음 점 표시를 위한 index 증감
        index += 1
    }
    
    /**
        graphView 위에 선을 그려주는 함수
     */
    private func addLayer(_ line: UIBezierPath, _ layer: CAShapeLayer, _ strokColor: UIColor, _ option: addLayerOption = .single) {
        
        // 최대값에 따른 스케일링 비율 설정
        let baseHeight: Float = Float(graphBaseHeight)
        if (maxOffset >= baseHeight) || (maxOffset <= -baseHeight) {
            // 기준점은 높이의 절반 값
            // 값이 baseHeight값의 절대값보다 크게되면 그래프 최대치를 초과하는것.
            multiplier = ((baseHeight / maxOffset) - 0.05)
        }
        
        // x, y, z 라인 구분
        switch line {
            case xLine:
                if option == .single {
                    xLine = UIBezierPath()
                    xLine.move(to: CGPoint(x: 1.5, y: Double(baseHeight)))
                }
                for (i, d) in graphData.enumerated() {
                    let x = CGFloat((i+1)) * blockWidth
                    let y = CGFloat(baseHeight - (d.x * multiplier))
                    xLine.addLine(to: CGPoint(x: x, y: y))
                }
                break
            case yLine:
                if option == .single {
                    yLine = UIBezierPath()
                    yLine.move(to: CGPoint(x: 1.5, y: Double(baseHeight)))
                }
                for (i, d) in graphData.enumerated() {
                    let x = CGFloat((i+1)) * blockWidth
                    let y = CGFloat(baseHeight - (d.y * multiplier))
                    yLine.addLine(to: CGPoint(x: x, y: y))
                }
                break
            case zLine:
                if option == .single {
                    zLine = UIBezierPath()
                    zLine.move(to: CGPoint(x: 1.5, y: Double(baseHeight)))
                }
                for (i, d) in graphData.enumerated() {
                    let x = CGFloat((i+1)) * blockWidth
                    let y = CGFloat(baseHeight - (d.z * multiplier))
                    zLine.addLine(to: CGPoint(x: x, y: y))
                }
                break
            default:
                break
        }
        
        // 그래프에 선 추가
        layer.frame = graphView.bounds
        layer.path = line.cgPath
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = strokColor.cgColor
        layer.lineWidth = 1.2
        graphView.layer.addSublayer(layer)
    }
    
    /**
        그래프 뷰를 초기화 합니다.
     */
    public func resetGraph() {
        graphBaseHeight = graphViewHeight / 2.0
        index = 0 // index 초기화
        interval = 0.0
        multiplier = 1.0
        graphData.removeAll(keepingCapacity: false)
        
        // x, y, z 점 위치 초기화
        xLine = UIBezierPath()
        xLine.move(to: CGPoint(x: 1.5, y: graphBaseHeight))
        yLine = UIBezierPath()
        yLine.move(to: CGPoint(x: 1.5, y: graphBaseHeight))
        zLine = UIBezierPath()
        zLine.move(to: CGPoint(x: 1.5, y: graphBaseHeight))
        
        xOffsetLabel.text = "x: \(String(format: "%0.f", 0))"
        yOffsetLabel.text = "y: \(String(format: "%0.f", 0))"
        zOffsetLabel.text = "z: \(String(format: "%0.f", 0))"
        
        // TEST
        xValue = 0.0
        yValue = 0.0
        ySubValue = 0.0
        zValue = 0.0
        
        xLineLayer.removeFromSuperlayer()
        yLineLayer.removeFromSuperlayer()
        zLineLayer.removeFromSuperlayer()
    }
}