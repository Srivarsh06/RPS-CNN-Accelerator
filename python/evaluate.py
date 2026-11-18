"""Re-check the saved model without retraining. Run:  python evaluate.py
Loads model/rps_cnn.pt, scores data/rps32.npz, and sanity-checks the dataset split.
"""
import numpy as np
import torch
from train import RPSNet, CLASSES


def main():
    d = np.load("data/rps32.npz")
    for sp in ("train", "test"):
        print(f"{sp:5s} {len(d['y_' + sp]):4d} images, per class {dict(zip(CLASSES, np.bincount(d['y_' + sp], minlength=4).tolist()))}")

    # No test image may appear verbatim in the training set.
    train_hashes = {x.tobytes() for x in d["x_train"]}
    dupes = sum(x.tobytes() in train_hashes for x in d["x_test"])
    print("test images duplicated in train:", dupes)

    net = RPSNet()
    net.load_state_dict(torch.load("model/rps_cnn.pt"))
    net.eval()
    print("params:", sum(p.numel() for p in net.parameters()))

    with torch.no_grad():
        for sp in ("train", "test"):
            x = torch.tensor(d["x_" + sp], dtype=torch.float32)[:, None] / 255
            y = torch.tensor(d["y_" + sp])
            pred = net(x).argmax(1)
            print(f"{sp} accuracy: {(pred == y).float().mean().item():.4f}")

    cm = np.zeros((4, 4), int)
    for t, p in zip(y.tolist(), pred.tolist()):
        cm[t, p] += 1
    print("test confusion (rows=true, cols=pred)", CLASSES)
    print(cm)


if __name__ == "__main__":
    main()
