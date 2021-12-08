//  FreqRespViewController.swift
//  AcoustEQ
//
//  Created by Sean Levine on 11/8/21.
//
import UIKit
import AVFoundation

class FreqRespViewController: UIViewController {


    // Storyboard Init

    @IBOutlet weak var spectrumView: SpectrumView!
    @IBOutlet weak var countdownTimer: UILabel!
    @IBOutlet weak var RecordButton: UIButton!
    @IBOutlet weak var closeRecording: UIButton!
    
    // Init Audio control
    var audioInput: TempiAudioInput!
    
    // Init Timer
    var count = 5
    var timer = Timer()
    
    //Init Audio Settings
    var sampleRate = 44100.0
    var recordingBuffer = 16384.0 //samples
    var regularBuffer = 2048.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.spectrumView.bounds = spectrumView.bounds
        
        
        countdownTimer?.isHidden = true
        closeRecording?.isHidden = true

        
        let audioInputCallback: TempiAudioInputCallback = { (timeStamp, numberOfFrames, samples) -> Void in
//            self.gotSomeAudio(timeStamp: Double(timeStamp), numberOfFrames: Int(numberOfFrames), samples: samples)
            tempi_dispatch_main { () -> () in
                self.spectrumView.performFFT(inputBuffer: samples, bufferSize: Float(self.regularBuffer))
            }
            
        }
        
        audioInput = TempiAudioInput(audioInputCallback: audioInputCallback, sampleRate: 44100, numberOfChannels: 1)
        audioInput.startRecording()
    }
    
    @IBAction func recordButtonTapped(_ sender: UIButton) {
        
        //Stop Recording
        audioInput.stopRecording()
        
        //Start Timer
        startTimer()
        
        //Countdown
        countdownTimer.text = "Recording in... " + String(count)
        countdownTimer.isHidden = false
        
        //Recording buffer length initialized
        
        //Wait for countdown to finish
        let totalWaitTime =  DispatchTimeInterval.seconds(count)
        DispatchQueue.main.asyncAfter(deadline: .now() + totalWaitTime) {

            let audioInputCallback: TempiAudioInputCallback = { (timeStamp, numberOfFrames, samples) -> Void in
                // somehow change the numberOfFrames in callback and spectrumView
                tempi_dispatch_main { () -> () in
                    //self.spectrumView.fft = TempiFFT(withSize: recordingBuffer, sampleRate: sampleRate)
                    self.spectrumView.performFFT(inputBuffer: samples, bufferSize: Float(2048.0))
                }
                
            }
            self.audioInput = TempiAudioInput(audioInputCallback: audioInputCallback, sampleRate: 44100, numberOfChannels: 1)
            
            // Change the IO Buffer duration
            do {
                
            try self.audioInput.audioSession.setPreferredIOBufferDuration(self.recordingBuffer/self.sampleRate)
                
            } catch{
                print("*** audioSession error: \(error)")
            }
            
            self.audioInput.startRecording() //record and stop recording after certain period of time
            
            //Record for length of buffer and stop recording
            let totalRecordTime =  DispatchTimeInterval.seconds(Int(self.recordingBuffer/self.sampleRate))
            DispatchQueue.main.asyncAfter(deadline: .now() + totalRecordTime) { //change this value depending on the buffer size
                self.audioInput.stopRecording()
                self.closeRecording.isHidden = false
            }
            
        }
    }
    
    @IBAction func closeRecordingTapped(_ sender: UIButton) {
        self.closeRecording.isHidden = true
        let audioInputCallback: TempiAudioInputCallback = { (timeStamp, numberOfFrames, samples) -> Void in
//            self.gotSomeAudio(timeStamp: Double(timeStamp), numberOfFrames: Int(numberOfFrames), samples: samples)
            tempi_dispatch_main { () -> () in
                self.spectrumView.performFFT(inputBuffer: samples, bufferSize: Float(self.regularBuffer))
            }
            
        }
        do {
            
        try self.audioInput.audioSession.setPreferredIOBufferDuration(self.regularBuffer/self.sampleRate)
            
        } catch{
            print("*** audioSession error: \(error)")
        }
        
        audioInput = TempiAudioInput(audioInputCallback: audioInputCallback, sampleRate: 44100, numberOfChannels: 1)
        audioInput.startRecording()
    }
    
    //Countdown selector used to change the timer
    @objc func updateCounter() {
        if(count > 0) {
            count -= 1
            countdownTimer.text = "Recording in... " + String(count)
        }
        else {
            countdownTimer.isHidden = true
            timer.invalidate()
            count = 5
        }
    }
    
    func startTimer() {
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }
    

    override func didReceiveMemoryWarning() {
        NSLog("*** Memory!")
        super.didReceiveMemoryWarning()
    }


}
