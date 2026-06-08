# Adaptive Modulation under Varying Wireless Channel Conditions

## Overview

This project presents a MATLAB-based simulation of an adaptive modulation system for wireless communication networks. The system dynamically selects the most suitable modulation technique according to channel quality conditions in order to balance communication reliability and spectral efficiency.

The simulation evaluates the performance of adaptive modulation under different wireless channel environments, including AWGN, Rayleigh fading, and Rician fading channels.

## Objectives

* Simulate wireless communication links under varying channel conditions.
* Implement and compare BPSK, QPSK, and 16-QAM modulation schemes.
* Develop adaptive modulation logic based on Signal-to-Noise Ratio (SNR).
* Analyze system performance using Bit Error Rate (BER) and Spectral Efficiency metrics.

## Features

* Adaptive modulation switching based on SNR thresholds.
* Support for:

  * BPSK
  * QPSK
  * 16-QAM
* Channel models:

  * AWGN
  * Rayleigh Fading
  * Rician Fading
* BER vs SNR analysis.
* Spectral Efficiency evaluation.
* Constellation diagram visualization.

## Adaptive Modulation Strategy

| SNR Range          | Selected Modulation |
| ------------------ | ------------------- |
| SNR < 8 dB         | BPSK                |
| 8 dB ≤ SNR < 18 dB | QPSK                |
| SNR ≥ 18 dB        | 16-QAM              |

The adaptive controller continuously monitors channel quality and selects the modulation scheme that provides the best trade-off between reliability and throughput.

## Key Results

* Lower-order modulation schemes provide greater reliability in poor channel conditions.
* Higher-order modulation schemes achieve improved data rates under favorable channel conditions.
* Adaptive modulation improves overall system performance by dynamically balancing BER and spectral efficiency.
