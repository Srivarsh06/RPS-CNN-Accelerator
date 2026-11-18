# RPS-CNN: FPGA Rock-Paper-Scissors Accelerator (ECE 385)

Rohan Kohli, Srivarsh Gudlavalleti. Target: Real Digital Urbana (Spartan-7 XC7S50).

## Layout
```
python/prep_data.py   build 32x32 grayscale dataset (rock/paper/scissors/none)
python/train.py       train float32 CNN, report test accuracy + confusion matrix
rtl/                  SystemVerilog (mac_lane, mac_engine, inference_ctrl stub, cycle_counter)
tb/                   self-checking testbenches
mem/                  .mem files exported from Python (Week 2)
constraints/          Urbana .xdc (Week 2/5)
docs/                 notes
sim.sh                run MAC testbench (Verilator)
```

## Network (what the RTL has to implement)
```
input 1x32x32 -> conv3x3 1->4 -> ReLU -> maxpool2 -> 4x15x15
              -> conv3x3 4->8 -> ReLU -> maxpool2 -> 8x6x6
              -> FC 288->4 -> argmax   (0 rock, 1 paper, 2 scissors, 3 none)
```
4 conv1 filters = 4 MAC lanes. 1,492 parameters total (40 + 296 + 1,156), fits trivially in BRAM.

## Status (Week 1)
- [x] Dataset prepared (split by source photo, no leakage)
- [x] Float CNN trained: 88.0% test accuracy (216 held-out images, split by source photo); train 95.0%; "none" class 54/54, rock/paper confusion is the main error
- [x] RTL project skeleton, MAC engine verified in simulation
- [ ] Week 2: INT8 quantization + .mem export, HDMI bring-up
