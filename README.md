# RPS-CNN: FPGA Rock-Paper-Scissors Accelerator (ECE 385)

Rohan Kohli, Srivarsh Gudlavalleti. Target: Real Digital Urbana (Spartan-7 XC7S50).

## Layout
```
python/prep_data.py   build 32x32 grayscale dataset (rock/paper/scissors/none)
python/train.py       train float32 CNN, report test accuracy + confusion matrix
python/evaluate.py    re-check the saved model + dataset split without retraining
rtl/                  SystemVerilog (mac_lane, mac_engine, inference_ctrl stub, cycle_counter)
tb/                   self-checking testbenches
mem/                  .mem files exported from Python (Week 2)
constraints/          Urbana .xdc (Week 2/5)
docs/                 notes, synthesis reports
create_vivado_project.tcl   builds vivado/rps_cnn.xpr (XC7S50)
sim.sh / sim_xsim.bat       run MAC testbench from the command line (Verilator / xsim)
```

## Running
**Vivado (simulation + synthesis).** The project is committed as `vivado/rps_cnn.xpr`; open it in Vivado 2022.2.
If it is missing or broken, regenerate it from the Vivado Tcl console: `cd <repo>; source create_vivado_project.tcl`.
- Simulation: Flow Navigator → Run Simulation → Run Behavioral Simulation. Tcl console prints
  `PASS: mac_engine matched reference on 50 trials x 4 lanes`.
- Synthesis: Run Synthesis (top = `mac_engine`, out-of-context since it has no pins yet).

**Python.** `pip install numpy torch pillow matplotlib`, then from `python/`:
- `python evaluate.py` scores the saved model (seconds).
- `python train.py` retrains from scratch (minutes on CPU).

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
- [x] Saved model re-checked with `evaluate.py`: 87.96% test / 94.97% train, 0 test images duplicated in train
- [x] RTL project skeleton, MAC engine verified in simulation (Vivado xsim, 50 trials x 4 lanes)
- [x] MAC engine synthesizes for XC7S50: 369 LUTs, 128 FFs (~1% of device), see `docs/mac_engine_utilization.txt`
- [ ] Week 2: INT8 quantization + .mem export, HDMI bring-up
