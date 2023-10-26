import Foundation
import AVFoundation
import AudioToolbox
import os
import Speech
import MediaPlayer

/// to play audio and speak text, overrides mute
class SoundPlayer {
    
    // MARK: - properties
    
    /// for logging
    private var log = OSLog(subsystem: ConstantsLog.subSystem, category: ConstantsLog.categoryPlaySound)

    /// audioplayer
    private var audioPlayer: AVAudioPlayer?
    
    static let shared = SoundPlayer()
    
    private init() {
        
    }
    
    // MARK: - initializer
    
    /// plays the sound, overrides mute
    /// - parameters:
    ///     - soundFileName : name of the file with the sound, the filename must include the extension, eg mp3
    func playSound(soundFileName: String, withVolume volume: Float? = nil) {
        guard let url = Bundle.main.url(forResource: soundFileName, withExtension: "") else {
            trace("in playSound, could not create url with sound %{public}@", log: self.log, category: ConstantsLog.categoryPlaySound, type: .error, soundFileName)
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            
        } catch let error {
            trace("in playSound, could not set AVAudioSession category to playback and mixwithOthers, error = %{public}@", log: self.log, category: ConstantsLog.categoryPlaySound, type: .error, error.localizedDescription)
        }
        
        var volumeChanged = false
        
        if var volume = volume {
            volume = min(volume, 1.0)
            volume = max(volume, 0.1)
            
            let volumeView = MPVolumeView()
            
            if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
                volumeChanged = true
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
                    slider.value = volume
                    self.doPlaySound(soundUrl: url)
                }
            }
        }
        
        if !volumeChanged {
            doPlaySound(soundUrl: url)
        }
        
//        do {
//            try audioPlayer = AVAudioPlayer(contentsOf: url)
//
//            if let audioPlayer = audioPlayer {
//                audioPlayer.play()
//
//            } else {
//                trace("in playSound, could not create url with sound %{public}@", log: self.log, category: ConstantsLog.categoryPlaySound, type: .error, soundFileName)
//            }
//
//        } catch let error {
//            trace("in playSound, exception while trying to play sound %{public}@, error = %{public}@", log: self.log, category: ConstantsLog.categoryPlaySound, type: .error, error.localizedDescription)
//        }
    }
    
    private func doPlaySound(soundUrl: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundUrl)
            
            if let audioPlayer = audioPlayer {
                audioPlayer.play()
                
            } else {
                trace("in playSound, could not create url with sound %{public}@", log: self.log, category: ConstantsLog.categoryPlaySound, type: .error, soundUrl.absoluteString)
            }
            
        } catch let error {
            trace("in playSound, exception while trying to play sound %{public}@, error = %{public}@", log: self.log, category: ConstantsLog.categoryPlaySound, type: .error, error.localizedDescription)
        }
    }
    
    /// is the PlaySound playing or not
    func isPlaying() -> Bool {
        if let audioPlayer = audioPlayer {
            return audioPlayer.isPlaying
        }
        return false
    }
    
    /// if playSound is playing, then stop
    func stopPlaying() {
        if isPlaying(), let audioPlayer = audioPlayer {
            audioPlayer.stop()
        }
    }
}
