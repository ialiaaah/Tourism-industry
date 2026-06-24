#!/usr/bin/env python3
"""
Generate a procedural GLB (binary glTF 2.0) model of the Pyramid of Khafre.
Outputs: assets/models/khafre_pyramid.glb

Run from the project root:
    python3 tools/generate_pyramid_glb.py
"""

import struct, json, math, os, sys

def pack_float(v): return struct.pack('<f', v)
def pack_uint16(v): return struct.pack('<H', v)

def cross(a, b):
    return [
        a[1]*b[2] - a[2]*b[1],
        a[2]*b[0] - a[0]*b[2],
        a[0]*b[1] - a[1]*b[0],
    ]

def normalize(v):
    l = math.sqrt(sum(x*x for x in v)) or 1.0
    return [x/l for x in v]

def face_normal(p0, p1, p2):
    ab = [p1[i]-p0[i] for i in range(3)]
    ac = [p2[i]-p0[i] for i in range(3)]
    return normalize(cross(ab, ac))

# ── Pyramid geometry ──────────────────────────────────────────────────────────
# Khafre pyramid: base 215.5m, height 143.5m → ratio ~0.666
# Model unit = 1 (scale applied in Flutter), half-base = 0.5, height = 0.666

HW = 0.5   # half base width
HT = 0.666 # height

# 5 unique positions
POSITIONS = [
    [-HW,  0.0, -HW],   # 0 back-left
    [ HW,  0.0, -HW],   # 1 back-right
    [ HW,  0.0,  HW],   # 2 front-right
    [-HW,  0.0,  HW],   # 3 front-left
    [ 0.0, HT,  0.0],   # 4 apex
]

# Each face: (v0, v1, v2) indices into POSITIONS + face colour hint via normal
# Faces wound CCW when viewed from outside
FACES = [
    (3, 2, 4),   # front  face  (south)
    (2, 1, 4),   # right  face  (east)
    (1, 0, 4),   # back   face  (north)
    (0, 3, 4),   # left   face  (west)
    (0, 1, 2),   # base   tri 1
    (0, 2, 3),   # base   tri 2
]

def build_buffers():
    """Return (pos_bytes, norm_bytes, idx_bytes, n_verts, n_indices, bbox)"""
    pos_data  = []
    norm_data = []
    idx_data  = []

    for (i0, i1, i2) in FACES:
        p0, p1, p2 = POSITIONS[i0], POSITIONS[i1], POSITIONS[i2]
        n = face_normal(p0, p1, p2)
        base_idx = len(pos_data) // 3
        for p in (p0, p1, p2):
            pos_data.extend(p)
            norm_data.extend(n)
        idx_data.extend([base_idx, base_idx+1, base_idx+2])

    pos_bytes  = b''.join(pack_float(v) for v in pos_data)
    norm_bytes = b''.join(pack_float(v) for v in norm_data)
    idx_bytes  = b''.join(pack_uint16(v) for v in idx_data)

    # Pad idx_bytes to 4-byte boundary
    while len(idx_bytes) % 4:
        idx_bytes += b'\x00'

    n_verts   = len(pos_data) // 3
    n_indices = len(idx_data)

    xs = pos_data[0::3]; ys = pos_data[1::3]; zs = pos_data[2::3]
    bbox = ([min(xs), min(ys), min(zs)], [max(xs), max(ys), max(zs)])
    return pos_bytes, norm_bytes, idx_bytes, n_verts, n_indices, bbox


def build_glb(out_path):
    pos_bytes, norm_bytes, idx_bytes, n_verts, n_indices, bbox = build_buffers()

    # Sandy limestone colour for the pyramid (RGB linear approx)
    base_color = [0.820, 0.714, 0.498, 1.0]

    # Buffer layout: [idx_bytes | pos_bytes | norm_bytes]
    idx_len  = len(idx_bytes)
    pos_len  = len(pos_bytes)
    norm_len = len(norm_bytes)
    buf_len  = idx_len + pos_len + norm_len

    gltf = {
        "asset": {"version": "2.0", "generator": "CulturaX-PyGen"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"mesh": 0, "name": "KhafrePyramid"}],
        "meshes": [{
            "name": "pyramid",
            "primitives": [{
                "attributes": {
                    "POSITION": 1,
                    "NORMAL":   2,
                },
                "indices":  0,
                "material": 0,
                "mode":     4,
            }]
        }],
        "materials": [{
            "name": "limestone",
            "pbrMetallicRoughness": {
                "baseColorFactor": base_color,
                "metallicFactor":  0.0,
                "roughnessFactor": 0.85,
            },
            "doubleSided": False,
        }],
        "accessors": [
            # 0 — indices
            {
                "bufferView": 0,
                "byteOffset": 0,
                "componentType": 5123,  # UNSIGNED_SHORT
                "count": n_indices,
                "type": "SCALAR",
            },
            # 1 — positions
            {
                "bufferView": 1,
                "byteOffset": 0,
                "componentType": 5126,  # FLOAT
                "count": n_verts,
                "type": "VEC3",
                "min": bbox[0],
                "max": bbox[1],
            },
            # 2 — normals
            {
                "bufferView": 2,
                "byteOffset": 0,
                "componentType": 5126,
                "count": n_verts,
                "type": "VEC3",
            },
        ],
        "bufferViews": [
            # 0 — indices
            {"buffer": 0, "byteOffset": 0,
             "byteLength": idx_len, "target": 34963},
            # 1 — positions
            {"buffer": 0, "byteOffset": idx_len,
             "byteLength": pos_len, "byteStride": 12, "target": 34962},
            # 2 — normals
            {"buffer": 0, "byteOffset": idx_len + pos_len,
             "byteLength": norm_len, "byteStride": 12, "target": 34962},
        ],
        "buffers": [{"byteLength": buf_len}],
    }

    json_bytes = json.dumps(gltf, separators=(',', ':')).encode('utf-8')
    # Pad to 4-byte boundary with spaces
    while len(json_bytes) % 4:
        json_bytes += b' '

    bin_chunk = idx_bytes + pos_bytes + norm_bytes

    # GLB structure:
    # header  (12 bytes)
    # chunk0  JSON: 8 + len(json_bytes)
    # chunk1  BIN:  8 + len(bin_chunk)
    total_len = 12 + 8 + len(json_bytes) + 8 + len(bin_chunk)

    with open(out_path, 'wb') as f:
        # Header
        f.write(b'glTF')             # magic
        f.write(struct.pack('<I', 2)) # version
        f.write(struct.pack('<I', total_len))
        # JSON chunk
        f.write(struct.pack('<I', len(json_bytes)))
        f.write(struct.pack('<I', 0x4E4F534A))  # "JSON"
        f.write(json_bytes)
        # BIN chunk
        f.write(struct.pack('<I', len(bin_chunk)))
        f.write(struct.pack('<I', 0x004E4942))  # "BIN\0"
        f.write(bin_chunk)

    print(f"Wrote {total_len} bytes → {out_path}")


if __name__ == '__main__':
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out  = os.path.join(root, 'assets', 'models', 'khafre_pyramid.glb')
    build_glb(out)
