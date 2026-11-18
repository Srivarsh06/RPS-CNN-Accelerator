"""Build a 32x32 grayscale 4-class dataset (rock/paper/scissors/none) as data/rps32.npz.

Usage:  python prep_data.py /path/to/rps-dataset   (folder with paper/ rock/ scissor/)
Source: github.com/IvanHsiao29/rps-dataset (Roboflow export, 640x640 green-screen photos)

Notes
- Roboflow exports several augmented copies of each source photo (file name has
  '.rf.<hash>'). We split train/test by SOURCE photo so no copy of a test photo
  ever appears in training (otherwise test accuracy is inflated).
- The dataset has no 'no hand' class, so we synthesize empty green backgrounds.
"""
import sys, glob, os, re
import numpy as np
from PIL import Image

CLASSES = ["rock", "paper", "scissors", "none"]          # label = index
FOLDERS = {"rock": "rock", "paper": "paper", "scissors": "scissor"}
SIZE = 32
rng = np.random.default_rng(385)


def load_gray32(path):
    im = Image.open(path).convert("L")
    return np.asarray(im.resize((SIZE, SIZE), Image.BOX), dtype=np.uint8)


def synth_none(n, bg_stats):
    """Empty green-screen frames: random green level, gradient, noise, faint blotches."""
    out = []
    lo, hi = bg_stats
    for _ in range(n):
        base = rng.uniform(lo, hi)
        yy, xx = np.mgrid[0:SIZE, 0:SIZE] / (SIZE - 1)
        gx, gy = rng.uniform(-25, 25, 2)
        img = base + gx * (xx - .5) + gy * (yy - .5)
        for _ in range(rng.integers(0, 3)):               # soft blotches / shadows
            cx, cy, r = rng.uniform(0, 1, 2).tolist() + [rng.uniform(.1, .3)]
            img += rng.uniform(-18, 18) * np.exp(-(((xx - cx) ** 2 + (yy - cy) ** 2) / (2 * r * r)))
        img += rng.normal(0, rng.uniform(1, 5), img.shape)
        out.append(np.clip(img, 0, 255).astype(np.uint8))
    return np.stack(out)


def main(root):
    per_class = {}
    for cls, folder in FOLDERS.items():
        groups = {}
        for f in sorted(glob.glob(os.path.join(root, folder, "*.jpg"))):
            src = re.sub(r"\.rf\..*$", "", os.path.basename(f))
            groups.setdefault(src, []).append(f)
        srcs = sorted(groups)
        rng.shuffle(srcs)
        n_test = max(1, round(0.25 * len(srcs)))
        per_class[cls] = (srcs[n_test:], srcs[:n_test], groups)

    X = {"train": [], "test": []}; Y = {"train": [], "test": []}
    for cls, (tr, te, groups) in per_class.items():
        for split, srcs in (("train", tr), ("test", te)):
            for s in srcs:
                for f in groups[s]:
                    X[split].append(load_gray32(f)); Y[split].append(CLASSES.index(cls))
    bg = np.concatenate([x[:6].ravel() for x in X["train"]])  # rough bg gray range
    bg_stats = (np.percentile(bg, 5), np.percentile(bg, 40))
    n_tr = int(np.mean([Y["train"].count(i) for i in range(3)]))
    n_te = int(np.mean([Y["test"].count(i) for i in range(3)]))
    X["train"] += list(synth_none(n_tr, bg_stats)); Y["train"] += [3] * n_tr
    X["test"] += list(synth_none(n_te, bg_stats)); Y["test"] += [3] * n_te

    os.makedirs("data", exist_ok=True)
    np.savez_compressed("data/rps32.npz",
                        x_train=np.stack(X["train"]), y_train=np.array(Y["train"]),
                        x_test=np.stack(X["test"]), y_test=np.array(Y["test"]))
    for sp in ("train", "test"):
        print(sp, len(Y[sp]), "images, per class:", np.bincount(Y[sp], minlength=4))


if __name__ == "__main__":
    main(sys.argv[1])
