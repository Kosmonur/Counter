//
//  ViewController.swift
//  Counter
//
//  Created by Александр Пичугин on 15.02.2023.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate {
    
    // задаём начальное значение счётчика
    private var counter:UInt = 0
    
    // добавим Haptic Touch на кнопку - определим силу отклика
    private let rigidImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
    
    // добавим в программу аудио
    private var audioPlayers: [AVAudioPlayer] = []
    private var audioPlayersLock = NSRecursiveLock()
    
    // будет два разных звука - один для нажатия кнопки, второй - для отпускания
    enum ButtonSound {
        case soundButtonUp
        case soundButtonDown
        
        var fileName: String {
            switch self {
            case .soundButtonUp:
                return "soundbuttonup"

            case .soundButtonDown:
                return "soundbuttondown"
            }
        }

        var fileURL: URL? {
            Bundle.main.url(forResource: self.fileName, withExtension: "wav")
        }
    }
    
    @IBOutlet weak var counterLabel: UILabel!
    @IBOutlet weak var counterButton: UIButton!
    
    /// Функция вызывается один раз при начальной загрузке программы
    override func viewDidLoad() {
        super.viewDidLoad()
        // выводим значенние счётчика
        counterLabel.text = "Значение счётчика:\n\n\(counter)"
        // делаем кнопку круглой
        counterButton.layer.cornerRadius = 0.5*counterButton.bounds.size.height      
    }
    
    @IBAction func buttonTouchDown(_ sender: Any) {
        // при нажатии кнопки - делаем Haptic Touch и играем звук
        rigidImpactFeedbackGenerator.impactOccurred()
        playButtonSound(.soundButtonDown)
    }
    
    @IBAction func buttonTouchUpInside(_ sender: Any) {
        // при отпускании кнопки - инкрементим счетчик с проверкой на переполнение, делаем Haptic Touch и играем звук
        
        counter = counter < UInt.max ? counter + 1 : 0
        counterLabel.text = "Значение счётчика:\n\n\(counter)"
        
        rigidImpactFeedbackGenerator.impactOccurred()
        playButtonSound(.soundButtonUp)
    }
    
    /// Функция воспроизведения звуков
    func playButtonSound(_ buttonSound: ButtonSound) {
        guard let buttonSoundURL = buttonSound.fileURL else {
            print("Ошибка в url на звук \(buttonSound.fileName)")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: buttonSoundURL)
                audioPlayer.delegate = self

                self.audioPlayersLock.lock()
                self.audioPlayers.append(audioPlayer)
                self.audioPlayersLock.unlock()

                // audioPlayer.volume = 1
                audioPlayer.prepareToPlay()
                audioPlayer.play()
            } catch {
                print("Ошибка воспроизведения \(error)")
            }
        }
    }
    
    /// Функция вызывается, когда проигрыватель завершил воспроизведение звука
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayersLock.lock()
        self.audioPlayers = self.audioPlayers.filter { $0 !== player }
        audioPlayersLock.unlock()
    }
}

