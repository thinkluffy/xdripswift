import Foundation
import AVFoundation
import AudioToolbox
import os
import Speech

class BGReadingSpeaker: NSObject {

    private static let log = Log(type: BGReadingSpeaker.self)

    /// a BgReadingsAccessor
    private var bgReadingsAccessor = BgReadingsAccessor()

    /// timestamp of last spoken reading, initially set to 1 jan 1970
    private var timeStampLastSpokenReading: Date

    /// to solve problem that sometimes UserDefaults key value changes is triggered twice for just one change
    private let keyValueObserverTimeKeeper: KeyValueObserverTimeKeeper = KeyValueObserverTimeKeeper()

    /// init is private, to avoid creation
    override init() {
        // initialize timeStampLastSpokenReading
        timeStampLastSpokenReading = Date(timeIntervalSince1970: 0)

        // call super.init
        super.init()

        // set languageCode in Texts_SpeakReading to value stored in defaults
        Texts_SpeakReading.setLanguageCode(code: UserDefaults.standard.speakReadingLanguageCode)

        // changing speakerLanguage code requires action
        UserDefaults.standard.addObserver(self, forKeyPath: UserDefaults.Key.speakReadingLanguageCode.rawValue, options: .new, context: nil)

    }

    // MARK: - public functions

    /// will speak the latest reading in the iPhone's language
    ///
    /// conditions:
    ///     - speakReadings is on
    ///     - no other sound is playing (via sharedAudioPlayer)
    ///     - there' s a recent reading less than 4.5 minutes old
    ///     - time since last spoken reading > interval defined by user (UserDefaults.standard.speakInterval)
    ///     - lastConnectionStatusChangeTimeStamp : when was the last transmitter dis/reconnect
    func speakNewReading(lastConnectionStatusChangeTimeStamp: Date) {
        BGReadingSpeaker.log.d("==> speakNewReading")

        // if speak reading not enabled, then no further processing
        if !UserDefaults.standard.speakReadings {
            return
        }

        // if app shared soundPlayer is playing, then don't say the text
        if SoundPlayer.shared.isPlaying() {
            BGReadingSpeaker.log.d("SoundPlayer is playing")
            return
        }

        // get latest reading, ignore sensor, rawData, timestamp - only 1
        let lastReadings = bgReadingsAccessor.get2LatestBgReadings(minimumTimeIntervalInMinutes: 4.0)

        // if there's no readings, then no further processing
        if lastReadings.count == 0 {
            BGReadingSpeaker.log.d("No reading to speak")
            return
        }

        // if an interval is defined, and if time since last spoken reading is less than interval, then don't speak
        // substract 10 seconds, because user will probably select a multiple of 5, and also readings usually arrive every 5 minutes
        // example user selects 10 minutes interval, next reading will arrive in exactly 10 minutes, time interval to be checked will be 590 seconds
        if Int(Date().timeIntervalSince(timeStampLastSpokenReading)) < (UserDefaults.standard.speakInterval * 60 - 10) {
            BGReadingSpeaker.log.d("Time interval < speakInterval")
            return
        }

        // check if timeStampLastSpokenReading is at least minimumTimeBetweenTwoReadingsInMinutes earlier than now
        // (or it's at least minimumTimeBetweenTwoReadingsInMinutes minutes ago that reading was spoken)
        // - otherwise don't speak the reading
        // exception : there's been a disconnect/reconnect after the last spoken reading
        if abs(timeStampLastSpokenReading.timeIntervalSince(Date())) < ConstantsSpeakReading.minimumTimeBetweenTwoReadingsInMinutes * 60.0 &&
                   timeStampLastSpokenReading.timeIntervalSince(lastConnectionStatusChangeTimeStamp) < 0 {
            BGReadingSpeaker.log.d("There is a connection status change since last speak")
            return
        }

        // assign bgReadingToSpeak
        let bgReadingToSpeak = lastReadings[0]

        // if reading older than 4.5 minutes, then no further processing
        if Date().timeIntervalSince(bgReadingToSpeak.timeStamp) > 4.5 * 60 {
            BGReadingSpeaker.log.d("bgReadingToSpeak is older than 4.5 minutes")
            return
        }

        if UserDefaults.standard.speakOnlyWhenOutOfRange &&
                   bgReadingToSpeak.calculatedValue < UserDefaults.standard.highMarkValue &&
                   bgReadingToSpeak.calculatedValue > UserDefaults.standard.lowMarkValue {
            BGReadingSpeaker.log.d("speakOnlyWhenOutOfRange is on, reading is in range")
            return
        }

        // start creating the text that needs to be spoken
        var currentBgReadingOutput = Texts_SpeakReading.currentGlucose

        //Glucose
        // create reading value
        var currentBgReadingFormatted = BgReading.unitizedString(calculatedValue: bgReadingToSpeak.calculatedValue,
                unitIsMgDl: UserDefaults.standard.bloodGlucoseUnitIsMgDl)
        // copied from Spike
        if !UserDefaults.standard.bloodGlucoseUnitIsMgDl {
            currentBgReadingFormatted = assertFractionalDigits(number: currentBgReadingFormatted)
        }
        currentBgReadingFormatted = formatLocaleSpecific(number: currentBgReadingFormatted, languageCode: Texts_SpeakReading.languageCode)
        if currentBgReadingFormatted == "HIGH" {
            currentBgReadingFormatted = ". " + Texts_SpeakReading.high

        } else if currentBgReadingFormatted == "LOW" {
            currentBgReadingFormatted = ". " + Texts_SpeakReading.low
        }
        currentBgReadingOutput = currentBgReadingOutput + " ,, " + currentBgReadingFormatted + ". "

        // Trend
        // if trend needs to be spoken, then compose trend text
        if UserDefaults.standard.speakTrend {
            //add trend to text (slope)
            currentBgReadingOutput += Texts_SpeakReading.currentTrend + " " + searchTranslationForCurrentTrend(bgReading: bgReadingToSpeak) + ". ";
        }

        // Delta
        // if delta needs to be spoken then compose delta
        if UserDefaults.standard.speakDelta {

            var previousBgReading: BgReading?
            if lastReadings.count > 1 {
                previousBgReading = lastReadings[1]
            }
            var currentDelta: String = bgReadingToSpeak.unitizedDeltaString(previousBgReading: previousBgReading, showUnit: false, mgdl: UserDefaults.standard.bloodGlucoseUnitIsMgDl)

            //Format current delta in case of anomalies
            if currentDelta == "ERR" || currentDelta == "???" {
                currentDelta = Texts_SpeakReading.deltanoncomputable
            }

            if (currentDelta == "0.0" || currentDelta == "+0" || currentDelta == "-0") {
                currentDelta = "0"
            }

            currentDelta = formatLocaleSpecific(number: currentDelta, languageCode: Texts_SpeakReading.languageCode)

            currentBgReadingOutput += Texts_SpeakReading.currentDelta + " " + currentDelta + "."

        }

        // say the text
        BGReadingSpeaker.log.d("speak reading")
        say(text: currentBgReadingOutput, language: Texts_SpeakReading.languageCode)

        // set timeStampLastSpokenReading
        timeStampLastSpokenReading = bgReadingToSpeak.timeStamp

    }

    // MARK: - private functions

    /// will speak the text, using language code for pronunciation
    private func say(text: String, language: String?) {

        let syn = AVSpeechSynthesizer.init()
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.51
        utterance.pitchMultiplier = 1
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        syn.speak(utterance)

    }

    /// copied from Spike -
    /// if number is a Double value, and if it has no "." then a "." is added - otherwise returns number
    private func assertFractionalDigits(number: String) -> String {
        let newNumber = number.replacingOccurrences(of: " ", with: "")

        if Double(newNumber) != nil {
            if !number.contains(find: ".") {
                return number + ".0"
            }
        }

        return number
    }

    /// copied from Spike
    /// - parameters:
    ///     - languageCode : must be format like en-EN
    private func formatLocaleSpecific(number: String, languageCode: String?) -> String {

        let newNumber = number.replacingOccurrences(of: " ", with: "")

        if Double(newNumber) != nil, let languageCode = languageCode {
            if languageCode.uppercased().startsWith("DE") {
                return number.replacingOccurrences(of: ".", with: ",")
            }
        }

        return number
    }

    /// translates currentTrend string to local string
    ///
    /// example if currentTrend = trenddoubledown, then for en-EN, return dramatically downward
    private func searchTranslationForCurrentTrend(bgReading: BgReading) -> String {
        if bgReading.hideSlope {
            return Texts_SpeakReading.trendnoncomputable
        }

        let slopeArrow = bgReading.slopArrow
        if slopeArrow == .doubleDown {
            return Texts_SpeakReading.trenddoubledown

        } else if slopeArrow == .singleDown {
            return Texts_SpeakReading.trendsingledown

        } else if slopeArrow == .fortyFiveDown {
            return Texts_SpeakReading.trendfortyfivedown

        } else if slopeArrow == .flat {
            return Texts_SpeakReading.trendflat

        } else if slopeArrow == .fortyFiveUp {
            return Texts_SpeakReading.trendfortyfiveup

        } else if slopeArrow == .singleUp {
            return Texts_SpeakReading.trendsingleup

        } else if slopeArrow == .doubleUp {
            return Texts_SpeakReading.trenddoubleup

        } else {
            return Texts_SpeakReading.trendnoncomputable
        }
    }

    // MARK:- observe function

    /// when user changes Speak Reading language code, action to do
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath {
            if let keyPathEnum = UserDefaults.Key(rawValue: keyPath) {
                switch keyPathEnum {

                case UserDefaults.Key.speakReadingLanguageCode:

                    // change by user, should not be done within 200 ms
                    if keyValueObserverTimeKeeper.verifyKey(forKey: keyPathEnum.rawValue, withMinimumDelayMilliSeconds: 200) {
                        // UserDefaults.standard.speakReadingLanguageCode shouldn't be nil normally, if it is would be a coding error, however need to check anyway so assign default if nil
                        Texts_SpeakReading.setLanguageCode(code: UserDefaults.standard.speakReadingLanguageCode)
                    }

                default:
                    break
                }
            }
        }
    }
}
