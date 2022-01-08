enum ConstantsNightScout {
    
    /// maximum number of days to upload
    static let maxDaysToUpload = 7
    
    /// if the time between the last and last but one reading is less than minimumTimeBetweenTwoReadingsInMinutes, then the last reading will not be uploaded - except if there's been a disconnect in between these two readings
    static let minimumTimeBetweenTwoReadingsInMinutes = 4.75
    
    /// there's al imit of 102400 bytes to upload to NightScout, this corresponds on average to 400 readings. Setting a lower maximum value to avoid to bypass this limit.
    static let maxReadingsToUpload = 300
    
}
