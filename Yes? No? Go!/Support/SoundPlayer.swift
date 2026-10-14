//
//  SoundPlayer.swift
//  Yes? No? Go!
//
//  The app's short sound effects. System sounds cover the lightweight taps;
//  bundled MP3s carry the characterful moments.
//

import Foundation
import AVFoundation
import AudioToolbox

/// Plays one named sound effect. Unknown names are ignored.
final class SoundPlayer {
    static let shared = SoundPlayer()

    private var audioPlayer: AVAudioPlayer?

    private init() {}

    func play(_ soundName: String) {
        // Use system sounds for lightweight playback
        switch soundName {
        case "coin":
            AudioServicesPlaySystemSound(1306) // Peek sound - bright and metallic like coin
        case "decision":
            AudioServicesPlaySystemSound(1057) // SMS Received 1 - subtle chime
        case "shuffle":
            AudioServicesPlaySystemSound(1519) // Begin Video Record - shuffling sound
        case "select":
            AudioServicesPlaySystemSound(1519) // Gentle selection sound
        case "rngDing":
            playFile(named: "rng_ding")
        case "success":
            AudioServicesPlaySystemSound(1025) // PhotoShutter - success sound
        case "yesChord":
            playFile(named: "c-chord-83638")
        case "noTrombone":
            playFile(named: "wah-wah-sad-trombone-6347")
        case "eagle":
            playFile(named: "eagle-sound-by-torma-368637")
        case "crown":
            playFile(named: "success-fanfare-trumpets-6185")
        case "thud":
            playFile(named: "thud-82914")
        case "slick":
            playFile(named: "steel-blade-slice-4-188216")
        case "paper":
            playFile(named: "crumping-paper-109585")
        case "mystical":
            playFile(named: "mystical-355968")
        case "error":
            AudioServicesPlaySystemSound(1053) // Error sound
        default:
            break
        }
    }

    private func playFile(named resource: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "mp3") else { return }
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
    }
}
