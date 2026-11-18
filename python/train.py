"""Train the small hardware-friendly CNN. Run:  python train.py
Input : data/rps32.npz (from prep_data.py)
Output: model/rps_cnn.pt, model/metrics.json, model/confusion.png (if matplotlib present)

Architecture (chosen so every op maps to the planned RTL; no padding, no batchnorm, no bias-free tricks):
  input  1x32x32
  conv1  3x3, 1->4,  valid  -> 4x30x30   ReLU   (4 filters = 4 MAC lanes)
  pool   2x2 max            -> 4x15x15
  conv2  3x3, 4->8,  valid  -> 8x13x13   ReLU
  pool   2x2 max (floor)    -> 8x6x6
  fc     288 -> 4  (argmax)
"""
import json, os
import numpy as np
import torch, torch.nn as nn, torch.nn.functional as F

CLASSES = ["rock", "paper", "scissors", "none"]
torch.manual_seed(385); np.random.seed(385)


class RPSNet(nn.Module):
    def __init__(self):
        super().__init__()
        self.conv1 = nn.Conv2d(1, 4, 3)
        self.conv2 = nn.Conv2d(4, 8, 3)
        self.fc = nn.Linear(8 * 6 * 6, 4)

    def forward(self, x):
        x = F.max_pool2d(F.relu(self.conv1(x)), 2)
        x = F.max_pool2d(F.relu(self.conv2(x)), 2)
        return self.fc(x.flatten(1))


def augment(x):
    """x: (B,1,32,32) in [0,1]. Random shift +-3px, horizontal flip, brightness/contrast jitter."""
    B = x.shape[0]
    flip = torch.rand(B) < 0.5
    x = torch.where(flip[:, None, None, None], x.flip(3), x)
    pad = F.pad(x, (3, 3, 3, 3), mode="replicate")
    out = torch.empty_like(x)
    for i in range(B):
        dy, dx = np.random.randint(0, 7, 2)
        out[i] = pad[i, :, dy:dy + 32, dx:dx + 32]
    c = 1 + 0.3 * (torch.rand(B, 1, 1, 1) - .5) * 2
    b = 0.15 * (torch.rand(B, 1, 1, 1) - .5) * 2
    return ((out - .5) * c + .5 + b).clamp(0, 1)


def main():
    d = np.load("data/rps32.npz")
    xtr = torch.tensor(d["x_train"], dtype=torch.float32)[:, None] / 255
    ytr = torch.tensor(d["y_train"])
    xte = torch.tensor(d["x_test"], dtype=torch.float32)[:, None] / 255
    yte = torch.tensor(d["y_test"])

    net = RPSNet()
    opt = torch.optim.Adam(net.parameters(), 3e-3, weight_decay=1e-4)
    EPOCHS, BS = 150, 32
    sched = torch.optim.lr_scheduler.OneCycleLR(opt, 6e-3, total_steps=EPOCHS * ((len(xtr) + BS - 1) // BS))
    for ep in range(EPOCHS):
        net.train(); perm = torch.randperm(len(xtr)); tl = 0
        for i in range(0, len(xtr), BS):
            idx = perm[i:i + BS]
            loss = F.cross_entropy(net(augment(xtr[idx])), ytr[idx])
            opt.zero_grad(); loss.backward(); opt.step(); sched.step(); tl += loss.item() * len(idx)
        if ep % 10 == 9 or ep == EPOCHS - 1:
            net.eval()
            with torch.no_grad():
                acc = (net(xte).argmax(1) == yte).float().mean().item()
            print(f"epoch {ep+1:3d}  train_loss {tl/len(xtr):.4f}  test_acc {acc:.3f}")

    net.eval()
    with torch.no_grad():
        pred = net(xte).argmax(1)
        tr_acc = (net(xtr).argmax(1) == ytr).float().mean().item()
    cm = np.zeros((4, 4), int)
    for t, p in zip(yte.tolist(), pred.tolist()):
        cm[t, p] += 1
    acc = float((pred == yte).float().mean())
    print("\nfloat32 test accuracy:", round(acc, 4), " train acc:", round(tr_acc, 4))
    print("confusion (rows=true, cols=pred)", CLASSES); print(cm)
    print("params:", sum(p.numel() for p in net.parameters()))

    os.makedirs("model", exist_ok=True)
    torch.save(net.state_dict(), "model/rps_cnn.pt")
    json.dump({"test_acc": acc, "train_acc": tr_acc, "classes": CLASSES,
               "confusion": cm.tolist(), "n_test": len(yte)}, open("model/metrics.json", "w"), indent=2)
    try:
        import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
        fig, ax = plt.subplots(figsize=(4.2, 3.8)); ax.imshow(cm, cmap="Blues")
        ax.set_xticks(range(4), CLASSES, rotation=30); ax.set_yticks(range(4), CLASSES)
        for i in range(4):
            for j in range(4):
                ax.text(j, i, cm[i, j], ha="center", va="center", color="w" if cm[i, j] > cm.max() / 2 else "k")
        ax.set_xlabel("predicted"); ax.set_ylabel("true"); ax.set_title(f"Test accuracy {acc*100:.1f}%")
        fig.tight_layout(); fig.savefig("model/confusion.png", dpi=150)
    except ImportError:
        pass


if __name__ == "__main__":
    main()
