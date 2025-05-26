# Coordinate_Calculator
## Overview

This project implements a **high-performance triangle coordinate calculator**. The system receives three consecutive coordinate inputs representing triangle vertices and outputs a sequence of valid coordinate pairs (xo, yo) that represent all integer points within the triangle boundary using scanline rasterization algorithms.

## 🎯 Project Objectives

- **Triangle Rasterization**: Compute all integer coordinate points within a triangle
- **Scanline Algorithm**: Implement horizontal scanning from y = y1 to y = y3
- **Linear Equation Processing**: Use ax + by + c = 0 for boundary determination
- **Synthesizable Design**: Optimized for logic synthesis tools and timing constraints
- **Real-time Processing**: Efficient coordinate generation with proper control signals

## 🏗️ System Architecture

### Key Features
- **3-bit Coordinate System**: All inputs/outputs are 3-bit unsigned values (0-7)
- **Vertical Constraint**: Guaranteed x1 = x3 and y1 < y2 < y3 for one vertical side
- **Control Signal Management**: Proper handling of nt, busy, and po signals
- **Sequential Processing**: Outputs coordinates in correct scanline order
- **Timing Optimized**: Meets 0.37 ns clock period requirement

### Triangle Processing Algorithm
1. **Input Phase**: Receive three consecutive coordinate pairs (x1,y1), (x2,y2), (x3,y3)
2. **Boundary Calculation**: Compute linear equations for triangle edges
3. **Scanline Processing**: Horizontal scanning from top to bottom
4. **Point Evaluation**: Determine interior points using linear equations
5. **Sequential Output**: Generate valid coordinates with timing control

## 📊 Technical Specifications

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `clk` | Input | 1 | Clock source (positive edge triggered) |
| `reset` | Input | 1 | Active-high asynchronous reset |
| `nt` | Input | 1 | New triangle indication (active when busy is low) |
| `xi` | Input | 3 | X-coordinate input for triangle vertices |
| `yi` | Input | 3 | Y-coordinate input for triangle vertices |
| `busy` | Output | 1 | Processing status (high during calculation) |
| `po` | Output | 1 | Valid output indication |
| `xo` | Output | 3 | X-coordinate output |
| `yo` | Output | 3 | Y-coordinate output |

## 🔄 Operation Protocol

### Input Sequence
1. **Triangle Setup**: Assert `nt` when `busy` is low
2. **Coordinate Input**: Provide three consecutive coordinate pairs
3. **Processing Wait**: Monitor `busy` signal during calculation
4. **Result Collection**: Capture outputs when `po` is asserted

### Timing Constraints
- **Clock Period**: 0.37 ns minimum for logic synthesis
- **Synchronous Design**: All signals synchronized to clock rising edge
- **Reset Scheme**: Active-high asynchronous reset
- **Input Timing**: Coordinates provided sequentially over clock cycles

## 🚀 Prerequisites
- **Verilog Simulator**: NCVerilog 15.20
- **Waveform Viewer**: nWave (Verdi_P-2019.06)
- **Synthesis Tools**: GENUS 20.10

## 🧪 Testing & Verification
![tb_result](https://github.com/user-attachments/assets/e015ec1f-3eb5-440d-b938-b8a4f5b336b6)

### Report Summary
