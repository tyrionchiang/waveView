//
//  swiftViewController.swift
//  SiriWaveViewTest
//
//  Created by Chiang Chuan on 23/04/2017.
//  Copyright © 2017 Chiang Chuan. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    enum SCSiriWaveformViewInputType {
        case recorder
        case player
    }
    
    
    var audioRecorder : AVAudioRecorder!
    var audioPlayer : AVAudioPlayer?
    var recordingSession : AVAudioSession?
    
    var selectedInputType = SCSiriWaveformViewInputType.recorder
    
    
    let scSiriWaveView = UIWaveView()
    
    lazy var SegmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items : ["Recoder", "Player"])
        sc.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(white: 0.8, alpha: 1)], for: UIControlState.selected)
        sc.tintColor = UIColor(white: 0.5, alpha: 1)
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.addTarget(self, action: #selector(handleSegmentControl), for: .valueChanged)
        return sc
    }()
    
    func handleSegmentControl(){
        setSelectedInputType(SegmentControl.selectedSegmentIndex == 0 ? .recorder : .player)
        //        print("selectedInputType : \(String(describing: selectedInputType)),\n segment: \(SegmentControl.selectedSegmentIndex) ")
    }
    func setSelectedInputType(_ selectedInputType: SCSiriWaveformViewInputType){
        self.selectedInputType = selectedInputType
        switch selectedInputType {
        case .recorder:
            audioPlayer?.stop()
            audioRecorder.prepareToRecord()
            audioRecorder.isMeteringEnabled = true
            audioRecorder.record()
        case .player:
            audioRecorder.stop()
            //            audioPlayer.prepareToPlay()
            audioPlayer?.isMeteringEnabled = true
            audioPlayer?.play()
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        initializeRecorder()
        recorder()
        audioPlayer = createAVAudioPlayer("05 Side to Side (feat. Nicki Minaj)", fileType: "mp3", volum: 0.5)
        
        
        
        let displaylink = CADisplayLink.init(target: self, selector: #selector(self.updateMeters))
        displaylink.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
        scSiriWaveView.waveColor = UIColor.white
        scSiriWaveView.primaryWaveLineWidth = 3.0
        scSiriWaveView.secondaryWaveLineWidth = 1.0
        
        setSelectedInputType(.recorder)
    }
    
    func createAVAudioPlayer(_ fileName : String, fileType: String, volum:Float) -> AVAudioPlayer? {
        if let path = Bundle.main.path(forResource: fileName, ofType: fileType){
            if let file = FileManager.default.contents(atPath: path){
                do{
                    let newPlayer = try AVAudioPlayer(data: file)
                    newPlayer.volume = volum
                    newPlayer.delegate = self
                    return newPlayer
                }catch{
                    print("music play initialize faild")
                }
            }else{
                print("load file failed")
            }
        }else{
            print("file not exist: \(fileName)")
        }
        return nil
    }
    
    
    func initializeRecorder() {
        recordingSession = AVAudioSession.sharedInstance()
        if let session = recordingSession{
            do{
                try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
                try session.setActive(true)
                session.requestRecordPermission(){
                    [unowned self] (allowed: Bool) -> Void in DispatchQueue.main.async{
                        if allowed{
                            //TODO:
                        }else{
                            //failed to record!
                        }
                    }
                }
            }catch{
                //TODO
                //failed to record!
            }
        }
    }
    
    func recorder(){
        let audioURL = URL(fileURLWithPath: "/dev/null")
        let settings = [
            AVFormatIDKey: kAudioFormatAppleLossless,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2 as NSNumber,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
            ] as [String : Any]
        do{
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
        }catch{
            finishRecording()
        }
    }
    func finishRecording() {
        audioRecorder.stop()
        audioRecorder = nil
    }
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag{
            finishRecording()
        }
    }
    
    
    func updateMeters(){
        var normalizedValue: CGFloat = 0.0
        switch selectedInputType {
        case .recorder:
            audioRecorder.updateMeters()
            normalizedValue = _normalizedPowerLevel(fromDecibels: CGFloat(audioRecorder.averagePower(forChannel: 0)))
            break
            
        case .player:
            audioPlayer?.updateMeters()
            normalizedValue = _normalizedPowerLevel(fromDecibels: CGFloat(audioPlayer!.averagePower(forChannel: 0)))
            break
        }
        scSiriWaveView.updateWithLevel(level: normalizedValue)
        
    }
    
    func _normalizedPowerLevel(fromDecibels decibels: CGFloat) -> CGFloat {
        if decibels < -60.0 || decibels == 0.0 {
            return 0.0
        }
        return CGFloat(powf((powf(10.0, Float(0.05 * decibels)) - powf(10.0, 0.05 * -60.0)) * (1.0 / (1.0 - powf(10.0, 0.05 * -60.0))), 1.0 / 2.0))
    }
    
    
    func setView(){
        
        self.navigationController?.navigationBar.isHidden = true
        scSiriWaveView.backgroundColor = UIColor(r: 22, g: 22, b: 22)
        scSiriWaveView.frame = CGRect(x: 0, y: view.frame.height * 0.8, width: view.frame.width, height: view.frame.height / 8)
        SegmentControl.frame = CGRect(x: view.frame.midX - 75 , y: view.frame.midY * 1.5, width: 150, height: 25)

        
        view.addSubview(scSiriWaveView)

        view.addSubview(scSiriWaveView)
        view.addSubview(SegmentControl)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

