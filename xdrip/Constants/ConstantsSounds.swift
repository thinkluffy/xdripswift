/// defines name of the Soundfile and name of the sound shown to the user with an extra function - both are defined in one case, seperated by a backslash - to be used for alerts - all these sounds will be shown
enum ConstantsSounds: String, CaseIterable {
    
    // here using case iso properties because we want to iterate through them
    // name of the sound as shown to the user, and also stored in the alerttype
    case batterwakeup = "Better Wake Up/betterwakeup.wav"
    case bruteforce = "Brute Force/bruteforce.wav"
    case modernalarm2 = "Modern Alert 2/modern2.wav"
    case modernalarm = "Modern Alert/modernalarm.wav"
    case shorthigh1 = "Short High 1/shorthigh1.wav"
    case shorthigh2 = "Short High 2/shorthigh2.wav"
    case shorthigh3 = "Short High 3/shorthigh3.wav"
    case shorthigh4 = "Short High 4/shorthigh4.wav"
    case shortlow1  = "Short Low 1/shortlow1.wav"
    case shortlow2  = "Short Low 2/shortlow2.wav"
    case shortlow3  = "Short Low 3/shortlow3.wav"
    case shortlow4  = "Short Low 4/shortlow4.wav"
    case spaceship = "Space Ship/spaceship.wav"
    case xdripalert = "xDrip Alert/xdripalert.wav"
    
    // copied from Spike project https://github.com/SpikeApp/Spike/tree/master/src/assets/sounds
    case Alarm_Buzzer = "Alarm Buzzer/Alarm_Buzzer.wav"
    case Alarm_Clock = "Alarm Clock/Alarm_Clock.wav"
    case Alert_Tone_Busy = "Alert Tone Busy/Alert_Tone_Busy.wav"
    case Alert_Tone_Ringtone_1 = "Alert Tone Ringtone 1/Alert_Tone_Ringtone_1.wav"
    case Alert_Tone_Ringtone_2 = "Alert Tone Ringtone 2/Alert_Tone_Ringtone_2.wav"
    case Alien_Siren = "Alien Siren/Alien_Siren.wav"
    case Ambulance = "Ambulance/Ambulance.wav"
    case Analog_Watch_Alarm = "Analog Watch Alarm/Analog_Watch_Alarm.wav"
    case Big_Clock_Ticking = "Big Clock Ticking/Big_Clock_Ticking.wav"
    case Burglar_Alarm_Siren_1 = "Burglar Alarm Siren 1/Burglar_Alarm_Siren_1.wav"
    case Burglar_Alarm_Siren_2 = "Burglar Alarm Siren 2/Burglar_Alarm_Siren_2.wav"
    case Cartoon_Ascend_Climb_Sneaky = "Cartoon Ascend Climb Sneaky/Cartoon_Ascend_Climb_Sneaky.wav"
    case Cartoon_Ascend_Then_Descend = "Cartoon Ascend Then Descend/Cartoon_Ascend_Then_Descend.wav"
    case Cartoon_Bounce_To_Ceiling = "Cartoon Bounce To Ceiling/Cartoon_Bounce_To_Ceiling.wav"
    case Cartoon_Dreamy_Glissando_Harp = "Cartoon Dreamy Glissando Harp/Cartoon_Dreamy_Glissando_Harp.wav"
    case Cartoon_Fail_Strings_Trumpet = "Cartoon Fail Strings Trumpet/Cartoon_Fail_Strings_Trumpet.wav"
    case Cartoon_Machine_Clumsy_Loop = "Cartoon Machine Clumsy Loop/Cartoon_Machine_Clumsy_Loop.wav"
    case Cartoon_Siren = "Cartoon Siren/Cartoon_Siren.wav"
    case Cartoon_Tip_Toe_Sneaky_Walk = "Cartoon Tip Toe Sneaky Walk/Cartoon_Tip_Toe_Sneaky_Walk.wav"
    case Cartoon_Uh_Oh = "Cartoon Uh Oh/Cartoon_Uh_Oh.wav"
    case Cartoon_Villain_Horns = "Cartoon Villain Horns/Cartoon_Villain_Horns.wav"
    case Cell_Phone_Ring_Tone = "Cell Phone Ring Tone/Cell_Phone_Ring_Tone.wav"
    case Chimes_Glassy = "Chimes Glassy/Chimes_Glassy.wav"
    case Computer_Magic = "Computer Magic/Computer_Magic.wav"
    case CSFX2_Alarm = "CSFX2 Alarm/CSFX-2_Alarm.wav"
    case Cuckoo_Clock = "Cuckoo Clock/Cuckoo_Clock.wav"
    case Dhol_Shuffleloop = "Dhol Shuffleloop/Dhol_Shuffleloop.wav"
    case Discreet = "Discreet/Discreet.wav"
    case Early_Sunrise = "Early Sunrise/Early_Sunrise.wav"
    case Emergency_Alarm_Carbon_Monoxide = "Emergency Alarm Carbon Monoxide/Emergency_Alarm_Carbon_Monoxide.wav"
    case Emergency_Alarm_Siren = "Emergency Alarm Siren/Emergency_Alarm_Siren.wav"
    case Emergency_Alarm = "Emergency Alarm/Emergency_Alarm.wav"
    case Ending_Reached = "Ending Reached/Ending_Reached.wav"
    case Fly = "Fly/Fly.wav"
    case Ghost_Hover = "Ghost Hover/Ghost_Hover.wav"
    case Good_Morning = "Good Morning/Good_Morning.wav"
    case Hell_Yeah_Somewhat_Calmer = "Hell Yeah Somewhat Calmer/Hell_Yeah_Somewhat_Calmer.wav"
    case In_A_Hurry = "In A Hurry/In_A_Hurry.wav"
    case Indeed = "Indeed/Indeed.wav"
    case Insistently = "Insistently/Insistently.wav"
    case Jingle_All_The_Way = "Jingle All The Way/Jingle_All_The_Way.wav"
    case Laser_Shoot = "Laser Shoot/Laser_Shoot.wav"
    case Machine_Charge = "Machine Charge/Machine_Charge.wav"
    case Magical_Twinkle = "Magical Twinkle/Magical_Twinkle.wav"
    case Marching_Heavy_Footed_Fat_Elephants = "Marching Heavy Footed Fat Elephants/Marching_Heavy_Footed_Fat_Elephants.wav"
    case Marimba_Descend = "Marimba Descend/Marimba_Descend.wav"
    case Marimba_Flutter_or_Shake = "Marimba Flutter or Shake/Marimba_Flutter_or_Shake.wav"
    case Martian_Gun = "Martian Gun/Martian_Gun.wav"
    case Martian_Scanner = "Martian Scanner/Martian_Scanner.wav"
    case Metallic = "Metallic/Metallic.wav"
    case Nightguard = "Nightguard/Nightguard.wav"
    case Not_Kiddin = "Not Kiddin/Not_Kiddin.wav"
    case Open_Your_Eyes_And_See = "Open Your Eyes And See/Open_Your_Eyes_And_See.wav"
    case Orchestral_Horns = "Orchestral Horns/Orchestral_Horns.wav"
    case Oringz = "Oringz/Oringz.wav"
    case Pager_Beeps = "Pager Beeps/Pager_Beeps.wav"
    case Remembers_Me_Of_Asia = "Remembers Me Of Asia/Remembers_Me_Of_Asia.wav"
    case Rise_And_Shine = "Rise And Shine/Rise_And_Shine.wav"
    case Rush = "Rush/Rush.wav"
    case SciFi_Air_Raid_Alarm = "SciFi Air Raid Alarm/Sci-Fi_Air_Raid_Alarm.wav"
    case SciFi_Alarm_Loop_1 = "SciFi Alarm Loop 1/Sci-Fi_Alarm_Loop_1.wav"
    case SciFi_Alarm_Loop_2 = "SciFi Alarm Loop 2/Sci-Fi_Alarm_Loop_2.wav"
    case SciFi_Alarm_Loop_3 = "SciFi Alarm Loop 3/Sci-Fi_Alarm_Loop_3.wav"
    case SciFi_Alarm_Loop_4 = "SciFi Alarm Loop 4/Sci-Fi_Alarm_Loop_4.wav"
    case SciFi_Alarm = "SciFi Alarm/Sci-Fi_Alarm.wav"
    case SciFi_Computer_Console_Alarm = "SciFi Computer Console Alarm/Sci-Fi_Computer_Console_Alarm.wav"
    case SciFi_Console_Alarm = "SciFi Console Alarm/Sci-Fi_Console_Alarm.wav"
    case SciFi_Eerie_Alarm = "SciFi Eerie Alarm/Sci-Fi_Eerie_Alarm.wav"
    case SciFi_Engine_Shut_Down = "SciFi Engine Shut Down/Sci-Fi_Engine_Shut_Down.wav"
    case SciFi_Incoming_Message_Alert = "SciFi Incoming Message Alert/Sci-Fi_Incoming_Message_Alert.wav"
    case SciFi_Spaceship_Message = "SciFi Spaceship Message/Sci-Fi_Spaceship_Message.wav"
    case SciFi_Spaceship_Warm_Up = "SciFi Spaceship Warm Up/Sci-Fi_Spaceship_Warm_Up.wav"
    case SciFi_Warning = "SciFi Warning/Sci-Fi_Warning.wav"
    case Signature_Corporate = "Signature Corporate/Signature_Corporate.wav"
    case Siri_Alert_Calibration_Needed = "Siri Alert Calibration Needed/Siri_Alert_Calibration_Needed.wav"
    case Siri_Alert_Device_Muted = "Siri Alert Device Muted/Siri_Alert_Device_Muted.wav"
    case Siri_Alert_Glucose_Dropping_Fast = "Siri Alert Glucose Dropping Fast/Siri_Alert_Glucose_Dropping_Fast.wav"
    case Siri_Alert_Glucose_Rising_Fast = "Siri Alert Glucose Rising Fast/Siri_Alert_Glucose_Rising_Fast.wav"
    case Siri_Alert_High_Glucose = "Siri Alert High Glucose/Siri_Alert_High_Glucose.wav"
    case Siri_Alert_Low_Glucose = "Siri Alert Low Glucose/Siri_Alert_Low_Glucose.wav"
    case Siri_Alert_Missed_Readings = "Siri Alert Missed Readings/Siri_Alert_Missed_Readings.wav"
    case Siri_Alert_Transmitter_Battery_Low = "Siri Alert Transmitter Battery Low/Siri_Alert_Transmitter_Battery_Low.wav"
    case Siri_Alert_Urgent_High_Glucose = "Siri Alert Urgent High Glucose/Siri_Alert_Urgent_High_Glucose.wav"
    case Siri_Alert_Urgent_Low_Glucose = "Siri Alert Urgent Low Glucose/Siri_Alert_Urgent_Low_Glucose.wav"
    case Siri_Calibration_Needed = "Siri Calibration Needed/Siri_Calibration_Needed.wav"
    case Siri_Device_Muted = "Siri Device Muted/Siri_Device_Muted.wav"
    case Siri_Glucose_Dropping_Fast = "Siri Glucose Dropping Fast/Siri_Glucose_Dropping_Fast.wav"
    case Siri_Glucose_Rising_Fast = "Siri Glucose Rising Fast/Siri_Glucose_Rising_Fast.wav"
    case Siri_High_Glucose = "Siri High Glucose/Siri_High_Glucose.wav"
    case Siri_Low_Glucose = "Siri Low Glucose/Siri_Low_Glucose.wav"
    case Siri_Missed_Readings = "Siri Missed Readings/Siri_Missed_Readings.wav"
    case Siri_Transmitter_Battery_Low = "Siri Transmitter Battery Low/Siri_Transmitter_Battery_Low.wav"
    case Siri_Urgent_High_Glucose = "Siri Urgent High Glucose/Siri_Urgent_High_Glucose.wav"
    case Siri_Urgent_Low_Glucose = "Siri Urgent Low Glucose/Siri_Urgent_Low_Glucose.wav"
    case Soft_Marimba_Pad_Positive = "Soft Marimba Pad Positive/Soft_Marimba_Pad_Positive.wav"
    case Soft_Warm_Airy_Optimistic = "Soft Warm Airy Optimistic/Soft_Warm_Airy_Optimistic.wav"
    case Soft_Warm_Airy_Reassuring = "Soft Warm Airy Reassuring/Soft_Warm_Airy_Reassuring.wav"
    case Store_Door_Chime = "Store Door Chime/Store_Door_Chime.wav"
    case Sunny = "Sunny/Sunny.wav"
    case Thunder_Sound_FX = "Thunder Sound FX/Thunder_Sound_FX.wav"
    case Time_Has_Come = "Time Has Come/Time_Has_Come.wav"
    case Tornado_Siren = "Tornado Siren/Tornado_Siren.wav"
    case Two_Turtle_Doves = "Two Turtle Doves/Two_Turtle_Doves.wav"
    case Unpaved = "Unpaved/Unpaved.wav"
    case Wake_Up_Will_You = "Wake Up Will You/Wake_Up_Will_You.wav"
    case Win_Gain = "Win Gain/Win_Gain.wav"
    case Wrong_Answer = "Wrong Answer/Wrong_Answer.wav"
    
    /// gets all sound names in array, ie part of the case before the /
    static func allSoundsBySoundNameAndFileName() -> (soundNames:[String], fileNames:[String]) {
        var soundNames = [String]()
        var soundFileNames = [String]()
        
        soundloop: for sound in ConstantsSounds.allCases {
            
            // ConstantsSounds defines available sounds. Per case there a string which is the soundname as shown in the UI and the filename of the sound in the Resources folder, seperated by backslash
            // get array of indexes, of location of "/"
            let indexOfBackSlash = sound.rawValue.indexes(of: "/")
            
            // define range to get the soundname (as shown in UI)
            let soundNameRange = sound.rawValue.startIndex..<indexOfBackSlash[0]
            
            // now get the soundName in a string
            let soundName = String(sound.rawValue[soundNameRange])
            
            // add the soundName to the returnvalue
            soundNames.append(soundName)
            
            // define range to get the soundFileName
            let languageCodeRange = sound.rawValue.index(after: indexOfBackSlash[0])..<sound.rawValue.endIndex
            
            // now get the language in a string
            let fileName = String(sound.rawValue[languageCodeRange])
            // add the languageCode to the returnvalue
            
            soundFileNames.append(fileName)
            
        }
        return (soundNames, soundFileNames)
    }
    
    /// gets the soundname for specific case
    static func getSoundName(forSound:ConstantsSounds) -> String {
        let indexOfBackSlash = forSound.rawValue.indexes(of: "/")
        let soundNameRange = forSound.rawValue.startIndex..<indexOfBackSlash[0]
        return String(forSound.rawValue[soundNameRange])
    }
    
    /// gets the soundFile for specific case
    static func getSoundFile(forSound:ConstantsSounds) -> String {
        let indexOfBackSlash = forSound.rawValue.indexes(of: "/")
        let soundNameRange = forSound.rawValue.index(after: indexOfBackSlash[0])..<forSound.rawValue.endIndex
        return String(forSound.rawValue[soundNameRange])
    }
}
