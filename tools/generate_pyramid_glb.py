#!/usr/bin/env python3
"""
Generate khafre_pyramid.glb using pygltflib, mirroring the EXACT structure of
the working sphinx.glb (POSITION + indices only, no normals, no byteStride,
doubleSided material). SceneKit (iOS) / Sceneform (Android) render this layout
reliably; hand-rolled variants with NORMAL/byteStride were silently rejected.

Run from the project root:
    python3 tools/generate_pyramid_glb.py
"""

import os
import numpy as np
from pygltflib import (
    GLTF2, Scene, Node, Mesh, Primitive, Attributes, Accessor, BufferView,
    Buffer, Material, PbrMetallicRoughness,
)

# Square-base pyramid, modeled around the origin with the base on y=0,
# at roughly the same coordinate scale as sphinx.glb (~2 units wide).
HW = 1.0   # half base width
HT = 1.3   # apex height

verts = [
    (-HW, 0.0, -HW),  # 0 back-left
    ( HW, 0.0, -HW),  # 1 back-right
    ( HW, 0.0,  HW),  # 2 front-right
    (-HW, 0.0,  HW),  # 3 front-left
    (0.0, HT,  0.0),  # 4 apex
]

# Triangles (doubleSided material => visible from both sides).
faces = [
    (3, 2, 4),  # front
    (2, 1, 4),  # right
    (1, 0, 4),  # back
    (0, 3, 4),  # left
    (0, 1, 2),  # base 1
    (0, 2, 3),  # base 2
]

positions = np.array(verts, dtype=np.float32)
indices = np.array([i for f in faces for i in f], dtype=np.uint16)

idx_bytes = indices.tobytes()
# 4-byte align so the float POSITION bufferView starts on a 4-byte boundary.
if len(idx_bytes) % 4:
    idx_bytes += b"\x00" * (4 - len(idx_bytes) % 4)
pos_bytes = positions.tobytes()
blob = idx_bytes + pos_bytes

gltf = GLTF2(
    scene=0,
    scenes=[Scene(nodes=[0])],
    nodes=[Node(mesh=0)],
    meshes=[Mesh(primitives=[Primitive(
        attributes=Attributes(POSITION=1),
        indices=0,
        mode=4,
        material=0,
    )])],
    materials=[Material(
        pbrMetallicRoughness=PbrMetallicRoughness(
            baseColorFactor=[0.80, 0.69, 0.46, 1.0],  # sandy limestone
            metallicFactor=0.2,
            roughnessFactor=0.8,
        ),
        emissiveFactor=[0.0, 0.0, 0.0],
        alphaMode="OPAQUE",
        doubleSided=True,
        name="Limestone",
    )],
    accessors=[
        Accessor(
            bufferView=0, byteOffset=0, componentType=5123,  # UNSIGNED_SHORT
            count=int(indices.size), type="SCALAR",
            max=[int(indices.max())], min=[int(indices.min())],
            normalized=False,
        ),
        Accessor(
            bufferView=1, byteOffset=0, componentType=5126,  # FLOAT
            count=int(positions.shape[0]), type="VEC3",
            max=positions.max(axis=0).tolist(),
            min=positions.min(axis=0).tolist(),
            normalized=False,
        ),
    ],
    bufferViews=[
        BufferView(buffer=0, byteOffset=0, byteLength=len(idx_bytes), target=34963),
        BufferView(buffer=0, byteOffset=len(idx_bytes), byteLength=len(pos_bytes), target=34962),
    ],
    buffers=[Buffer(byteLength=len(blob))],
)
gltf.set_binary_blob(blob)

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out = os.path.join(root, "assets", "models", "khafre_pyramid.glb")
gltf.save_binary(out)
print(f"Wrote {os.path.getsize(out)} bytes -> {out}")
