//
//  AudioViewModel.swift
//  IPlay
//
//  Created by Aswanth K on 01/07/25.
//

import Foundation
import CoreData
import AVFoundation
import MediaPlayer

final class AudioViewModel: NSObject, ObservableObject {
    @Published var tracks: [AudioTrack] = []
    @Published var currentPlayer: AVAudioPlayer?
    @Published var currentTrack: AudioTrack?
    @Published var currentlyPlayingFile: String?
    @Published var isPlaying: Bool = false
    
    @Published var playbackTime: TimeInterval = 0
    private var nowPlayingTimer: Timer?
    
    @Published var rotationAngle: Double = 0
    private var rotationTimer: Timer?
    
    private let context = PersistenceController.shared.container.viewContext
    var currentPlayerTimer: Timer.TimerPublisher {
        Timer.publish(every: 1.0, on: .main, in: .common)
    }
    
    @Published var isShuffleEnabled: Bool = false
    enum RepeatMode: String, CaseIterable {
        case off, one, all
    }
    @Published var repeatMode: RepeatMode = .off
    
    // MARK: - Playlists
    @Published var playlists: [Playlist] = []

    override init() {
        super.init()
        configureAudioSession()
        setupRemoteTransportControls()
        preloadFromDocumentsIfNeeded()
        fetchTracks()
        fetchPlaylists()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    // MARK: - Audio Session
    func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    @objc func handleAudioInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    currentPlayer?.play()
                    isPlaying = true
                    startNowPlayingUpdates()
                }
            }
        }
    }

    // MARK: - Track Management
    func fetchTracks() {
        let request: NSFetchRequest<AudioTrack> = AudioTrack.fetchRequest()
        do {
            tracks = try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
        }
    }

    func preloadFromDocumentsIfNeeded() {
        let existingCount = (try? context.count(for: AudioTrack.fetchRequest())) ?? 0
        guard existingCount == 0 else { return }

        let audioFiles = FileManagerHelper.shared.listAudioFiles()

        for fileURL in audioFiles {
            let track = AudioTrack(context: context)
            track.id = UUID()
            track.title = fileURL.deletingPathExtension().lastPathComponent
            track.artist = "Unknown"
            track.fileName = fileURL.lastPathComponent
        }

        do {
            try context.save()
        } catch {
            print("CoreData Save error: \(error)")
        }
    }

    func importAudioFiles(from pickedURLs: [URL]) {
        let documents = FileManagerHelper.shared.getDocumentsDirectory()

        for pickedURL in pickedURLs {
            let destinationURL = documents.appendingPathComponent(pickedURL.lastPathComponent)

            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: pickedURL, to: destinationURL)

                let track = AudioTrack(context: context)
                track.id = UUID()
                track.title = destinationURL.deletingPathExtension().lastPathComponent
                track.artist = "Unknown"
                track.fileName = destinationURL.lastPathComponent

            } catch {
                print("❌ Failed to import \(pickedURL.lastPathComponent): \(error.localizedDescription)")
            }
        }

        do {
            try context.save()
            fetchTracks()
        } catch {
            print("❌ Core Data save failed: \(error.localizedDescription)")
        }
    }

    func deleteTracks(at offsets: IndexSet) {
        DispatchQueue.main.async {
            for index in offsets {
                let trackToDelete = self.tracks[index]
                if self.currentlyPlayingFile == trackToDelete.fileName {
                    self.stopPlayback()
                }
                self.context.delete(trackToDelete)
            }

            do {
                try self.context.save()
                self.fetchTracks()
            } catch {
                print("Failed to delete tracks: \(error)")
            }
        }
    }
    // MARK: - Playlists
    func fetchPlaylists() {
        let request: NSFetchRequest<Playlist> = Playlist.fetchRequest()
        do {
            playlists = try context.fetch(request)
        } catch {
            print("Fetch playlists error: \(error)")
        }
    }

    func createPlaylist(named name: String) {
        let playlist = Playlist(context: context)
        playlist.id = UUID()
        playlist.name = name
        saveContext()
        fetchPlaylists()
    }

    func addTrack(_ track: AudioTrack, to playlist: Playlist) {
        playlist.addToTracks(track)
        saveContext()
        fetchPlaylists()
    }

    func removeTrack(_ track: AudioTrack, from playlist: Playlist) {
        playlist.removeFromTracks(track)
        saveContext()
        fetchPlaylists()
    }

    func deletePlaylist(_ playlist: Playlist) {
        context.delete(playlist)
        saveContext()
        fetchPlaylists()
    }
    
    // MARK: - Playback Control
    func togglePlayback(for track: AudioTrack) {
        let fileName = track.fileName ?? ""
        let fileURL = FileManagerHelper.shared.getDocumentsDirectory().appendingPathComponent(fileName)

        if currentlyPlayingFile == fileName, let player = currentPlayer {
            if player.isPlaying {
                player.pause()
                isPlaying = false
                stopNowPlayingUpdates()
                stopRotation()
            } else {
                player.play()
                isPlaying = true
                startNowPlayingUpdates()
                startRotation()
            }
            updateNowPlayingInfo(for: track)
        } else {
            stopPlayback()
            do {
                currentPlayer = try AVAudioPlayer(contentsOf: fileURL)
                currentPlayer?.delegate = self
                currentPlayer?.prepareToPlay()
                currentPlayer?.play()

                currentlyPlayingFile = fileName
                currentTrack = track
                isPlaying = true

                startNowPlayingUpdates()
                startRotation()
                updateNowPlayingInfo(for: track)
            } catch {
                print("Playback error: \(error)")
                isPlaying = false
                stopRotation()
            }
        }
    }

    func stopPlayback() {
        stopNowPlayingUpdates()
        stopRotation()
        currentPlayer?.stop()
        currentPlayer = nil
        playbackTime = 0
        currentTrack = nil
        currentlyPlayingFile = nil
        isPlaying = false
    }

    func playNextTrack() {
        guard !tracks.isEmpty else { return }
        
        if isShuffleEnabled {
            // Pick a random track that is not the current one
            let availableTracks = tracks.filter { $0 != currentTrack }
            if let randomTrack = availableTracks.randomElement() {
                togglePlayback(for: randomTrack)
            } else if repeatMode == .all {
                // If no available tracks (only one track), replay it
                if let currentTrack = currentTrack {
                    togglePlayback(for: currentTrack)
                }
            }
            return
        }
        
        guard let current = currentTrack,
              let index = tracks.firstIndex(of: current) else { return }
        if index + 1 < tracks.count {
            let nextTrack = tracks[index + 1]
            togglePlayback(for: nextTrack)
        } else if repeatMode == .all {
            // Loop to first track
            if let first = tracks.first {
                togglePlayback(for: first)
            }
        }
    }
    
    func playPreviousTrack() {
        guard let current = currentTrack,
              let index = tracks.firstIndex(of: current) else { return }
        
        if index > 0 {
            let previousTrack = tracks[index - 1]
            togglePlayback(for: previousTrack)
        } else if repeatMode == .all {
            // Loop to last track
            if let lastTrack = tracks.last {
                togglePlayback(for: lastTrack)
            }
        }
    }
    
    func cycleRepeatMode() {
        switch repeatMode {
        case .off:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .off
        }
    }
    
    func seek(to time: TimeInterval) {
        guard let player = currentPlayer else { return }
        player.currentTime = time
        playbackTime = time
        updateNowPlayingInfo(for: currentTrack!)
    }

    // MARK: - Now Playing Info
    func updateNowPlayingInfo(for track: AudioTrack) {
        var nowPlayingInfo: [String: Any] = [:]

        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title ?? "Unknown Title"
        nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist ?? "Unknown Artist"

        if let player = currentPlayer {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.isPlaying ? 1.0 : 0.0
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func startNowPlayingUpdates() {
        nowPlayingTimer?.invalidate()
        nowPlayingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let track = self.currentTrack else { return }
            self.playbackTime = self.currentPlayer?.currentTime ?? 0
            self.updateNowPlayingInfo(for: track)
        }
        RunLoop.current.add(nowPlayingTimer!, forMode: .common)
    }

    func stopNowPlayingUpdates() {
        nowPlayingTimer?.invalidate()
        nowPlayingTimer = nil
    }

    func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self, let track = self.currentTrack else { return .commandFailed }
            self.currentPlayer?.play()
            self.isPlaying = true
            self.startNowPlayingUpdates()
            self.updateNowPlayingInfo(for: track)
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self, let track = self.currentTrack else { return .commandFailed }
            self.currentPlayer?.pause()
            self.isPlaying = false
            self.stopNowPlayingUpdates()
            self.updateNowPlayingInfo(for: track)
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNextTrack()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPreviousTrack()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let player = self.currentPlayer,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            player.currentTime = positionEvent.positionTime
            self.updateNowPlayingInfo(for: self.currentTrack!)
            return .success
        }
    }
    
    // MARK: - Favorite
    var favoriteTracks: [AudioTrack] {
        tracks.filter { $0.favorite }
    }
    
    func toggleFavorite(for track: AudioTrack) {
        track.favorite.toggle()
        saveContext()
        fetchTracks()
    }
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            debugPrint("Failed to save favorite content:  \(error)")
        }
    }
    // Image Rotation
    private func startRotation() {
        rotationTimer?.invalidate()
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            self.rotationAngle += 0.5
            if self.rotationAngle >= 360 {
                self.rotationAngle = 0
            }
        }
        RunLoop.main.add(rotationTimer!, forMode: .common)
    }

    private func stopRotation() {
        rotationTimer?.invalidate()
        rotationTimer = nil
    }
}



// MARK: - AVAudioPlayerDelegate
extension AudioViewModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard let currentFileName = currentlyPlayingFile else { return }

        // Handle repeat one mode
        if repeatMode == .one {
            // Replay the same track
            if let currentTrack = currentTrack {
                togglePlayback(for: currentTrack)
            }
            return
        }

        // Handle repeat all mode or normal progression
        if let currentIndex = tracks.firstIndex(where: { $0.fileName == currentFileName }) {
            if currentIndex + 1 < tracks.count {
                // Play next track
                let nextTrack = tracks[currentIndex + 1]
                togglePlayback(for: nextTrack)
            } else if repeatMode == .all {
                // Loop to first track
                if let firstTrack = tracks.first {
                    togglePlayback(for: firstTrack)
                }
            } else {
                // Repeat mode is off - stop playback
                isPlaying = false
                playbackTime = currentPlayer?.duration ?? 0
                updateNowPlayingInfo(for: currentTrack!)
                stopNowPlayingUpdates()
                stopRotation()
            }
        }
    }
}
