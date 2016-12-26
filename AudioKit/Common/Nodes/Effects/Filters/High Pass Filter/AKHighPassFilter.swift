//
//  AKHighPassFilter.swift
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright (c) 2016 Aurelius Prochazka. All rights reserved.
//

import AVFoundation

/// AudioKit version of Apple's HighPassFilter Audio Unit
///
open class AKHighPassFilter: AKNode, AKToggleable, AUComponent {

    public static let ComponentDescription = AudioComponentDescription(appleEffect: kAudioUnitSubType_HighPassFilter)

    internal var internalEffect = AVAudioUnitEffect()
    internal var internalAU: AudioUnit? = nil

    fileprivate var mixer: AKMixer

    /// Cutoff Frequency (Hz) ranges from 10 to 22050 (Default: 6900)
    open var cutoffFrequency: Double = 6900 {
        didSet {
            cutoffFrequency = (10...22050).clamp(cutoffFrequency)
            AudioUnitSetParameter(
                internalAU!,
                kHipassParam_CutoffFrequency,
                kAudioUnitScope_Global, 0,
                Float(cutoffFrequency), 0)
        }
    }

    /// Resonance (dB) ranges from -20 to 40 (Default: 0)
    open var resonance: Double = 0 {
        didSet {
            resonance = (-20...40).clamp(resonance)
            AudioUnitSetParameter(
                internalAU!,
                kHipassParam_Resonance,
                kAudioUnitScope_Global, 0,
                Float(resonance), 0)
        }
    }

    /// Dry/Wet Mix (Default 100)
    open var dryWetMix: Double = 100 {
        didSet {
            dryWetMix = (0...100).clamp(dryWetMix)
            inputGain?.volume = 1 - dryWetMix / 100
            effectGain?.volume = dryWetMix / 100
        }
    }

    fileprivate var lastKnownMix: Double = 100
    fileprivate var inputGain: AKMixer?
    fileprivate var effectGain: AKMixer?

    /// Tells whether the node is processing (ie. started, playing, or active)
    open var isStarted = true

    // MARK: - Initialization

    /// Initialize the high pass filter node
    ///
    /// - Parameters:
    ///   - input: Input node to process
    ///   - cutoffFrequency: Cutoff Frequency (Hz) ranges from 10 to 22050 (Default: 6900)
    ///   - resonance: Resonance (dB) ranges from -20 to 40 (Default: 0)
    ///
    public init(
        _ input: AKNode,
        cutoffFrequency: Double = 6900,
        resonance: Double = 0) {

            self.cutoffFrequency = cutoffFrequency
            self.resonance = resonance

            inputGain = AKMixer(input)
            inputGain!.volume = 0
            mixer = AKMixer(inputGain!)

            effectGain = AKMixer(input)
            effectGain!.volume = 1

            internalEffect = AVAudioUnitEffect(audioComponentDescription: _Self.ComponentDescription)
            super.init()

            AudioKit.engine.attach(internalEffect)
            internalAU = internalEffect.audioUnit
            AudioKit.engine.connect((effectGain?.avAudioNode)!, to: internalEffect)
            AudioKit.engine.connect(internalEffect, to: mixer.avAudioNode)
            avAudioNode = mixer.avAudioNode

            AudioUnitSetParameter(internalAU!, kHipassParam_CutoffFrequency, kAudioUnitScope_Global, 0, Float(cutoffFrequency), 0)
            AudioUnitSetParameter(internalAU!, kHipassParam_Resonance, kAudioUnitScope_Global, 0, Float(resonance), 0)
    }

    // MARK: - Control

    /// Function to start, play, or activate the node, all do the same thing
    open func start() {
        if isStopped {
            dryWetMix = lastKnownMix
            isStarted = true
        }
    }

    /// Function to stop or bypass the node, both are equivalent
    open func stop() {
        if isPlaying {
            lastKnownMix = dryWetMix
            dryWetMix = 0
            isStarted = false
        }
    }
}
